import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BurgerApp extends StatelessWidget {
  const BurgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Burger Builder',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: BurgerBuilderScreen(),
    );
  }
}

class BurgerBuilderScreen extends StatefulWidget {
  const BurgerBuilderScreen({super.key});

  @override
  _BurgerBuilderScreenState createState() => _BurgerBuilderScreenState();
}

class _BurgerBuilderScreenState extends State<BurgerBuilderScreen> {
  Map<String, List<BurgerItem>> burgerOptions = {};
  Map<String, Map<BurgerItem, int>> selectedOptions = {};
  double totalPrice = 0.0;
  bool _isLoading = true;
  String newBurgerName = '';

  @override
  void initState() {
    super.initState();
    _loadIngredients();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBurgerNameDialog();
    });
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
        options[category]!.add(BurgerItem(name, price, imagePath));
      }

      setState(() {
        burgerOptions = options;
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Name Your Burger'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Enter burger name',
            ),
            onChanged: (value) {
              newBurgerName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {}); // Trigger rebuild to show the name
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Burger Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          if (newBurgerName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Your Burger Name: $newBurgerName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView(
                    children: burgerOptions.entries.map((entry) {
                      String category = entry.key;
                      List<BurgerItem> items = entry.value;
                      return buildCategorySection(category, items);
                    }).toList(),
                  ),
                ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('£${totalPrice.toStringAsFixed(2)}'),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Add to Basket'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCategorySection(String category, List<BurgerItem> items) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: items.map((item) => buildBurgerItemCard(item, category)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBurgerItemCard(BurgerItem item, String category) {
    int quantity = selectedOptions[category]?[item] ?? 0;

    return IntrinsicWidth(
      child: Card(
        color: quantity > 0 ? Colors.red[100] : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.network(
                item.imagePath,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('£${item.price.toStringAsFixed(2)}'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: quantity > 0
                        ? () {
                            setState(() {
                              quantity--;
                              if (quantity == 0) {
                                selectedOptions[category]?.remove(item);
                                if (selectedOptions[category]?.isEmpty == true) {
                                  selectedOptions.remove(category);
                                }
                              } else {
                                selectedOptions.putIfAbsent(category, () => {})[item] = quantity;
                              }
                              _calculateTotalPrice();
                            });
                          }
                        : null,
                  ),
                  Text('$quantity'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        quantity++;
                        if (category == 'Bread') {
                          selectedOptions[category]?.clear();
                        }
                        selectedOptions.putIfAbsent(category, () => {})[item] = quantity;
                        _calculateTotalPrice();
                      });
                    },
                  ),
                ],
              ),
            ],
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

class BurgerItem {
  final String name;
  final double price;
  final String imagePath;

  BurgerItem(this.name, this.price, this.imagePath);
}