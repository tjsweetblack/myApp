import 'package:auth_bloc/logic/cubit/auth_cubit.dart';
import 'package:auth_bloc/screens/profile/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> replicateDocument(String collection, String docId) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  // Reference to the original document
  DocumentReference originalDocRef = firestore.collection(collection).doc(docId);
  
  // Get the document snapshot
  DocumentSnapshot docSnap = await originalDocRef.get();

  if (docSnap.exists) {
    // Copy data
    Map<String, dynamic> data = docSnap.data() as Map<String, dynamic>;

    // Create a new document with a randomly generated ID in the same collection
    DocumentReference newDocRef = firestore.collection(collection).doc();
    
    // Save the document
    await newDocRef.set(data);
    print("Document replicated successfully! New ID: ${newDocRef.id}");
  } else {
    print("Document not found!");
  }
}

class HomeScreen extends StatelessWidget {
  // Fetch data from Firestore
  Future<List<Map<String, dynamic>>> _getTopPicks() async {
    var snapshot = await FirebaseFirestore.instance.collection('top_picks').get();
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
                backgroundImage: NetworkImage('https://cdn4.iconfinder.com/data/icons/glyphs/24/icons_user-512.png'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Text
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
              style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 30, bottom: 20, start: 16, end: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for burgers...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),

          // Our Top Picks Text
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              "Our Top Picks",
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
          ),

          // FutureBuilder to fetch and display the data from Firestore
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getTopPicks(),  // Fetch top picks from Firestore
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No top picks available'));
              }

              var topPicks = snapshot.data!;

              return Container(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: topPicks.length,  // Use the actual count of fetched burgers
                  itemBuilder: (context, index) {
                    var burger = topPicks[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display the burger image using the URL from Firestore
                          Image.network(
                            burger['imageUrl'],
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(height: 8),
                          // Display the burger name
                          Text(
                            burger['name'],
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.yellow, size: 16),
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

          // Floating Action Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FloatingActionButton(
                onPressed: () {
                  // Navigate to Create Burger Screen
                },
                child: Icon(Icons.add),
                backgroundColor: Colors.orange,
                tooltip: 'Create Your Burger',
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Optional, ensures the items don't have labels floating
        selectedItemColor: Colors.black, // This sets the color for the selected icon/text
        unselectedItemColor: const Color.fromARGB(255, 65, 64, 64), // This sets the color for the unselected icon/text
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
      ),
    );
  }
}
