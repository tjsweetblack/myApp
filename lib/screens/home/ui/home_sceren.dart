import 'package:auth_bloc/routing/routes.dart';

import 'package:auth_bloc/screens/product/product_details.dart';

import 'package:auth_bloc/screens/profile/profile.dart';

import 'package:carousel_slider/carousel_slider.dart'; // Updated import

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<List<Map<String, dynamic>>> _getTopPicks() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('burgers')
        .where('topPick', isEqualTo: true) // Filter for topPick = true

        .get();

    return snapshot.docs.map((doc) {
      return {
        'name': doc['name'],
        'imageUrl': doc['imageUrl'],
        'rating': doc['rating'],
        'price': doc['price'],
        'productID': doc.id,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getBurgers() async {
    var snapshot = await FirebaseFirestore.instance.collection('burgers').get();

    return snapshot.docs.map((doc) {
      return {
        'name': doc['name'],

        'imageUrl': doc['imageUrl'],

        'rating': doc['rating'],

        'price': doc['price'],

        'productID': doc.id, // Add productID to the map'
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CarouselSlider.builder(
                    options: CarouselOptions(
                      height: 200.0,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      aspectRatio: 16 / 9,
                      viewportFraction: 0.8,
                    ),
                    itemCount: 3,
                    itemBuilder:
                        (BuildContext context, int index, int realIndex) {
                      return Container(
                        margin: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          image: DecorationImage(
                              image: NetworkImage(
                                'https://cdn.printnetwork.com/production/assets/themes/5966561450122033bd4456f8/imageLocker/5f206dc35d4bff1ada62fb4c/blog/blog-description/1647973541988_restaurant-banner.png', // Replace with your ad URLs
                              ),
                              fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Color.fromARGB(255, 0, 0, 0),

                      margin: EdgeInsets.zero,

                      elevation: 4, // Add elevation for a card look

                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/logo/logo.png', // Your logo path

                              height: 80, // Adjust height as needed
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Criar seu hamburger",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, Routes.createBurger);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange, // Example

                                foregroundColor: Colors.white, // Example

                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: const Text("Começar Agora"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      "Best Deals",
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _getTopPicks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No top picks available'));
                  }

                  var topPicks = snapshot.data!;

                  return SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: topPicks.length,
                      itemBuilder: (context, index) {
                        var burger = topPicks[index];

                        return Padding(
                          padding: const EdgeInsets.all(8.0),

                          child: GestureDetector(
// Wrap with GestureDetector

                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailsPage(
                                      burgerId: burger['productID']),
                                ),
                              );
                            },

                            child: Column(
// Keep the Column *inside* GestureDetector

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Image.network(
                                  burger['imageUrl'],
                                  height: 150,
                                  width: 150,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  burger['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.yellow, size: 16),
                                    Text('${burger['rating']}'),
                                  ],
                                ),
                                Text('\$${burger['price']}'),
                              ],
                            ),
                          ),

// ... (GestureDetector and Column for topPicks remain the same)
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 24),
                child: Text(
                  "Our Burgers",
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
// Wrap SliverList in FutureBuilder

              future: _getBurgers(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()));
                }

                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                      child: Center(child: Text('Error: ${snapshot.error}')));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverToBoxAdapter(
                      child: Center(child: Text('No burgers available')));
                }

                var burgers = snapshot.data!;

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      if (index >= burgers.length) {
// Check index before accessing

                        return const SizedBox
                            .shrink(); // Return an empty widget
                      }

                      var burger = burgers[index];

                      return GestureDetector(
// GestureDetector *outside* Card

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsPage(
                                burgerId: burger['productID'],
                              ),
                            ),
                          );
                        },

                        child: Card(
// Card *inside* GestureDetector

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
                          ),
                        ),
                      );
                    },

                    childCount:
                        burgers.length, // Use the actual length of the list
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
// Spacer Box

              child: SizedBox(
                height: 70, // Height of the box

                width: double.infinity, // Occupy full width

                child: Container(
                  color:
                      Theme.of(context).canvasColor, // Match background color
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}
