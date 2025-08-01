import 'package:auth_bloc/routing/routes.dart';
import 'package:auth_bloc/screens/home/ui/home_sceren.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class MyOrdersPageStateModel extends ChangeNotifier {
  List<Map<String, dynamic>> pastOrders = [];
  bool _isLoading = true;
  String? errorMessage;

  bool get isLoading => _isLoading;

  void updateOrders(List<Map<String, dynamic>> allOrders) {
    errorMessage = null;
    pastOrders = allOrders
        .where((order) =>
            order['status'] == 'cancelled' || order['status'] == 'complete')
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  void setLoading() {
    _isLoading = true;
    errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _isLoading = false;
    errorMessage = message;
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
            backgroundColor: Colors.grey[100],
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildContent(model),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(MyOrdersPageStateModel model) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('status',
              whereIn: ['cancelled', 'complete']) // Filter for past orders
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          model.setError('Something went wrong: ${snapshot.error}');
          return _buildErrorUI(model.errorMessage!);
        }

        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            model.setLoading();
            return const Center(child: CircularProgressIndicator());
          default:
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              model.updateOrders([]);
              return _buildNoOrdersUI();
            } else {
              List<Map<String, dynamic>> allOrders =
                  snapshot.data!.docs.map((doc) {
                Map<String, dynamic> orderData =
                    doc.data() as Map<String, dynamic>;
                return {
                  ...orderData,
                  'id': doc.id,
                };
              }).toList();
              model.updateOrders(allOrders);
              return _buildPastOrderPageContent(
                  model); // Build specific past orders content
            }
        }
      },
    );
  }

  Widget _buildErrorUI(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            'Error Loading Past Orders',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPastOrderPageContent(MyOrdersPageStateModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image at the top
        SizedBox(
          width: double.infinity,
          height: 150, // Adjust height as needed
          child: Image.asset(
            'assets/images/pastOrders.png', // Replace with your image URL
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16), // Added SizedBox for spacing
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8.0), // Added padding for text
          child: Text(
            'My Past Orders', // Text below image
            style: TextStyle(
              fontSize: 24, // Adjust font size as needed
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800, // Darker grey for emphasis
            ),
          ),
        ),
        const SizedBox(height: 24),
        model.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildPastOrderList(model.pastOrders, 'No past orders found'),
      ],
    );
  }

  Widget _buildNoOrdersUI() {
    return _NoOrdersPlaceholder(emptyMessage: 'No past orders found.');
  }

  Widget _buildPastOrderList(
      List<Map<String, dynamic>> orders, String emptyMessage) {
    return orders.isEmpty
        ? _NoOrdersPlaceholder(emptyMessage: emptyMessage)
        : Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderListItem(order: order); // Reuse _OrderListItem
              },
            ),
          );
  }
}

// Reuse _OrderListItem and _NoOrdersPlaceholder widgets from MyOrdersPage
class _OrderListItem extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderListItem({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${order['orderNumber']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status: ${order['status']}',
                  style: TextStyle(color: _getStatusColor(order['status'])),
                ),
                Text(
                  'Total: \$${order['totalPrice']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Routes.orderDetails,
                    arguments: {'orderId': order['id']},
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('View Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange[700]!;
      case 'complete':
        return Colors.green[700]!;
      case 'cancelled':
        return Colors.red[700]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

// Reuse _NoOrdersPlaceholder widget from MyOrdersPage
class _NoOrdersPlaceholder extends StatelessWidget {
  final String? emptyMessage;

  const _NoOrdersPlaceholder({this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    final message = emptyMessage ?? 'No orders found.';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            // Consider adding a past orders specific image here if desired
            'https://cdni.iconscout.com/illustration/premium/thumb/girl-holding-empty-shopping-cart-illustration-download-in-svg-png-gif-file-formats--no-items-online-stroller-pack-e-commerce-illustrations-10018095.png?f=webp',
            height: 100,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.image_not_supported,
              size: 200,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Past Orders', // Changed text to reflect past orders
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                Routes.mainScreen,
                arguments: 0,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0)),
            ),
            child: const Text(
              'Discover Now',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
