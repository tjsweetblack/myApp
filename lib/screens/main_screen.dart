import 'package:auth_bloc/screens/cart/cart.dart';
import 'package:auth_bloc/screens/favourates/favourate.dart';
import 'package:auth_bloc/screens/home/ui/home_sceren.dart';
import 'package:auth_bloc/screens/orders/orders.dart';
import 'package:auth_bloc/screens/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';// Import rxdart

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _appBarTitle = 'Home';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>?>?
      _orderStreamSubscription; // Add StreamSubscription

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    MyOrdersPage(),
    CartScreen(),
    FavoritesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          _appBarTitle = 'Home';
          break;
        case 1:
          _appBarTitle = 'Orders';
          break;
        case 2:
          _appBarTitle = 'Cart';
          break;
        case 3:
          _appBarTitle = 'Favorites';
          break;
      }
    });
  }

  Stream<DocumentSnapshot<Object?>> _getCartStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final usersCollection = FirebaseFirestore.instance.collection('users');
      return usersCollection
          .doc(user.uid)
          .snapshots()
          .asyncMap((userDoc) async {
            if (userDoc.exists) {
              String? cartId = userDoc.data()?['cart'];
              if (cartId != null) {
                return FirebaseFirestore.instance
                    .collection('cart')
                    .doc(cartId)
                    .get();
              }
            }
            return Future.value(null);
          })
          .map((docSnapshot) {
            if (docSnapshot != null && docSnapshot.exists) {
              return docSnapshot;
            } else {
              return null;
            }
          })
          .where((docSnapshot) => docSnapshot != null)
          .cast<DocumentSnapshot<Object?>>();
    } else {
      return Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                    'https://cdn4.iconfinder.com/data/icons/glyphs/24/icons_user-512.png'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        // Changed body to Column to place the card above Center
        children: [
          Expanded(
            // Added Expanded to make Center take remaining space
            child: Center(
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.orange,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Order',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<DocumentSnapshot<Object?>>(
              stream: _getCartStream(),
              builder: (context, snapshot) {
                int cartCount = 0;
                if (snapshot.hasData && snapshot.data!.exists) {
                  Map<String, dynamic> cartData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  List<dynamic> items = cartData['items'] ?? [];
                  cartCount = items.length;
                }
                return Stack(
                  children: [
                    const Icon(Icons.shopping_basket),
                    if (cartCount > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
