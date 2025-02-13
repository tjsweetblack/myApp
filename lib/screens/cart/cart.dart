import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
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

            for (var itemData in items) {
              String? productId = itemData['productId'] as String?;
              if (productId != null) {
                DocumentSnapshot productDoc =
                    await _firestore.collection('burgers').doc(productId).get();

                if (productDoc.exists) {
                  Map<String, dynamic> productData =
                      productDoc.data() as Map<String, dynamic>;
                  List<String> extrasList = [];
                  if (productData['custom'] == true) {
                    Map<String, dynamic>? extras =
                        itemData['extras'] as Map<String, dynamic>?;
                    if (extras != null) {
                      extrasList = extras.keys.toList();
                    }
                  }

                  fetchedItems.add({
                    'productName': productData['name'] ?? '',
                    'productDetails': productData['description'] ?? '',
                    'price': itemData['totalPrice'] ?? 0,
                    'quantity': itemData['quantity'] ?? 1,
                    'extras': extrasList,
                    'productId': productId,
                    'cartId': cartId,
                    'imageUrl': productData['imageUrl'] ?? '',
                  });
                } else {
                  print("Product not found: $productId");
                }
              } else {
                print("Missing productId: $itemData");
              }
            }
            setState(() {
              cartItems = fetchedItems;
              _isLoading = false;
              _cartTotalPrice = (cartData['cartTotalPrice'] ?? 0)
                  .toDouble(); // Get cart total
            });
          } else {
            setState(() {
              cartItems = [];
              _isLoading = false;
              _cartTotalPrice = 0; // Get cart total
            });
          }
        } else {
          setState(() {
            cartItems = [];
            _isLoading = false;
            _cartTotalPrice = 0;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
        _cartTotalPrice = 0;
      });
    }
  }

  Future<void> _showCheckoutBottomSheet() async {
    double serviceFee = 0;
    double deliveryFee = 0;

    DocumentSnapshot feeDoc =
        await _firestore.collection('fees').doc('Cji9LufFaQWzbYgZkVCg').get();
    if (feeDoc.exists) {
      serviceFee = (feeDoc['service'] as num).toDouble();
      deliveryFee = (feeDoc['delivery'] as num).toDouble();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        double total = _cartTotalPrice + serviceFee + deliveryFee;
        String paymentMethod = 'TPA';
        String shippingAddress = '';

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
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
                    ),
                  ),
                  const Divider(),
                  Text('Service Fee: \$${serviceFee.toStringAsFixed(2)}'),
                  Text('Delivery Fee: \$${deliveryFee.toStringAsFixed(2)}'),
                  Text('Cart Total: \$${_cartTotalPrice.toStringAsFixed(2)}'),
                  const Divider(),
                  Text('Total: \$${total.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  const Text('Payment Method'),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('TPA'),
                        selected: paymentMethod == 'TPA',
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
                        label: const Text('Cash'),
                        selected: paymentMethod == 'Cash',
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
                  const Text('Shipping Address'),
                  TextFormField(
                    initialValue: shippingAddress,
                    onChanged: (value) {
                      shippingAddress = value;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Ex: kilamba, edificio K12, apartamento 45',
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
                                'extras': cartItem['extras'].isNotEmpty
                                    ? Map.fromIterable(cartItem['extras'],
                                        value: (_) => 1)
                                    : {},
                              };
                            }).toList();

                            await orderCollection.doc(orderId).set({
                              'userId': user.uid,
                              'items': orderItems,
                              'totalPrice': total,
                              'paymentMethod': paymentMethod,
                              'shippingAddress': shippingAddress,
                              'status': 'pending',
                              'dateCreated': FieldValue.serverTimestamp(),
                              'kitchenStatus': 'queue',
                              'orderNumber': orderNumber,
                            });

                            await _clearCart(user);

                            Navigator.pop(context);
                            _showOrderSuccessDialog();
                          }
                        } else {
                          print("Failed to get order number.");
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to place order.')));
                        }
                      },
                      child: const Text('Complete Order'),
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
          title: const Text("Order Successful!"),
          content: const Text("Your order has been placed successfully."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
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
                ? const Center(child: Text("Your cart is empty."))
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.network(
                                      item['imageUrl'],
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (BuildContext context,
                                          Widget child,
                                          ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['productName'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(item['productDetails']),
                                          const SizedBox(height: 8),
                                          Text('\$${item['price']}'),
                                          if (item['extras'].isNotEmpty)
                                            Text('Extras: '
                                                '${item['extras'].join(", ")}'),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () {
                                            setState(() {
                                              if (item['quantity'] > 1) {
                                                item['quantity']--;
                                                _updateCartQuantity(
                                                    item['cartId'],
                                                    item['quantity'],
                                                    item['productId']);
                                              } else {
                                                _removeCartItem(item['cartId'],
                                                    item['productId']);
                                              }
                                            });
                                          },
                                        ),
                                        Text('${item['quantity']}'),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            setState(() {
                                              item['quantity']++;
                                              _updateCartQuantity(
                                                  item['cartId'],
                                                  item['quantity'],
                                                  item['productId']);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 32),
                              ],
                            );
                          },
                        ),
                      ),
                      BottomAppBar(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total: \$${_cartTotalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _showCheckoutBottomSheet,
                                child: const Text('Checkout'),
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
      DocumentReference cartRef = _firestore.collection('cart').doc(cartId);
      DocumentSnapshot cartSnapshot = await cartRef.get();

      if (cartSnapshot.exists) {
        Map<String, dynamic> cartData =
            cartSnapshot.data() as Map<String, dynamic>;
        List<dynamic> items = List.from(cartData['items']);

        items.removeWhere((item) => item['productId'] == productId);

        await cartRef.update({'items': items});

        if (items.isEmpty) {
          User? user = _auth.currentUser;
          if (user != null) {
            DocumentReference userRef =
                _firestore.collection('users').doc(user.uid);
            await userRef.update({'cart': null});
          }
        }
        _loadCartItems();
      }
    } catch (e) {
      print('Error removing item: $e');
    }
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
