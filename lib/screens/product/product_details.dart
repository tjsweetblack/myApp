import 'package:auth_bloc/routing/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductDetailsPage extends StatefulWidget {
  final String burgerId;

  const ProductDetailsPage({super.key, required this.burgerId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  Map<String, dynamic>? _burgerData;
  Map<String, int> _extraQuantities = {};
  List<DocumentSnapshot> _extras = [];
  double _burgerPrice = 0;
  double _totalPrice = 0;
  bool _isAddingToCart = false; // Loading state for Add to Cart

  @override
  void initState() {
    super.initState();
    _getUser();
    _loadBurgerDetails();
    _loadExtras();
  }

  Future<void> _getUser() async {
    _user = _auth.currentUser;
    if (mounted) setState(() {});
  }

  Future<void> _loadBurgerDetails() async {
    DocumentReference burgerDoc =
        FirebaseFirestore.instance.collection('burgers').doc(widget.burgerId);

    DocumentSnapshot snapshot = await burgerDoc.get();

    if (snapshot.exists) {
      if (mounted)
        setState(() {
          _burgerData = snapshot.data() as Map<String, dynamic>?;
          _burgerPrice =
              double.tryParse(_burgerData?['price']?.toString() ?? '0') ?? 0;
          _updateTotalPrice();
        });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Burger not found.')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadExtras() async {
    CollectionReference ingredientsCollection =
        FirebaseFirestore.instance.collection('ingredients');

    QuerySnapshot snapshot =
        await ingredientsCollection.where('extra', isEqualTo: true).get();

    if (snapshot.docs.isNotEmpty) {
      if (mounted)
        setState(() {
          _extras = snapshot.docs;
          for (var doc in _extras) {
            _extraQuantities[doc.id] = 0;
          }
          _updateTotalPrice();
        });
    } else {
      print("No extras found in ingredients collection.");
    }
  }

  void _updateTotalPrice() {
    _totalPrice = _burgerPrice * quantity;
    _extraQuantities.forEach((extraId, extraQuantity) {
      if (extraQuantity > 0) {
        DocumentSnapshot? extraDoc =
            _extras.firstWhere((doc) => doc.id == extraId);
        if (extraDoc != null) {
          double extraPrice =
              double.tryParse(extraDoc['price']?.toString() ?? '0') ?? 0;
          _totalPrice += extraPrice * extraQuantity * quantity;
        }
      }
    });
  }

  Future<void> _addToCart(BuildContext context) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add to cart.')),
      );
      return;
    }

    setState(() {
      _isAddingToCart = true; // Start loading
    });

    try {
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(_user!.uid);
      DocumentSnapshot userSnapshot = await userDoc.get();

      if (!userSnapshot.exists ||
          !userSnapshot.data().toString().contains('cart')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart not found for this user.')),
        );
        return;
      }

      String cartId = userSnapshot.get('cart');
      DocumentReference cartDoc =
          FirebaseFirestore.instance.collection('cart').doc(cartId);
      DocumentSnapshot cartSnapshot = await cartDoc.get();

      if (!cartSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart document does not exist.')),
        );
        return;
      }

      List<String> extrasArray = [];
      _extraQuantities.forEach((key, value) {
        for (int i = 0; i < value; i++) {
          extrasArray.add(key);
        }
      });

      Map<String, dynamic> newItem = {
        'productId': widget.burgerId,
        'quantity': quantity,
        'extras': extrasArray,
        'totalPrice': _totalPrice,
      };

      await cartDoc.update({
        'items': FieldValue.arrayUnion([newItem]),
        'cartTotalPrice': FieldValue.increment(_totalPrice),
      });

      setState(() {
        _isAddingToCart = false; // End loading
      });

      // Show Dialog on successful cart addition with black background, white text, orange buttons
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return Theme(
            // Apply theme for AlertDialog
            data: Theme.of(context).copyWith(
              dialogTheme: DialogThemeData(
                backgroundColor: Colors.black, // Black background for dialog
              ),
            ),
            child: AlertDialog(
              title: Text('Successfully added to cart!',
                  style: TextStyle(color: Colors.white)), // White title text
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.orange), // Orange text for button
                  child: const Text('Continue Exploring',
                      style:
                          TextStyle(color: Colors.white)), // White button text
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      Routes.mainScreen,
                      arguments: 0,
                    );
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.orange), // Orange text for button
                  child: const Text('See My Cart',
                      style:
                          TextStyle(color: Colors.white)), // White button text
                  onPressed: () {
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
    } catch (e) {
      setState(() {
        _isAddingToCart = false; // End loading even in error case
      });
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $e')),
      );
    }
  }

  Future<void> _duplicateBurger(BuildContext context, String burgerId) async {
    try {
      DocumentReference burgerDoc =
          FirebaseFirestore.instance.collection('burgers').doc(burgerId);
      DocumentSnapshot burgerSnapshot = await burgerDoc.get();

      if (!burgerSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Burger not found.')),
        );
        return;
      }

      Map<String, dynamic> burgerData =
          burgerSnapshot.data() as Map<String, dynamic>;

      CollectionReference burgersCollection =
          FirebaseFirestore.instance.collection('burgers');

      DocumentReference newBurgerDoc =
          burgersCollection.doc(); // Firestore generates ID

      await newBurgerDoc.set(burgerData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Burger duplicated!')),
      );
    } catch (e) {
      print('Error duplicating burger: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error duplicating burger: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_burgerData == null || _extras.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (!snapshot.hasData ||
                      snapshot.data == null ||
                      !snapshot.data!.exists) {
                    return IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {},
                    );
                  }

                  DocumentSnapshot userDoc = snapshot.data!;
                  List<dynamic> favoriteBurgerIds =
                      userDoc.get('favorites') ?? [];
                  bool isFavorite = favoriteBurgerIds.contains(widget.burgerId);

                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    onPressed: () {
                      if (_user != null) {
                        favoritesProvider.toggleFavorite(widget.burgerId);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please log in to add to favorites.'),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              child: _burgerData?['imageUrl'] is String
                  ? Image.network(
                      _burgerData!['imageUrl'],
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Text("Error loading image"),
                    )
                  : const Text("Invalid Burger Image URL"),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Name: ', // Add "Name:" here
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      _burgerData?['name']?.toString() ?? 'Burger Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Quantidade: ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (mounted)
                          setState(() {
                            if (quantity > 1) {
                              quantity--;
                            }
                            _updateTotalPrice();
                          });
                      },
                    ),
                    Text(
                      quantity.toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (mounted)
                          setState(() {
                            quantity++;
                            _updateTotalPrice();
                          });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'descricao:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _burgerData?['description']?.toString() ??
                  'No description available',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Adicionar Extras:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            for (var extraDoc in _extras)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      extraDoc['imageUrl'] is String
                          ? Image.network(
                              extraDoc['imageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error_outline),
                            )
                          : const Icon(Icons.image_not_supported, size: 50),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(extraDoc['name']?.toString() ?? 'Extra Name'),
                          Text(
                              "Price: ${extraDoc['price']?.toString() ?? 'N/A'}"),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (mounted)
                            setState(() {
                              if (_extraQuantities[extraDoc.id]! > 0) {
                                _extraQuantities[extraDoc.id] =
                                    _extraQuantities[extraDoc.id]! - 1;
                              }
                              _updateTotalPrice();
                            });
                        },
                      ),
                      Text(
                        _extraQuantities[extraDoc.id]!.toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (mounted)
                            setState(() {
                              _extraQuantities[extraDoc.id] =
                                  _extraQuantities[extraDoc.id]! + 1;
                              _updateTotalPrice();
                            });
                        },
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${_totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white),
              ),
              Stack(
                // Use Stack to overlay button and loading indicator
                alignment: Alignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isAddingToCart
                        ? null
                        : () {
                            // Disable button when loading
                            _addToCart(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      textStyle: const TextStyle(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Add to Cart',
                        style: TextStyle(
                          color: Colors.black,
                        )),
                  ),
                  if (_isAddingToCart) // Show loading indicator when _isAddingToCart is true
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white, // White color for loader
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FavoritesProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  List<String> favoriteBurgerIds = [];

  FavoritesProvider() {
    _getUser();
  }

  Future<void> _getUser() async {
    _user = _auth.currentUser;
    if (_user != null) {
      await _loadFavorites();
    }
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    if (_user == null) return;

    DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(_user!.uid);

    DocumentSnapshot snapshot = await userDoc.get();

    if (!snapshot.exists || !snapshot.data().toString().contains('favorites')) {
      return;
    }

    favoriteBurgerIds = List<String>.from(snapshot.get('favorites') ?? []);
    notifyListeners();
  }

  Future<void> toggleFavorite(String burgerId) async {
    if (_user == null) return;

    DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(_user!.uid);

    if (favoriteBurgerIds.contains(burgerId)) {
      favoriteBurgerIds.remove(burgerId);
    } else {
      favoriteBurgerIds.add(burgerId);
    }

    await userDoc.update({'favorites': favoriteBurgerIds});
    notifyListeners();
  }

  bool isFavorite(String burgerId) {
    return favoriteBurgerIds.contains(burgerId);
  }
}
