import 'package:auth_bloc/screens/cart/cart.dart';
import 'package:auth_bloc/screens/home/ui/home_sceren.dart';
import 'package:auth_bloc/screens/orders/orders.dart';
import 'package:flutter/material.dart';
// ... other imports (your routes, screens, etc.)

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Index of the currently selected screen
  String _appBarTitle = 'Home'; // Title of the app bar

  // Define your screens
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Your existing HomeScreen
    MyOrdersPage(), // Your existing MyOrdersPage
    CartScreen(),
    // Add other screens here as needed
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        centerTitle: true,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex), // Show selected screen
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Order',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
        currentIndex: _selectedIndex, // Highlight selected item
        onTap: _onItemTapped, // Handle item taps
      ),
    );
  }
}
