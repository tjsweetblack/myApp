import 'package:flutter/material.dart';

class BurgerApp extends StatelessWidget {
  const BurgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Burger Builder',
      theme: ThemeData(
        primarySwatch: Colors.red, // Customize your theme
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
  // Sample Data (Replace with your actual data fetching)
  final Map<String, List<BurgerItem>> burgerOptions = {
    'Bun': [
      BurgerItem('Brioche', 0.0, 'images/brioche.png'), // Add image paths
      BurgerItem('Seeded', 0.0, 'images/seeded.png'),
      BurgerItem('Lettuce', 0.0, 'images/lettuce.png'),
    ],
    'Patty': [
      BurgerItem('Beef', 11.95, 'images/beef.png'),
      BurgerItem('Chicken', 10.95, 'images/chicken.png'),
      BurgerItem('Beyond', 10.95, 'images/beyond.png'),
    ],
    'Toppings': [
      BurgerItem('Ketchup', 0.0, 'images/ketchup.png'),
      BurgerItem('Mayo', 0.0, 'images/mayo.png'),
      BurgerItem('BBQ', 0.0, 'images/bbq.png'),
    ],
  };

  Map<String, BurgerItem?> selectedOptions = {}; // Track selected items
  double totalPrice = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Burger Builder'),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              // Handle close action
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: burgerOptions.entries.map((entry) {
                String category = entry.key;
                List<BurgerItem> items = entry.value;

                return buildCategorySection(category, items);
              }).toList(),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('£${totalPrice.toStringAsFixed(2)}'),
                ElevatedButton(
                  onPressed: () {
                    // Handle add to basket
                  },
                  child: Text('Add to Basket'),
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
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Wrap( // Use Wrap for responsive layout
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
    bool isSelected = selectedOptions[category] == item;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedOptions.remove(category);
            totalPrice -= item.price;
          } else {
            selectedOptions[category] = item;
            totalPrice = selectedOptions.values.fold(0, (sum, item) => sum + (item?.price ?? 0));
          }
        });
      },
      child: Card(
        color: isSelected ? Colors.red[100] : null, // Highlight selected card
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Image.asset(item.imagePath, height: 80), // Display image
              Text(item.name),
              Text('£${item.price.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ),
    );
  }
}

class BurgerItem {
  final String name;
  final double price;
  final String imagePath;

  BurgerItem(this.name, this.price, this.imagePath);
}