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
          ? const Center(child: Text("Please log in to view favorites."))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _getFavoriteBurgers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No favorites yet.'));
                }

                var favoriteBurgers = snapshot.data!;

                return ListView.builder(
                  itemCount: favoriteBurgers.length,
                  itemBuilder: (context, index) {
                    var burger = favoriteBurgers[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsPage(burgerId: burger['id']),
                          ),
                        );
                      },
                      child: Card(
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: Image.network(burger['imageUrl']),
                            ),
                          ),
                          title: Text(burger['name']),
                          subtitle: Text('\$${burger['price']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.red),
                            onPressed: () {
                              _removeFavorite(burger['id']);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
