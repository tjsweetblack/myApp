import 'package:auth_bloc/routing/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BurgerApp extends StatelessWidget {
  const BurgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Burger Builder',
      theme: ThemeData(
        fontFamily: 'Roboto', // Modern font
        primarySwatch: Colors.amber, // Using amber as a base, can be customized
        scaffoldBackgroundColor:
            const Color(0xFFf5f5f5), // Light grey background
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.amber,
          accentColor: const Color(0xFFffcc80), // Lighter amber accent
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF333333), // Dark app bar
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Colors.black, // Explicitly set bottom bar color to black
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFffcc80), // Accent button color
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0), // Rounded buttons
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF333333),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: const BurgerBuilderScreen(),
    );
  }
}

class BurgerBuilderScreen extends StatefulWidget {
  const BurgerBuilderScreen({super.key});

  @override
  State<BurgerBuilderScreen> createState() => _BurgerBuilderScreenState();
}

class _BurgerBuilderScreenState extends State<BurgerBuilderScreen> {
  Map<String, List<BurgerItem>> burgerOptions = {};
  Map<String, Map<BurgerItem, int>> selectedOptions = {};
  double totalPrice = 0.0;
  bool _isLoading = true;
  String newBurgerName = '';
  List<BurgerItem> _orderedSelectedItems = []; // Track selected items order
  bool _breadSelected = false; // Track if bread is selected
  bool _nameValid = false; // Track if burger name is valid
  bool _isAddingToCart = false; // Loading state for Add to Cart Button

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _getUser();
    _loadIngredients();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBurgerNameDialog();
    });
  }

  Future<void> _getUser() async {
    _user = _auth.currentUser;
    setState(() {});
  }

  Future<void> _loadIngredients() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('ingredients').get();

      Map<String, List<BurgerItem>> options = {};

      for (var doc in snapshot.docs) {
        String category = doc['category'];
        String name = doc['name'];
        double price = (doc['price'] as num).toDouble();
        String imagePath = doc['imageUrl'];

        if (!options.containsKey(category)) {
          options[category] = [];
        }
        options[category]!.add(
            BurgerItem(name, price, imagePath, category)); // Corrected line
      }

      // Ensure 'pao' category is always first
      Map<String, List<BurgerItem>> orderedOptions = {};
      if (options.containsKey('pao')) {
        orderedOptions['pao'] = options['pao']!;
      }
      options.forEach((key, value) {
        if (key != 'pao') {
          orderedOptions[key] = value;
        }
      });

      setState(() {
        burgerOptions = orderedOptions; // Use ordered options map
        _isLoading = false;
      });
    } catch (error) {
      print("Error loading ingredients: $error");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading ingredients: $error')),
      );
    }
  }

  void _showBurgerNameDialog() {
    newBurgerName = ''; // Reset name when dialog is shown again
    _nameValid = false; // Reset name validity
    showDialog(
      context: context,
      barrierDismissible: false, // Make dialog mandatory
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Use StatefulBuilder to manage dialog's state
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: const Text('Name Your Burger',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      errorText: _nameValid ? null : 'Burger name is required',
                      hintText: 'Enter burger name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.secondary),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) {
                      newBurgerName = value;
                      dialogSetState(() {
                        // Update dialog state
                        _nameValid = value.isNotEmpty;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _nameValid
                      ? () {
                          Navigator.of(context).pop();
                          setState(() {}); // Trigger rebuild to show the name
                        }
                      : null, // Disable button if name is invalid
                  child: const Text('Continue',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createAndAddToCart() async {
    int totalSelectedItems = 0;
    selectedOptions.forEach((category, items) {
      items.forEach((item, quantity) {
        totalSelectedItems += quantity;
      });
    });

    if (totalSelectedItems < 5) {
      _showErrorDialog('Please select at least 5 items to create a burger.');
      return;
    }

    if (!selectedOptions.containsKey('patty') ||
        selectedOptions['patty']!.isEmpty) {
      _showErrorDialog('Please select at least one patty.');
      return;
    }

    if (selectedOptions.isEmpty || !_breadSelected) {
      _showErrorDialog(
          'Please select a bread and ingredients to create a burger.');
      return;
    }

    // If all conditions are met, show quantity dialog
    _showQuantityDialog();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.black,
              contentTextStyle: TextStyle(color: Colors.white),
            ),
          ),
          child: AlertDialog(
            title: const Text(
              'Esta a faltar algo.',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showQuantityDialog() async {
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
                    _addToCartWithQuantity(
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

  Future<void> _addToCartWithQuantity(int quantity) async {
    setState(() {
      _isAddingToCart = true; // Start loading
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You must be logged in to create a burger.')),
        );
        return;
      }

      List<Future<String>> ingredientIdFutures = [];
      double burgerPrice = 0;

      selectedOptions.forEach((category, items) {
        items.forEach((item, qty) {
          for (int i = 0; i < qty; i++) {
            // Use the quantity from selectedOptions
            ingredientIdFutures.add(_getIngredientIdByName(item.name));
          }
          burgerPrice +=
              item.price * qty; // Use the quantity from selectedOptions
        });
      });

      final resolvedIngredientIds = await Future.wait(ingredientIdFutures);

      final burgerRef =
          await FirebaseFirestore.instance.collection('burgers').add({
        'name': newBurgerName,
        'description': 'Custom Burger',
        'imageUrl':
            'https://img.lovepik.com/png/20231117/cartoon-burger-sticker-for-burger-app-logo-vector-clipart-tummy_613421_wh300.png',
        'ingredients': resolvedIngredientIds,
        'price': burgerPrice,
        'rating': 0,
        'topPick': false,
        'custom': true,
        'userId': user.uid, // ADD USER ID HERE
      });

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
        'productId': burgerRef.id,
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

      showDialog<void>(
        context: context,
        barrierDismissible: false, // User must tap a button to close
        builder: (BuildContext dialogContext) {
          return Theme(
            // Apply theme for AlertDialog
            data: Theme.of(context).copyWith(
              dialogTheme: const DialogThemeData(
                backgroundColor: Colors.black, // Black background for dialog
              ),
            ),
            child: AlertDialog(
              title: const Text('Successfully added to cart!',
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
                    ); // Close the dialog
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
                    ); // First close the dialog
                  },
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        selectedOptions.clear();
        totalPrice = 0.0;
        newBurgerName = '';
        _orderedSelectedItems.clear(); // Clear ordered items on cart add
        _breadSelected = false; // Reset bread selection state
      });
    } catch (error) {
      setState(() {
        _isAddingToCart = false; // Stop loading even in error
      });
      print('Error creating and adding to cart: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating and adding to cart: $error')),
      );
    }
  }

  Future<String> _getIngredientIdByName(String name) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('ingredients')
        .where('name', isEqualTo: name)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    } else {
      throw Exception('Ingredient with name "$name" not found.');
    }
  }

  Widget _buildTopBottomLabels() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("baixo",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF555555))),
          const Text("cima",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF555555))),
        ],
      ),
    );
  }

  Widget _buildSelectedItemsRow() {
    List<Widget> selectedItemImages = [];
    BurgerItem? bread;
    List<BurgerItem> ingredientsBetweenBread = [];

    for (var item in _orderedSelectedItems) {
      if (item.category == 'pao') {
        bread = item; // Assuming only one bread can be selected
      } else {
        ingredientsBetweenBread.add(item);
      }
    }

    if (bread != null) {
      selectedItemImages.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6.0),
            child: Image.network(
              bread.imagePath,
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
      for (var item in ingredientsBetweenBread) {
        selectedItemImages.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: Image.network(
                item.imagePath,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }
      selectedItemImages.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6.0),
            child: Image.network(
              bread.imagePath,
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    } else {
      for (var item in _orderedSelectedItems) {
        // If no bread, show all linearly (fallback)
        selectedItemImages.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: Image.network(
                item.imagePath,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }
    }

    return Container(
      height: 40, // Fixed height for the row
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: selectedItemImages,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Burger Builder'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              // TODO: Implement cart navigation
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (newBurgerName.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Center(
                child: Text(
                  'Your Burger Name: $newBurgerName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (newBurgerName
              .isNotEmpty) // Conditionally build labels and selected items row
            _buildTopBottomLabels(),
          if (newBurgerName.isNotEmpty) _buildSelectedItemsRow(),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    children: burgerOptions.entries.map((entry) {
                      String category = entry.key;
                      List<BurgerItem> items = entry.value;
                      return buildCategorySection(
                          category,
                          items,
                          category == 'pao' ||
                              _breadSelected); // Pass breadSelected state
                    }).toList(),
                  ),
                ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black, // Enforce black bottom bar color
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: Kz${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              Stack(
                // Stack to overlay button and loading indicator
                alignment: Alignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isAddingToCart
                        ? null
                        : _createAndAddToCart, // Disable button when loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Add to Cart',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
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

  Widget buildCategorySection(
      String category, List<BurgerItem> items, bool enabled) {
    // Added enabled parameter
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: enabled
            ? Colors.white
            : Colors.grey[100], // Grey out category section if disabled
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              category,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: enabled
                      ? Color(0xFF333333)
                      : Colors.grey[400]), // Grey out title if disabled
            ),
          ),
          Divider(
              height: 10,
              thickness: 1.5,
              color: enabled
                  ? Colors.grey
                  : Colors.grey[200]), // Grey out divider if disabled
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: items
                .map((item) => buildBurgerItemCard(
                    item, category, enabled)) // Pass enabled state to item card
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget buildBurgerItemCard(
      BurgerItem item, String category, bool categoryEnabled) {
    // Added categoryEnabled parameter
    int quantity = selectedOptions[category]?[item] ?? 0;
    bool ispaoCategory = category == 'pao';
    bool enabled =
        categoryEnabled || ispaoCategory; // Always enable pao category

    return IntrinsicWidth(
      child: GestureDetector(
        // Wrap Container with GestureDetector
        onTap: ispaoCategory &&
                enabled // Only handle tap for pao category and when enabled
            ? () {
                setState(() {
                  selectedOptions[category]
                      ?.clear(); // Clear any previous pao selection
                  _orderedSelectedItems.removeWhere((orderedItem) =>
                      orderedItem.category == 'pao'); // Clear ordered pao
                  if (quantity == 0) {
                    // Select if not already selected
                    selectedOptions.putIfAbsent(category, () => {})[item] = 1;
                    _orderedSelectedItems.add(item); // Add to ordered list
                    _breadSelected = true; // Set bread as selected
                    quantity = 1; // Set quantity to 1 for UI
                  } else {
                    // Deselect if already selected (optional, you can remove this if you don't want deselect on re-tap)
                    selectedOptions[category]?.remove(item);
                    _orderedSelectedItems.removeLastOccurrence(item);
                    quantity = 0;
                    _breadSelected =
                        false; // Update bread selected state if no bread selected
                  }
                  _calculateTotalPrice();
                });
              }
            : null, // No tap action for other categories or when disabled
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: quantity > 0
                  ? Colors.orange[200]!
                  : Colors.grey[300]!, // Slightly stronger orange highlight
              width: 1,
            ),
            color: quantity > 0
                ? Colors.orange[50]
                : Colors.white, // Lighter background when selected
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Opacity(
                    // Grey out image if disabled
                    opacity: enabled ? 1.0 : 0.5,
                    child: Image.network(
                      item.imagePath,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(item.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: enabled
                              ? Color(0xFF333333)
                              : Colors.grey[400])), // Grey out name if disabled
                ),
                Text('Kz${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 14, // Slightly increased size for price
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold)),
                if (!ispaoCategory) // Conditionally show +/- buttons for non-pao categories
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.grey),
                        onPressed: quantity > 0 &&
                                enabled // Conditionally enable remove button
                            ? () {
                                setState(() {
                                  quantity--;
                                  if (quantity == 0) {
                                    selectedOptions[category]?.remove(item);
                                    if (selectedOptions[category]?.isEmpty ==
                                        true) {
                                      selectedOptions.remove(category);
                                    }
                                    _orderedSelectedItems.removeLastOccurrence(
                                        item); // Remove from ordered list
                                  } else {
                                    selectedOptions[category]![item] =
                                        quantity; // Update quantity
                                  }
                                  _calculateTotalPrice();
                                });
                              }
                            : null,
                      ),
                      Text('$quantity',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: enabled
                                  ? Color(0xFF555555)
                                  : Colors.grey[
                                      400])), // Grey out quantity if disabled
                      IconButton(
                        icon: Icon(Icons.add_circle,
                            color: Theme.of(context).colorScheme.secondary),
                        onPressed: enabled
                            ? () {
                                setState(() {
                                  quantity++;
                                  if (ispaoCategory) {
                                    // This part is now redundant as buttons are removed for pao
                                    selectedOptions[category]?.clear();
                                    _orderedSelectedItems.removeWhere(
                                        (orderedItem) =>
                                            orderedItem.category ==
                                            'pao'); // Clear existing pao
                                    selectedOptions.putIfAbsent(
                                            category, () => {})[item] =
                                        1; // Only one pao
                                    _orderedSelectedItems
                                        .add(item); // Add pao to ordered list
                                    quantity =
                                        1; // Reset quantity to 1 for pao in UI
                                    _breadSelected =
                                        true; // Set bread as selected
                                  } else {
                                    if (!_breadSelected) {
                                      _showErrorDialog(
                                          'Please select a bread first from "pao" category to enable other ingredients.');
                                      return; // Exit without adding ingredient
                                    }
                                    selectedOptions.putIfAbsent(
                                            category, () => {})[item] =
                                        quantity; // Update quantity
                                    _orderedSelectedItems
                                        .add(item); // Add to ordered list
                                  }
                                  _calculateTotalPrice();
                                });
                              }
                            : () {
                                // Added else block for disabled button tap
                                _showErrorDialog(
                                    'Please select a bread first from "pao" category to enable other ingredients.');
                              },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _calculateTotalPrice() {
    totalPrice = 0;
    selectedOptions.forEach((category, items) {
      items.forEach((item, quantity) {
        totalPrice += item.price * quantity;
      });
    });
  }
}

extension ListExt<T> on List<T> {
  void removeLastOccurrence(T element) {
    int index = -1;
    for (int i = 0; i < length; i++) {
      if (this[i] == element) {
        // Assuming BurgerItem == is implemented properly or using isSameItem check
        index = i;
      }
    }
    if (index != -1) {
      removeAt(index);
    }
  }
}

class BurgerItem {
  final String name;
  final double price;
  final String imagePath;
  final String category; // Added category to BurgerItem for easier filtering

  BurgerItem(this.name, this.price, this.imagePath, this.category);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BurgerItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          category == other.category; // Important for comparison in lists

  @override
  int get hashCode => name.hashCode ^ category.hashCode;
}
