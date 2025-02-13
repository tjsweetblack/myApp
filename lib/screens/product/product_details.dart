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
  List<Map<String, dynamic>> _extras = [];
  double _burgerPrice = 0; // Store the base burger price
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _getUser();
    _loadBurgerDetails();
    _loadExtras();
  }

  Future<void> _getUser() async {
    _user = _auth.currentUser;
    setState(() {});
  }

  Future<void> _loadBurgerDetails() async {
    DocumentReference burgerDoc =
        FirebaseFirestore.instance.collection('burgers').doc(widget.burgerId);

    DocumentSnapshot snapshot = await burgerDoc.get();

    if (snapshot.exists) {
      setState(() {
        _burgerData = snapshot.data() as Map<String, dynamic>;
        _burgerPrice =
            double.parse(_burgerData!['price'].toString()); // Parse price
        _totalPrice = _burgerPrice;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Burger not found.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _loadExtras() async {
    CollectionReference ingredientsCollection =
        FirebaseFirestore.instance.collection('ingredients');

    QuerySnapshot snapshot =
        await ingredientsCollection.where('extra', isEqualTo: true).get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _extras = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        for (var extra in _extras) {
          _extraQuantities[extra['name']] = 0;
        }
      });
    } else {
      print("No extras found in ingredients collection.");
    }
  }

  Future<void> _addToCart(BuildContext context) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add to cart.')),
      );
      return;
    }

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

      Map<String, dynamic> newItem = {
        'productId': widget.burgerId,
        'quantity': quantity,
        'extras': _extraQuantities.map((key, value) => MapEntry(key, value)),
        'totalPrice': _totalPrice,
      };

      await cartDoc.update({
        'items': FieldValue.arrayUnion([newItem]),
        'cartTotalPrice': FieldValue.increment(_totalPrice),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added to cart!')),
      );
    } catch (e) {
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

      // Remove any fields you don't want to duplicate (optional):
      burgerData.remove(
          'rating'); // Example: Remove rating if you don't want to copy it
      burgerData.remove('reviews'); // Example: Remove reviews

      // Create a NEW document in the 'burgers' collection:
      CollectionReference burgersCollection =
          FirebaseFirestore.instance.collection('burgers');

      DocumentReference newBurgerDoc =
          burgersCollection.doc(); // Firestore generates ID

      await newBurgerDoc.set(burgerData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Burger duplicated!')),
      );

      // Optionally navigate to the new burger's details page:
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ProductDetailsPage(burgerId: newBurgerDoc.id), // Pass new ID
      //   ),
      // );
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
        title: Text(_burgerData!['name'] ?? 'Product Details'),
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
              child: Image.network(
                _burgerData!['imageUrl'],
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _burgerData!['name'] ?? 'Burger Name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.yellow),
                    Text(_burgerData!['rating']?.toString() ?? 'N/A'),
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
                    Text(
                      'Quantidade: ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if (quantity > 1) {
                            quantity--;
                            _totalPrice =
                                _burgerPrice * quantity; // Update total price
                          }
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
                        setState(() {
                          quantity++;
                          _totalPrice =
                              _burgerPrice * quantity; // Update total price
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _burgerData!['description'] ?? 'No description available',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Price: ${_burgerPrice.toStringAsFixed(2)}', // Display burger price
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Adicionar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            for (var extra in _extras)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    // Wrap image and text in a Row
                    children: [
                      Image.network(
                        // Display the image
                        extra['imageUrl'],
                        width: 50, // Adjust width as needed
                        height: 50, // Adjust height as needed
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 8), // Add some spacing
                      Column(
                        children: [
                          Text(extra['name']),
                          Text("Price: ${extra['price']}"),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (_extraQuantities[extra['name']]! > 0) {
                              _extraQuantities[extra['name']] =
                                  _extraQuantities[extra['name']]! - 1;
                              _totalPrice -= double.parse(extra['price']
                                  .toString()); // Update total price
                            }
                          });
                        },
                      ),
                      Text(
                        _extraQuantities[extra['name']]!.toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _extraQuantities[extra['name']] =
                                _extraQuantities[extra['name']]! + 1;
                            _totalPrice += double.parse(extra['price']
                                .toString()); // Update total price
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
        // Fixed bottom bar
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
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _duplicateBurger(context,
                      widget.burgerId); // Call the add to cart function
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  textStyle: const TextStyle(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 25,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text('Add to Cart',
                    style: TextStyle(
                      color: Colors.white,
                    )),
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
