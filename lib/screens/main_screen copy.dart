import 'package:auth_bloc/screens/cart/cart.dart';
import 'package:auth_bloc/screens/favourates/favourate.dart';
import 'package:auth_bloc/screens/home/ui/home_sceren.dart';
import 'package:auth_bloc/screens/orders/orders.dart';
import 'package:auth_bloc/screens/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart'; // Import rxdart

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

  Stream<DocumentSnapshot<Map<String, dynamic>>?>
      _getOldestActiveOrderStream() {
    User? user = FirebaseAuth.instance.currentUser;
    print("_getOldestActiveOrderStream() called");

    if (user != null) {
      print("User is logged in: ${user.uid}");
      return FirebaseFirestore.instance
          .collection('orders') // Make sure collection is 'orders'
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending'])
          .orderBy('dateCreated', descending: false)
          .limit(1)
          .snapshots()
          .debounceTime(const Duration(milliseconds: 500)) // RE-ADD DEBOUNCE!
          .map((snapshot) {
            print(
                "Snapshot received (after debounce): ${snapshot.docs.length} documents");
            if (snapshot.docs.isNotEmpty) {
              print("Oldest order document found: ${snapshot.docs.first.id}");
              return snapshot.docs.first;
            } else {
              print("No active orders found");
              return null;
            }
          });
    } else {
      print("No user logged in");
      return Stream.value(null);
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
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
            // CORRECTED: Use _getOldestActiveOrderStream() directly
            stream: _getOldestActiveOrderStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                // Check if stream is active
                if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.exists) {
                  Map<String, dynamic> orderData = snapshot.data!.data()!;
                  return _buildOrderCard(orderData);
                } else {
                  return const SizedBox
                      .shrink(); // Don't show card if no active order
                }
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                // Optionally show a loading indicator while waiting for initial data
                return const CircularProgressIndicator();
              } else {
                return const SizedBox
                    .shrink(); // Show nothing in other states (e.g., none, done, error)
              }
            },
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

  int _rebuildCount = 0; // Add rebuild counter

  Widget _buildOrderCard(Map<String, dynamic> orderData) {
    _rebuildCount++; // Increment rebuild counter
    print("Building _buildOrderCard, rebuildCount: $_rebuildCount");
    String orderNumber =
        (orderData['orderNumber'] ?? 'N/A').toString(); // Convert to String
    double totalAmount =
        (orderData['totalPrice'] ?? 0.0).toDouble(); // Changed to totalPrice
    String kitchenStatus =
        orderData['kitchenStatus'] ?? 'pending'; // Default to pending if null
    Timestamp dateCreated =
        orderData['dateCreated'] as Timestamp? ?? Timestamp.now();
    DateTime dateTime = dateCreated.toDate();
    String formattedDate =
        DateFormat('MMM d, HH:mm').format(dateTime); // Formatted date

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:
              MainAxisSize.min, // Ensure card takes minimal vertical space
          children: [
            Text('Order Number: $orderNumber',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Order Date: $formattedDate'),
            const SizedBox(height: 8),
            Text('Total Amount: \$${totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            _buildProgressBar(kitchenStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String kitchenStatus) {
    Color pendingColor = Colors.grey;
    Color cookingColor = Colors.grey;
    Color deliveryColor = Colors.grey;

    if (kitchenStatus == 'queue' || kitchenStatus == 'pending') {
      // Assuming 'queue' is the initial pending state
      pendingColor = Colors.orange;
    } else if (kitchenStatus == 'cooking') {
      pendingColor = Colors.orange;
      cookingColor = Colors.orange;
    } else if (kitchenStatus == 'packing') {
      pendingColor = Colors.orange;
      cookingColor = Colors.orange;
      deliveryColor = Colors.orange;
    }

    return Row(
      children: [
        _buildProgressSection('Pending', pendingColor),
        const SizedBox(width: 8),
        _buildProgressSection('Cooking', cookingColor),
        const SizedBox(width: 8),
        _buildProgressSection('Delivery', deliveryColor),
      ],
    );
  }

  Widget _buildProgressSection(String title, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
