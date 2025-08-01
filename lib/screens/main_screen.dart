import 'package:auth_bloc/screens/cart/cart.dart';
import 'package:auth_bloc/screens/favourates/favourate.dart';
import 'package:auth_bloc/screens/home/ui/home_sceren.dart';
import 'package:auth_bloc/screens/orders/order_tracking/order_tracking.dart';
import 'package:auth_bloc/screens/orders/orders.dart';
import 'package:auth_bloc/screens/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// Placeholder for your Order Tracking Screen - Replace with your actual screen


class MainScreen extends StatefulWidget {
  final int initialTabIndex; // Add this parameter

  const MainScreen(
      {super.key, this.initialTabIndex = 0}); // Default to Home tab (index 0)

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _appBarTitle = 'Home';
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _orderStreamSubscription;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    MyOrdersPage(),
    CartScreen(),
    FavoritesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex; // Set initial index from widget parameter
    _updateAppBarTitle(_selectedIndex); // Set initial app bar title
    _checkPendingOrderAndNavigateMainScreen(); // **CHECK PENDING ORDER HERE ON INIT**
  }

  Future<void> _checkPendingOrderAndNavigateMainScreen() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;

        // Query Firestore to check for pending orders
        QuerySnapshot pendingOrdersSnapshot = await FirebaseFirestore.instance
            .collection('orders') // Replace 'orders' with your orders collection name
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending') // Assuming 'pending' is your status value
            .limit(1) // We only need to know if at least one pending order exists
            .get();

        if (pendingOrdersSnapshot.docs.isNotEmpty) {
          // User has a pending order, navigate to OrderTrackingScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OrderTrackingScreen()), // Navigate to OrderTrackingScreen
          );
          return; // Important: Exit the function after navigation
        }
      }
    } catch (e) {
      print("Error checking for pending order in MainScreen: $e");
      // Optionally handle error, maybe show a snackbar or log.
      // But crucial: DO NOT block MainScreen loading if the check fails.
      // The user should still be able to use the app even if order check has a temporary issue.
    }
    // If no pending order found (or error in check), MainScreen will load normally.
  }


  // Helper function to update AppBar title based on index
  void _updateAppBarTitle(int index) {
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
      default:
        _appBarTitle = 'Home'; // Default case, shouldn't happen normally
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _updateAppBarTitle(index); // Update app bar title when tab is tapped
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

  // Stream to check for active orders
  Stream<QuerySnapshot<Map<String, dynamic>>> _getActiveOrdersStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status',
              isEqualTo: 'pending') // Changed to 'isEqualTo: pending'
          .snapshots();
    } else {
      return Stream.empty();
    }
  }

  @override
  void dispose() {
    _orderStreamSubscription
        ?.cancel(); // Cancel subscription when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        title: Text(
          _appBarTitle,
          style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        ),
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
                    'https://t3.ftcdn.net/jpg/05/70/71/06/360_F_570710660_Jana1ujcJyQTiT2rIzvfmyXzXamVcby8.jpg'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
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
          const BottomNavigationBarItem(
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