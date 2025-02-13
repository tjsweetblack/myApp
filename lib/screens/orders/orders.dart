import 'package:auth_bloc/routing/routes.dart'; // Import your routes
import 'package:auth_bloc/screens/home/ui/home_sceren.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class MyOrdersPageStateModel extends ChangeNotifier {
  List<Map<String, dynamic>> upcomingOrders = [];
  List<Map<String, dynamic>> pastOrders = [];
  bool isLoading = true;
  bool showUpcoming = true;

  void toggleShowUpcoming() {
    showUpcoming = !showUpcoming;
    notifyListeners();
  }

  // No longer need loadOrders() here

  void updateOrders(List<Map<String, dynamic>> allOrders) {
    // Helper function
    upcomingOrders =
        allOrders.where((order) => order['status'] == 'pending').toList();
    pastOrders = allOrders
        .where((order) =>
            order['status'] == 'cancelled' || order['status'] == 'complete')
        .toList();
    isLoading = false;
    notifyListeners();
  }
}

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  late MyOrdersPageStateModel _model;

  @override
  void initState() {
    super.initState();
    _model = MyOrdersPageStateModel();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MyOrdersPageStateModel>(
      create: (context) => _model,
      child: Consumer<MyOrdersPageStateModel>(
        builder: (context, model, child) {
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot>(
                // Use StreamBuilder
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('userId',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Something went wrong: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Text("No orders found."));
                  }

                  List<Map<String, dynamic>> allOrders =
                      snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> orderData =
                        doc.data() as Map<String, dynamic>;
                    return orderData; // Include the orderId
                  }).toList();

                  model.updateOrders(
                      allOrders); // Update the orders in the model

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ... (Your Toggle Buttons - same as before)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              model.toggleShowUpcoming();
                            },
                            child: Text(
                              'Upcoming',
                              style: TextStyle(
                                color: model.showUpcoming
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: model.showUpcoming
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              model.toggleShowUpcoming();
                            },
                            child: Text(
                              'History',
                              style: TextStyle(
                                color: !model.showUpcoming
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: !model.showUpcoming
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      model.isLoading // Use the model's isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : model.showUpcoming
                              ? _buildOrderList(
                                  model.upcomingOrders, 'No upcoming orders')
                              : _buildOrderList(
                                  model.pastOrders, 'No past orders'),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderList(
      List<Map<String, dynamic>> orders, String emptyMessage) {
    return orders.isEmpty
        ? Center(
            child: Column(
              children: [
                Image.network(
                  'https://cdni.iconscout.com/illustration/premium/thumb/boy-with-no-goods-in-shopping-cart-illustration-download-svg-png-gif-file-formats--empty-order-data-basket-pack-e-commerce-illustrations-10018100.png',
                  height: 100,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    textStyle: const TextStyle(color: Colors.white),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Discover Now',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        : Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  child: ListTile(
                    title: Text('Order number: ${order['orderNumber']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${order['status']}'),
                        Text('Total Price: ${order['totalPrice']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
  }
}
