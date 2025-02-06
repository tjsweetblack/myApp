import 'package:auth_bloc/routing/routes.dart';
import 'package:auth_bloc/screens/profile/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// ... other imports

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<List<Map<String, dynamic>>> _getTopPicks() async {
    var snapshot =
        await FirebaseFirestore.instance.collection('top_picks').get();
    return snapshot.docs.map((doc) {
      return {
        'name': doc['name'],
        'imageUrl': doc['imageUrl'],
        'rating': doc['rating'],
        'price': doc['price'],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 240, 240, 240),
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
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
      body: CustomScrollView(
        // Use CustomScrollView for scrolling
        slivers: <Widget>[
          SliverToBoxAdapter(
            // Welcome Text, etc.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Important!
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Let's find your",
                    style: TextStyle(fontSize: 30, color: Colors.black),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    "Burger!!",
                    style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      top: 30, bottom: 20, start: 16, end: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for burgers...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)),
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    "Our Top Picks",
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            // FutureBuilder & ListView
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
                  // Set a fixed height!
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: topPicks.length,
                    itemBuilder: (context, index) {
                      var burger = topPicks[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
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
                                  fontWeight: FontWeight.bold, fontSize: 16),
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
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, Routes.productDetails);
          },
          backgroundColor: Colors.orange,
          tooltip: 'Create Your Burger',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
