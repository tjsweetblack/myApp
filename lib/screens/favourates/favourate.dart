import 'package:auth_bloc/screens/product/product_details.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  Future<void> _getUser() async {
    _user = _auth.currentUser;
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> _getFavoriteBurgers() async {
    if (_user == null) {
      return [];
    }

    DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(_user!.uid);

    DocumentSnapshot snapshot = await userDoc.get();

    if (!snapshot.exists || !snapshot.data().toString().contains('favorites')) {
      return [];
    }

    List<dynamic> favoriteBurgerIds = snapshot.get('favorites') ?? [];
    List<Map<String, dynamic>> favoriteBurgers = [];

    for (String burgerId in favoriteBurgerIds) {
      DocumentSnapshot burgerSnapshot = await FirebaseFirestore.instance
          .collection('burgers')
          .doc(burgerId)
          .get();

      if (burgerSnapshot.exists) {
        Map<String, dynamic> burgerData =
            burgerSnapshot.data() as Map<String, dynamic>;

        favoriteBurgers.add({
          'id': burgerSnapshot.id,
          'name': burgerData['name'],
          'imageUrl': burgerData['imageUrl'],
          'rating': burgerData['rating'],
          'price': burgerData['price'],
        });
      }
    }
    return favoriteBurgers;
  }

  Future<void> _removeFavorite(String burgerId) async {
    if (_user == null) return;

    DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(_user!.uid);

    DocumentSnapshot snapshot = await userDoc.get();

    if (!snapshot.exists || !snapshot.data().toString().contains('favorites')) {
      return;
    }

    List<dynamic> favoriteBurgerIds = snapshot.get('favorites') ?? [];
    favoriteBurgerIds.remove(burgerId);

    await userDoc.update({'favorites': favoriteBurgerIds});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _user == null
          ? const Center(
              child: Text(
                "Please log in to view favorites.",
                style: TextStyle(fontSize: 16),
              ),
            )
          : SingleChildScrollView(
              // Wrap the entire body in SingleChildScrollView
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
                    child: Image.asset(
                      'assets/images/favorite_header_image.png',
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Text(
                    "My Favorite Burgers",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getFavoriteBurgers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Colors.redAccent));
                      }

                      if (snapshot.hasError) {
                        return Center(
                            child: Text('Error: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red)));
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('No favorites yet.',
                                style: TextStyle(fontSize: 16)));
                      }

                      var favoriteBurgers = snapshot.data!;

                      return ListView.builder(
                        shrinkWrap:
                            true, // Important for ListView inside Column
                        physics:
                            const NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        itemCount: favoriteBurgers.length,
                        itemBuilder: (context, index) {
                          var burger = favoriteBurgers[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailsPage(
                                      burgerId: burger['id']),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0)),
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: Image.network(
                                        burger['imageUrl'],
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            const SizedBox(
                                                width: 120,
                                                height: 120,
                                                child: Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey)),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            burger['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '\$${burger['price']}',
                                            style: TextStyle(
                                              color: Colors.orange.shade800,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: InkWell(
                                              onTap: () {
                                                _removeFavorite(burger['id']);
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.favorite,
                                                        color: Colors.red[400],
                                                        size: 20),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      'Remove',
                                                      style: TextStyle(
                                                          color:
                                                              Colors.red[700],
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ),
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
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
