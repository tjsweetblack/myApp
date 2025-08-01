import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auth_bloc/routing/routes.dart';

class MyCustomBurgersScreen extends StatefulWidget {
  const MyCustomBurgersScreen({super.key});

  @override
  State<MyCustomBurgersScreen> createState() => _MyCustomBurgersScreenState();
}

class _MyCustomBurgersScreenState extends State<MyCustomBurgersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAddingToCart = false; // Loading state for Add to Cart Button

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("Please log in to see your custom burgers."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'My Custom Burgers',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        // Wrap the Column with SingleChildScrollView
        child: Column(
          // Wrap the whole body in a Column
          children: [
            // Image on top of the list
            SizedBox(
              height: 150, // Adjust height as needed
              child: Image.network(
                'https://i.ibb.co/XfqCfm3J/istockphoto-1313964112-612x612.jpg', // Replace with your image URL
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported,
                  size: 80,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16), // Add spacing below the image
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0), // Add horizontal padding
              child: Text(
                'My Past Creations', // Text below image
                style: TextStyle(
                  fontSize: 24, // Adjust font size as needed
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800, // Darker grey for emphasis
                ),
              ),
            ),
            const SizedBox(height: 24), // Add spacing below the text
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('burgers')
                  .where('custom', isEqualTo: true)
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Something went wrong: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child:
                          Text("You haven't created any custom burgers yet."));
                }

                return ListView(
                  shrinkWrap: true, // Add shrinkWrap to true
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable ListView's scrolling
                  children:
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data =
                        document.data()! as Map<String, dynamic>;
                    List<dynamic> ingredientUids = data['ingredients'] ?? [];
                    double price = data['price'] != null
                        ? (data['price'] as num).toDouble()
                        : 0.0;
                    String burgerId = document.id; // Get document ID

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: SizedBox(
                                  height: 150,
                                  width: 150,
                                  child: Image.network(
                                    data['imageUrl'] ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error,
                                            stackTrace) =>
                                        const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                data['name'] ?? 'Custom Burger',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '\$${price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Ingredients:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: ingredientUids.map((ingredientUid) {
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: _firestore
                                        .collection('ingredients')
                                        .doc(ingredientUid)
                                        .get(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<DocumentSnapshot>
                                            ingredientSnapshot) {
                                      if (ingredientSnapshot.hasData &&
                                          ingredientSnapshot.data!.exists) {
                                        Map<String, dynamic> ingredientData =
                                            ingredientSnapshot.data!.data()
                                                as Map<String, dynamic>;
                                        return Chip(
                                          avatar: CircleAvatar(
                                            // Use CircleAvatar for rounded image
                                            backgroundColor: Colors.grey[50],
                                            backgroundImage: NetworkImage(
                                              ingredientData['imageUrl'] ?? '',
                                            ),
                                          ),
                                          label: Text(ingredientData['name'] ??
                                              'Ingredient'),
                                        );
                                      } else {
                                        return const Chip(
                                            avatar: CircleAvatar(
                                                backgroundColor: Colors
                                                    .grey), // Grey background while loading
                                            label:
                                                Text('Loading Ingredient...'));
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(
                                  height: 20), // Spacing before button
                              Center(
                                // Center the button
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Center(
                                      // Center the button
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: _isAddingToCart
                                                ? null
                                                : () => _addCustomBurgerToCart(
                                                    data, burgerId),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(
                                                    20.0), // Increased roundness
                                              ),
                                              minimumSize: const Size(
                                                  400, 40), // Increased width
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal:
                                                          20), // Add padding
                                            ),
                                            child: const Text('Add to Cart',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          if (_isAddingToCart)
                                            const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (_isAddingToCart)
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCustomBurgerToCart(
      Map<String, dynamic> burgerData, String burgerId) async {
    // Show quantity dialog here before adding to cart
    _showQuantityDialog(burgerData, burgerId);
  }

  Future<void> _showQuantityDialog(
      Map<String, dynamic> burgerData, String burgerId) async {
    int quantity = 1; // Initial quantity

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: const Text('How many burgers?',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Quantity: $quantity',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (quantity > 1) {
                            dialogSetState(() {
                              quantity--;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          dialogSetState(() {
                            quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(dialogContext)
                        .pop(); // Close dialog without adding
                  },
                ),
                TextButton(
                  child: const Text('Confirm',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close dialog
                    _addToCartWithQuantity(burgerData, burgerId,
                        quantity); // Call cart addition with quantity
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addToCartWithQuantity(
      Map<String, dynamic> burgerData, String burgerId, int quantity) async {
    setState(() {
      _isAddingToCart = true; // Start loading
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You must be logged in to add to cart.')),
        );
        return;
      }

      double burgerPrice = burgerData['price'] != null
          ? (burgerData['price'] as num).toDouble()
          : 0.0;

      // Get the user's cart document (create if it doesn't exist)
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userSnapshot = await userDoc.get();

      String cartId;

      if (!userSnapshot.exists ||
          !userSnapshot.data().toString().contains('cart')) {
        final cartRef = await FirebaseFirestore.instance
            .collection('cart')
            .add({'items': [], 'cartTotalPrice': 0.0});
        cartId = cartRef.id;
        await userDoc.update({'cart': cartId});
      } else {
        cartId = userSnapshot.get('cart');
      }

      final cartDoc = FirebaseFirestore.instance.collection('cart').doc(cartId);

      Map<String, dynamic> newItem = {
        'productId': burgerId,
        'quantity': quantity, // Use the quantity selected from dialog!
        'extras': [], // Add extras logic here if needed
        'totalPrice':
            burgerPrice * quantity, // Update totalPrice based on quantity
      };

      await cartDoc.update({
        'items': FieldValue.arrayUnion([newItem]),
        'cartTotalPrice': FieldValue.increment(
            burgerPrice * quantity), // Increment total by quantity * price
      });

      setState(() {
        _isAddingToCart = false; // Stop loading
      });

      _showSeeCartDialog();
    } catch (error) {
      setState(() {
        _isAddingToCart = false; // Stop loading even in error
      });
      print('Error adding to cart: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $error')),
      );
    }
  }

  void _showSeeCartDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close
      builder: (BuildContext dialogContext) {
        return Theme(
          // Apply theme for AlertDialog
          data: Theme.of(context).copyWith(
            dialogTheme: const DialogTheme(
              backgroundColor: Colors.black, // Black background for dialog
            ),
          ),
          child: AlertDialog(
            title: const Text('Successfully added to cart!',
                style: TextStyle(color: Colors.white)), // White title text
            content: const Text('Would you like to see your cart?',
                style: TextStyle(color: Colors.white)),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.orange), // Orange text for button
                child: const Text('No, continue exploring',
                    style: TextStyle(color: Colors.white)), // White button text
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close the dialog
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.orange), // Orange text for button
                child: const Text('Yes, see my cart',
                    style: TextStyle(color: Colors.white)), // White button text
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // First close the dialog
                  Navigator.pushNamed(
                    context,
                    Routes.mainScreen,
                    arguments: 2,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
