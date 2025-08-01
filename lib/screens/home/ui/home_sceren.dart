import 'package:auth_bloc/routing/routes.dart';
import 'package:auth_bloc/screens/home/ui/widgets/product_card.dart';
import 'package:auth_bloc/screens/orders/order_tracking/order_tracking.dart';
import 'package:auth_bloc/screens/product/product_details.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Map<String, dynamic>>> _getTopPicks() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('burgers')
        .where('topPick', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'name':
            _truncateText(doc['name'], 15), // Truncate name to 15 characters
        'imageUrl': doc['imageUrl'],
        'price': doc['price'],
        'productID': doc.id,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getBurgers() async {
    var snapshot = await FirebaseFirestore.instance.collection('burgers').get();

    List<Map<String, dynamic>> burgers = [];

    for (var doc in snapshot.docs) {
      if (!doc.data().containsKey('custom')) {
        await doc.reference.update({'custom': false});
      }
      if (doc['custom'] == false) {
        burgers.add({
          'name':
              _truncateText(doc['name'], 15), // Truncate name to 15 characters
          'imageUrl': doc['imageUrl'],
          'price': doc['price'],
          'productID': doc.id,
        });
      }
    }

    return burgers;
  }

  Future<String?> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        return userDoc.data()?['name'] as String?;
      }
    }
    return null;
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return text.substring(0, maxLength) + '...';
    }
  }

  // New function to fetch advertisements from Firestore
  Future<List<Map<String, dynamic>>> _getAdvertisements() async {
    var snapshot =
        await FirebaseFirestore.instance.collection('advertisement').get();

    return snapshot.docs.map((doc) {
      return {
        'imageUrl': doc[
            'imageUrl'], // Assuming 'imageUrl' field exists in your 'advertisement' collection
        // You can add other fields from your advertisement documents if needed
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                backgroundColor: Colors.white,
                pinned: true,
                expandedHeight: 70.0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  title: Container(
                    height: 70.0,
                    alignment: Alignment.centerLeft,
                    color: const Color.fromARGB(
                        255, 0, 0, 0), // White app bar container
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: FutureBuilder<String?>(
                      future: _getUserName(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text(
                            "Hi User",
                            style: TextStyle(
                              color: const Color.fromRGBO(255, 255, 255, 1),
                              fontSize: 18.0,
                            ),
                          );
                        }
                        final userName = snapshot.data;
                        return Text(
                          userName != null ? "Hi $userName" : "Hi User",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getAdvertisements(), // Fetch advertisements here
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                              height: 200,
                              child: Center(
                                  child:
                                      CircularProgressIndicator())); // Show loading indicator while fetching
                        }
                        if (snapshot.hasError) {
                          return SizedBox(
                            height: 200,
                            child: Center(
                                child: Text(
                                    'Error loading advertisements: ${snapshot.error}')), // Show error message if fetch fails
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const SizedBox(
                            height: 200,
                            child: Center(
                                child: Text(
                                    'No advertisements available')), // Show message if no advertisements
                          );
                        }

                        final advertisements = snapshot.data!;

                        return CarouselSlider.builder(
                          options: CarouselOptions(
                            height: 200.0,
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 16 / 9,
                            viewportFraction: 0.8,
                          ),
                          itemCount: advertisements
                              .length, // Dynamic count from advertisement data
                          itemBuilder:
                              (BuildContext context, int index, int realIndex) {
                            var advertisement = advertisements[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                image: DecorationImage(
                                    image: NetworkImage(
                                      advertisement[
                                          'imageUrl'], // Use imageUrl from Firestore data
                                    ),
                                    fit: BoxFit.cover),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(
                          16.0), // <--- This Padding was causing the issue
                      child: Card(
                        color: Colors.black.withOpacity(0.9),
                        margin: EdgeInsets
                            .zero, // <-- Add this to remove default card margins
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(
                              16.0), // Keep padding for content inside the card
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment
                                .stretch, // <-- Optional: stretch column children
                            children: [
                              Image.asset(
                                'assets/images/logo/logo.png',
                                height: 80,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Criar seu hamburger",
                                textAlign: TextAlign.center,
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
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: const Text("Começar Agora",
                                    style: TextStyle(color: Colors.black)),
                              ),
                              const SizedBox(
                                  height: 8), // Add spacing between buttons
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context,
                                      Routes
                                          .myCustomBurgersScreen); // Replace with your actual route name
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors
                                      .orange, // Example styling - adjust as needed
                                ),
                                child: const Text("See My Creations",
                                    style: TextStyle(
                                        color: Colors
                                            .white)), // White text for visibility on black card
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        "Our Menu",
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.grey.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        "Best Deals",
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade700),
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
                      return const Center(
                          child: Text('No top picks available'));
                    }

                    var topPicks = snapshot.data!;

                    return ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 320,
                      ),
                      child: SizedBox(
                        child: ListView.separated(
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 15.0),
                          itemCount: topPicks.length,
                          itemBuilder: (context, index) {
                            var burger = topPicks[index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailsPage(
                                        burgerId: burger['productID']),
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 200,
                                child: ProductCard(
                                  imageUrl: burger['imageUrl'],
                                  productName: burger['name'],
                                  price: (burger['price'] as num).toDouble(),
                                  currency: '\kz',
                                  cardColor: Colors.white,
                                  textColor: Colors.black,
                                  borderRadius: 12.0,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProductDetailsPage(
                                                burgerId: burger['productID']),
                                      ),
                                    );
                                  },
                                  categoryName: '',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 20.0, top: 20, bottom: 12),
                  child: Text(
                    "Our Burgers",
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors
                            .grey.shade700), // Grey and smaller for subheading
                  ),
                ),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
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
                    // Changed to SliverList from SliverGrid
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        if (index >= burgers.length) {
                          return const SizedBox.shrink();
                        }

                        var burger = burgers[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical:
                                  8.0), // Added vertical padding for spacing between cards
                          child: ProductCard(
                            imageUrl: burger['imageUrl'],
                            productName: burger['name'],
                            price: (burger['price'] as num).toDouble(),
                            currency: '\Kz', // Keep your currency
                            cardColor: Colors.white,
                            textColor: Colors.black,
                            borderRadius: 12.0,
                            height: 320,
                            categoryName: '', // Or 'Burgers' if you prefer
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
                          ),
                        );
                      },
                      childCount: burgers.length,
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: Container(
                    color: Theme.of(context).canvasColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
