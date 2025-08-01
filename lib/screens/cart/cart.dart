import 'package:auth_bloc/routing/routes.dart';
import 'package:auth_bloc/screens/cart/widgets/cart_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http; // Import http package at the top
import 'package:auth_bloc/screens/orders/order_tracking/order_tracking.dart';
import 'package:open_street_map_search_and_pick/open_street_map_search_and_pick.dart';
// Import OrderTrackingScreen

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> cartItems = [];
  bool _isLoading = true;
  double _cartTotalPrice = 0;
  List<Map<String, dynamic>> _sides = []; // Store fetched sides
  Map<String, int> _selectedSidesQuantities =
      {}; // Track selected sides and quantities
  double _sidesTotalPrice = 0;
  String shippingAddress = ''; // Declare shippingAddress here, at class level
  LatLng? selectedLocation; // Track total price of sides

  @override
  void initState() {
    super.initState();
    _loadCartItems();
    _loadSides(); // Load sides on initialization
  }

  Future<void> _loadSides() async {
    setState(() {
      _isLoading = true;
      _sides = [];
    });
    QuerySnapshot sideSnapshot =
        await _firestore.collection('sides').orderBy('category').get();
    if (sideSnapshot.docs.isNotEmpty) {
      setState(() {
        _sides = sideSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['id'] == null) {
            print("Warning: side document with missing id: ${doc.id}");
          }
          return data;
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      print("No sides found");
    }
  }

  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
      cartItems = []; // Clear existing items to ensure correct refresh
    });

    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        String? cartId = userDoc['cart'];
        if (cartId != null) {
          DocumentSnapshot cartDoc =
              await _firestore.collection('cart').doc(cartId).get();
          if (cartDoc.exists) {
            Map<String, dynamic> cartData =
                cartDoc.data() as Map<String, dynamic>;
            List<dynamic> items = cartData['items'] ?? [];
            List<Map<String, dynamic>> fetchedItems = [];

            List<Future<DocumentSnapshot>> productFutures = [];

            for (var itemData in items) {
              String? productId = itemData['productId'] as String?;
              if (productId != null) {
                productFutures
                    .add(_firestore.collection('burgers').doc(productId).get());
              }
            }

            List<DocumentSnapshot> productDocs =
                await Future.wait(productFutures);

            for (int i = 0; i < items.length; i++) {
              // Corrected loop condition
              var itemData = items[i];
              DocumentSnapshot productDoc = productDocs[i];

              if (productDoc.exists) {
                Map<String, dynamic> productData =
                    productDoc.data() as Map<String, dynamic>;
                String? productId = itemData['productId'] as String?;
                List<dynamic> extrasUids =
                    []; // Initialize as empty list by default

                if (itemData['extras'] != null) {
                  if (itemData['extras'] is List) {
                    extrasUids = List<dynamic>.from(
                        itemData['extras']); // Safe cast if it IS a List
                  } else if (itemData['extras'] is Map) {
                    // **NEW: Check if it's a Map (incorrect type)**
                    print(
                        "Warning: itemData['extras'] is a Map instead of List for product ID: ${itemData['productId']}. Treating as no extras.");
                    // In this case, we treat it as if there are no extras (empty list is already initialized)
                  } else {
                    // **NEW: Handle other unexpected types**
                    print(
                        "Warning: itemData['extras'] has unexpected type: ${itemData['extras'].runtimeType} for product ID: ${itemData['productId']}. Treating as no extras.");
                    // Treat as no extras (empty list)
                  }
                }

                fetchedItems.add({
                  'productName': productData['name'] ?? '',
                  'productDetails': productData['description'] ??
                      '', // Keep details if you want them initially
                  'price': itemData['totalPrice'] ?? 0,
                  'quantity': itemData['quantity'] ?? 1,
                  'extrasUid': extrasUids,
                  'extras': [], // Initialize as empty lists
                  'ingredients': [],
                  'productId': productId,
                  'cartId': cartId,
                  'imageUrl': productData['imageUrl'] ?? '', // Basic image
                  'itemData':
                      itemData, // Pass original itemData for later detailed fetch
                });
              } else {
                String? productId = itemData['productId'] as String?;
                print("Product not found: $productId");
              }
            }

            setState(() {
              cartItems = fetchedItems;
              _isLoading = false;
              _cartTotalPrice = (cartData['cartTotalPrice'] ?? 0).toDouble();
            });
          } else {
            _setEmptyCartState();
          }
        } else {
          _setEmptyCartState();
        }
      }
    } else {
      setState(() {
        _isLoading = false;
        _cartTotalPrice = 0;
      });
    }
  }

  // Helper function to fetch extra documents in parallel
  Future<List<DocumentSnapshot>> _fetchExtraDocs(List<String> extraUids) async {
    List<Future<DocumentSnapshot>> futures = [];
    for (String extraUid in extraUids) {
      futures.add(_firestore
          .collection('ingredients')
          .doc(extraUid)
          .get()); // Assuming 'ingredients' collection
    }
    return Future.wait(futures);
  }

  // Helper function to fetch ingredient documents in parallel
  Future<List<DocumentSnapshot>> _fetchIngredientDocs(
      List<String> ingredientUids) async {
    List<Future<DocumentSnapshot>> futures = [];
    for (String ingredientUid in ingredientUids) {
      futures.add(_firestore
          .collection('ingredients')
          .doc(ingredientUid)
          .get()); // Assuming 'ingredients' collection
    }
    return Future.wait(futures);
  }

  // Helper function to map DocumentSnapshot to Map<String, String> for extras/ingredients
  Map<String, String> _mapExtraIngredientDocToMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data != null && data['name'] != null) {
      return {
        'name': data['name'] as String,
        'imageUrl': data['imageUrl'] as String? ?? '',
      };
    } else {
      print(
          "Warning: Missing 'name' or 'imageUrl' field in extra/ingredient document: ${doc.id}");
      return {'name': '', 'imageUrl': ''}; // Return empty map in case of error
    }
  }

  bool productDataHasIngredients(dynamic itemData) {
    String? productId = itemData['productId'] as String?;
    if (productId != null) {
      return true; // Assume product data has ingredients to fetch later from productDoc. This avoids fetching productDoc twice.
    }
    return false;
  }

  List<dynamic> productDataIngredientsUids(dynamic itemData) {
    // In this optimized version, ingredients are fetched from productDoc directly if product is custom.
    return []; // Return empty list as ingredients are fetched later from productDoc.
  }

  void _setEmptyCartState() {
    setState(() {
      cartItems = [];
      _isLoading = false;
      _cartTotalPrice = 0;
    });
  }

  void _showSidesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gostarias de algum acompanhante?', // Portuguese text
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sides.length,
                    itemBuilder: (context, index) {
                      final side = _sides[index];
                      final category = side['category'] as String? ?? 'Others';
                      final name = side['name'] as String? ?? 'N/A';
                      final price = (side['price'] as num? ?? 0).toDouble();
                      final imageUrl = side['imageUrl'] as String? ?? '';
                      final sideId = (side['id'] as String?) ??
                          _sides
                              .indexOf(side)
                              .toString(); // Ensure sideId is String

                      if (index > 0 &&
                          _sides[index - 1]['category'] != category) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 16, bottom: 8),
                              child: Text(
                                category,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white),
                              ),
                            ),
                            _buildSideCard(
                                side, setState, name, price, imageUrl, sideId),
                          ],
                        );
                      } else if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 0, bottom: 8),
                              child: Text(
                                category,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white),
                              ),
                            ),
                            _buildSideCard(
                                side, setState, name, price, imageUrl, sideId),
                          ],
                        );
                      }
                      return _buildSideCard(
                          side, setState, name, price, imageUrl, sideId);
                    },
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close sides bottom sheet
                        _showCheckoutBottomSheet(); // Then show checkout bottom sheet
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text(
                          'Continuar para Checkout'), // Portuguese text
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // setState here to rebuild the bottom app bar with the updated _sidesTotalPrice
      setState(() {});
    });
  }

  Widget _buildSideCard(Map<String, dynamic> side, StateSetter setState,
      String name, double price, String imageUrl, String sideId) {
    int quantity = _selectedSidesQuantities[sideId] ?? 0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                imageUrl,
                height: 50,
                width: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.fastfood, color: Colors.grey, size: 50),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.white),
                  onPressed: () {
                    if (quantity > 0) {
                      setState(() {
                        _selectedSidesQuantities[sideId] = quantity - 1;
                        _updateSidesTotalPrice();
                      });
                    }
                  },
                ),
                Text(
                  quantity.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedSidesQuantities[sideId] = quantity + 1;
                      _updateSidesTotalPrice();
                      print("Quantity updated: $quantity");
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateSidesTotalPrice() {
    double totalPrice = 0;
    _selectedSidesQuantities.forEach((sideId, quantity) {
      final side = _sides.firstWhere(
        (s) => (s['id'] as String?) == sideId,
        orElse: () => <String, dynamic>{}, // Return an empty map
      );
      if (side.isNotEmpty) {
        //check if the map is empty
        totalPrice += (side['price'] as num).toDouble() * quantity;
      }
    });
    _sidesTotalPrice = totalPrice;
  }

  Future<void> _showCheckoutBottomSheet() async {
    double serviceFee = 0;
    double deliveryFee = 0;
    double servicePercentage = 0; // New variable for percentage

    DocumentSnapshot feeDoc =
        await _firestore.collection('fees').doc('Cji9LufFaQWzbYgZkVCg').get();
    if (feeDoc.exists) {
      servicePercentage =
          (feeDoc['service'] as num).toDouble(); // Get percentage from database
      deliveryFee = (feeDoc['delivery'] as num).toDouble();
      serviceFee =
          (_cartTotalPrice * servicePercentage / 100); // Calculate service fee
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        double total =
            _cartTotalPrice + serviceFee + deliveryFee + _sidesTotalPrice;
        String paymentMethod = 'TPA';

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Checkout',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Divider(color: Colors.white),
                  Text(
                    'Service Fee: \$${serviceFee.toStringAsFixed(2)} (${servicePercentage.toStringAsFixed(2)}%)', // Display both fee and percentage
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text('Delivery Fee: \$${deliveryFee.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white)),
                  Text('Cart Total: \$${_cartTotalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white)),
                  Text('Sides Total: \$${_sidesTotalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white)),
                  const Divider(color: Colors.white),
                  Text('Total: \$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Payment Method',
                      style: TextStyle(color: Colors.white)), // White text
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('TPA',
                            style:
                                TextStyle(color: Colors.black)), // Black text
                        selected: paymentMethod == 'TPA',
                        selectedColor: Colors.orange, // Orange when selected
                        backgroundColor: Colors.grey, // Grey when unselected
                        onSelected: (value) {
                          if (value) {
                            setState(() {
                              paymentMethod = 'TPA';
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Cash',
                            style:
                                TextStyle(color: Colors.black)), // Black text
                        selected: paymentMethod == 'Cash',
                        selectedColor: Colors.orange, // Orange when selected
                        backgroundColor: Colors.grey, // Grey when unselected
                        onSelected: (value) {
                          if (value) {
                            setState(() {
                              paymentMethod = 'Cash';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Shipping Address',
                      style: TextStyle(color: Colors.white)), // White text
                  ElevatedButton(
                    onPressed: () async {
                      LatLng location = await _selectLocation(context);
                      print(
                          "CartScreen: Location received from _selectLocation: $location");

                      try {
                        final response = await http.get(Uri.parse(
                            'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${location.latitude}&lon=${location.longitude}&addressdetails=1'));

                        if (response.statusCode == 200) {
                          final decodedResponse = jsonDecode(response.body);
                          print(
                              "Nominatim API decodedResponse: $decodedResponse");

                          if (decodedResponse != null &&
                              decodedResponse['display_name'] != null) {
                            // <-- Check for display_name
                            setState(() {
                              shippingAddress = decodedResponse[
                                  'display_name']; // <-- Use display_name directly
                              print(
                                  "Shipping address set to: $shippingAddress"); // Log shipping address
                              selectedLocation = location;
                            });
                          } else {
                            print(
                                "Nominatim API: No address details found in response (inside IF condition)");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'No address found for selected location.')),
                            );
                            setState(() {
                              shippingAddress = '';
                            });
                          }
                        } else {
                          // Handle API error (e.g., show an error message)
                          print(
                              "Nominatim API request failed with status: ${response.statusCode}");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Failed to get address.')),
                          );
                          setState(() {
                            shippingAddress = '';
                          });
                        }
                      } catch (e) {
                        // Handle any exceptions (e.g., network issues)
                        print("Error fetching address: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to get address.')),
                        );
                        setState(() {
                          shippingAddress = '';
                        });
                      }
                    },
                    child: const Text('Select Location'),
                  ),

                  if (shippingAddress
                      .isNotEmpty) // Check if shippingAddress is not empty
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'Your Current Location:',
                            style: TextStyle(
                              color: Colors
                                  .white, // Or any style you prefer for the title
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            shippingAddress,
                            style: const TextStyle(
                                color: Colors.white), // Style for the address
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        int orderNumber =
                            await countDocumentsPlusOne('orders') ?? 0;

                        if (orderNumber != 0) {
                          User? user = _auth.currentUser;
                          if (user != null) {
                            CollectionReference orderCollection =
                                _firestore.collection('orders');

                            String orderId = orderCollection.doc().id;

                            List<Map<String, dynamic>> orderItems =
                                cartItems.map((cartItem) {
                              return {
                                'productId': cartItem['productId'],
                                'quantity': cartItem['quantity'],
                                'totalPrice':
                                    cartItem['price'] * cartItem['quantity'],
                                'extras': cartItem['extrasUid'] ?? [],
                              };
                            }).toList();

                            List<Map<String, dynamic>> orderSides = [];
                            _selectedSidesQuantities
                                .forEach((sideId, quantity) {
                              if (quantity > 0) {
                                orderSides.add({
                                  'sideId': sideId,
                                  'quantity': quantity,
                                });
                              }
                            });

                            print(
                                "Shipping Address just before saving order: $shippingAddress"); // <-- ADD THIS LOG
                            LatLng? location =
                                selectedLocation; // Use the selectedLocation variable

                            await orderCollection.doc(orderId).set({
                              'userId': user.uid,
                              'items': orderItems,
                              'sides': orderSides,
                              'sidesTotalPrice': _sidesTotalPrice,
                              'totalPrice': total,
                              'paymentMethod': paymentMethod,
                              'shippingAddress':
                                  shippingAddress, // <-- USING shippingAddress here
                              'status': 'pending',
                              'dateCreated': FieldValue.serverTimestamp(),
                              'kitchenStatus': 'queue',
                              'orderNumber': orderNumber,
                              'latitude': location?.latitude, // Add latitude
                              'longitude': location?.longitude,
                            });

                            await _clearCart(user);
                            _selectedSidesQuantities = {};
                            _sidesTotalPrice = 0;

                            Navigator.pop(context);
                            _showOrderSuccessDialog();
                          }
                        } else {
                          print("Failed to get order number.");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Failed to place order.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Complete Order',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<LatLng> _selectLocation(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSelectionScreen(),
      ),
    );
    return result as LatLng; // Cast the result to LatLng
  }

  Future<void> _clearCart(User user) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        String? cartId = userDoc['cart'];

        if (cartId != null) {
          // Get a reference to the cart document
          DocumentReference cartRef = _firestore.collection('cart').doc(cartId);

          // Option 1: Update the 'items' array to empty (Recommended)
          await cartRef.update({
            'items': [],
            'cartTotalPrice': 0.0
          }); // Clear items and total price
          _loadCartItems(); // Refresh cart items
        }
      }
    } catch (e) {
      print("Error clearing cart: $e");
      // Handle the error appropriately, e.g., show a snackbar to the user.
    }
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          title: const Text(
            "Order Successful!",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text("Your order has been placed successfully.",
              style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  // Navigate to OrderTrackingScreen here!
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OrderTrackingScreen()),
                );
              },
              child: const Text("OK", style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : cartItems.isEmpty
                ? Center(
                    // Center the content when cart is empty
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Center vertically
                      children: <Widget>[
                        Image.network(
                          // Consider adding a past orders specific image here if desired
                          'https://cdni.iconscout.com/illustration/premium/thumb/girl-holding-empty-shopping-cart-illustration-download-in-svg-png-gif-file-formats--no-items-online-stroller-pack-e-commerce-illustrations-10018095.png?f=webp',
                          height: 100,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.image_not_supported,
                            size: 200,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Your cart is empty", // Display the requested text
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center, // Center text
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              Routes.mainScreen,
                              arguments: 0,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.orange, // Match button color in the app
                            foregroundColor: Colors.black, // Match text color
                          ),
                          child: const Text("Discover now"),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return CartItemWidget(
                              item: item,
                              onRemoveItem: _removeCartItem,
                              onUpdateQuantity: _updateCartQuantity,
                              onLoadCartItems:
                                  _loadCartItems, // Pass the callback
                              showCheckoutBottomSheet: () {
                                // Modified to call _showSidesBottomSheet instead
                                _showSidesBottomSheet();
                              },
                            );
                          },
                        ),
                      ),
                      BottomAppBar(
                        color: Colors.black,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total: \Kz${_cartTotalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  textStyle:
                                      const TextStyle(color: Colors.black),
                                ),
                                onPressed: () {
                                  // Modified to call _showSidesBottomSheet instead
                                  _showSidesBottomSheet();
                                },
                                child: const Text(
                                  'Checkout',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Future<void> _updateCartQuantity(
      String cartId, int quantity, String productId) async {
    try {
      DocumentReference cartRef = _firestore.collection('cart').doc(cartId);
      DocumentSnapshot cartSnapshot = await cartRef.get();
      if (cartSnapshot.exists) {
        Map<String, dynamic> cartData =
            cartSnapshot.data() as Map<String, dynamic>;
        List<dynamic> items = List.from(cartData['items']);

        int index = items.indexWhere((item) => item['productId'] == productId);
        if (index != -1) {
          items[index]['quantity'] = quantity;
          await cartRef.update({'items': items});
          _loadCartItems();
        }
      }
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  Future<void> _removeCartItem(String cartId, String productId) async {
    try {
      DocumentReference cartRef =
          FirebaseFirestore.instance.collection('cart').doc(cartId);
      DocumentSnapshot cartSnapshot = await cartRef.get();

      if (cartSnapshot.exists) {
        Map<String, dynamic> cartData =
            cartSnapshot.data() as Map<String, dynamic>;
        List<dynamic> items = List.from(cartData['items']);

        // Find the item to be removed and get its totalPrice
        double itemTotalPriceToRemove = 0;
        var itemToRemove = items.firstWhere(
            (item) => item['productId'] == productId,
            orElse: () => null); // Find the item

        if (itemToRemove != null) {
          itemTotalPriceToRemove =
              (itemToRemove['totalPrice'] as num).toDouble(); // Get totalPrice
          items.removeWhere(
              (item) => item['productId'] == productId); // Remove item
        }

        // Calculate the new cartTotalPrice
        double currentCartTotalPrice =
            (cartData['cartTotalPrice'] as num).toDouble();
        double newCartTotalPrice =
            currentCartTotalPrice - itemTotalPriceToRemove;

        // Ensure cartTotalPrice is not negative
        if (newCartTotalPrice < 0) {
          newCartTotalPrice = 0;
        }

        await cartRef.update({
          'items': items,
          'cartTotalPrice': newCartTotalPrice, // Update cartTotalPrice
        });
        // No need to call _loadCartItems() here if it's called in the widget that uses this function
      }
    } catch (e) {
      print('Error removing item and updating cart total: $e');
    }
  }

  Future<int?> countDocumentsPlusOne(String collectionPath) async {
    //Takes Collection Path as an argument
    try {
      CollectionReference collection = FirebaseFirestore.instance
          .collection(collectionPath); //Access Collection

      AggregateQuerySnapshot snapshot =
          await collection.count().get(); //Count documents
      int? count = snapshot.count;

      return count! + 1;
    } catch (e) {
      print("Error counting documents: $e");
      return null; // Return null to indicate an error
    }
  }
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  LatLng? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Column(
        children: [
          Expanded(
            child: OpenStreetMapSearchAndPick(
              onPicked: (pickedData) {
                _selectedLocation = LatLng(
                  pickedData.latLong.latitude,
                  pickedData.latLong.longitude,
                );
                Navigator.pop(context, _selectedLocation); // Navigate back here
              },
              buttonColor: Colors.orange,
              buttonText: 'cofimar a localizacao',
            ),
          ),
        ],
      ),
    );
  }
}

class LocationSelectionScreen extends StatefulWidget {
  @override
  _LocationSelectionScreenState createState() =>
      _LocationSelectionScreenState();
}
