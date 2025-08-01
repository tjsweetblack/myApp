import 'package:auth_bloc/screens/orders/order_details/order_details.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  int _currentStage = 0;
  String _orderNumber = 'N/A';
  bool _isOrderCancelled = false;
  late AnimationController _glowAnimationController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _orderId; // Variable to store the document UID

  @override
  void initState() {
    super.initState();
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _glowAnimationController.dispose();
    super.dispose();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _loadOrderData() {
    User? user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereNotIn: ['complete', 'cancelled'])
          .orderBy('dateCreated', descending: true)
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              return snapshot.docs.first
                  as DocumentSnapshot<Map<String, dynamic>>;
            } else {
              return null;
            }
          })
          .cast<DocumentSnapshot<Map<String, dynamic>>>();
    } else {
      return null;
    }
  }

  int _getStatusStage(String status, String kitchenStatus) {
    print(
        "Status in _getStatusStage: $status, Kitchen Status: $kitchenStatus"); // Debug print
    if (status == 'complete') {
      print("_getStatusStage returning: 4 (Completed)"); // Debug print
      return 4;
    } else if (kitchenStatus == 'packing') {
      print("_getStatusStage returning: 3 (Packing)"); // Debug print
      return 3;
    } else if (kitchenStatus == 'cooking') {
      print("_getStatusStage returning: 2 (Cooking)"); // Debug print
      return 2;
    } else {
      print("_getStatusStage returning: 1 (Pending)"); // Debug print
      return 1;
    }
  }

  void _cancelOrder(BuildContext buildContext) async {
    showDialog(
      context: buildContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text('Confirmation', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to cancel your order?',
              style: TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              child:
                  Text('No, Go Back', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text('Yes, Cancel',
                  style: TextStyle(color: Colors.redAccent)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog immediately
                try {
                  if (_orderId != null) {
                    await _firestore.collection('orders').doc(_orderId).update({
                      'status': 'cancelled',
                      'kitchenStatus': 'cancelled'
                    }); // Update status to 'cancelled' in Firestore
                    setState(() {
                      _isOrderCancelled = true; // Show cancelled screen
                      _currentStage = 4; // Enable exit like complete order
                    });
                    ScaffoldMessenger.of(buildContext).showSnackBar(
                      const SnackBar(content: Text('Order cancelled')),
                    );
                  } else {
                    ScaffoldMessenger.of(buildContext).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Error: Order ID not found. Cannot cancel.')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(buildContext).showSnackBar(
                    SnackBar(
                        content: Text('Failed to cancel order. Error: ${e}')),
                  );
                  print('Error cancelling order: $e'); // Log the error
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _viewOrderDetails(String orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsPage(
            orderId: orderId), // Assuming OrderDetailsPage is imported
      ),
    );
  }

  void _showWaitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must explicitly dismiss the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text('Please Wait', style: TextStyle(color: Colors.white)),
          content: Text(
              'You must wait until your order is complete to leave the page.',
              style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenContext = context;
    return PopScope(
      canPop: _currentStage == 4 ||
          _isOrderCancelled, // Exit if complete or cancelled
      child: Scaffold(
        backgroundColor: Colors.black,
        // No AppBar
        body: Stack(
          // Use Stack to overlay Exit button
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              // StreamBuilder to listen to order data
              stream: _loadOrderData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.white70)));
                }
                if (!snapshot.hasData ||
                    snapshot.data == null ||
                    !snapshot.data!.exists) {
                  return const Center(
                      child: Text(
                          'No active order found.\nPlace an order to track it here.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 16, color: Colors.white70)));
                }

                final orderData = snapshot.data!.data()!;
                _orderNumber = '#${orderData['orderNumber'] ?? "N/A"}';
                _currentStage = _getStatusStage(
                    orderData['status'] ?? 'pending',
                    orderData['kitchenStatus'] ?? 'queue');
                _orderId = snapshot.data!.id;

                print("Current Stage in StreamBuilder: $_currentStage");

                return _isOrderCancelled
                    ? Center(
                        child: Text('Order Cancelled',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white70)))
                    : Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              const SizedBox(height: 40),
                              Image.asset(
                                'assets/images/orderStatus.png',
                                height: 300,
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Your order is on the way!',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Please wait...',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),
                              _buildOrderInfoRow('Order number:', _orderNumber),
                              const SizedBox(height: 20),
                              _buildOrderInfoRow(
                                  'Order status:',
                                  _getStatusText(_currentStage,
                                      orderData: null)),
                              const SizedBox(height: 10),
                              OrderProgressBar(
                                  currentStage: _currentStage,
                                  glowAnimation: _glowAnimationController),
                              const SizedBox(height: 40),
                              ElevatedButton(
                                onPressed: () => _viewOrderDetails(_orderId!),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('View Order Details',
                                    style: TextStyle(fontSize: 16)),
                              ),
                              const SizedBox(height: 10),
                              if (_currentStage == 1)
                                TextButton(
                                  onPressed: () => _cancelOrder(screenContext),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.redAccent),
                                  child: const Text('Cancel Order',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.redAccent)),
                                )
                              else
                                SizedBox
                                    .shrink(), // Hide button for other stages
                            ],
                          ),
                        ),
                      );
              },
            ),
            Positioned(
              // Exit Button positioned at top
              top: 20.0,
              left: 10.0,
              child: TextButton(
                onPressed: () {
                  if (_currentStage == 4 || _isOrderCancelled) {
                    // Allow exit if cancelled
                    Navigator.of(context)
                        .pop(); // Exit if complete or cancelled
                  } else {
                    _showWaitDialog(); // Show dialog if not complete
                  }
                },
                child: const Text('Exit',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(int stage, {Map<String, dynamic>? orderData}) {
    switch (stage) {
      case 1:
        return 'Pending';
      case 2:
        return 'Cooking';
      case 3:
        return 'Packing';
      case 4:
        return 'Complete';
      default:
        return 'Unknown';
    }
  }

  Widget _buildOrderInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ],
    );
  }
}

class OrderProgressBar extends StatelessWidget {
  final int currentStage;
  final AnimationController glowAnimation;

  const OrderProgressBar(
      {super.key, required this.currentStage, required this.glowAnimation});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildProgressPoint('Pending', 1),
        Expanded(
          child: AnimatedBuilder(
            animation: glowAnimation,
            builder: (context, child) {
              return _buildGlowingProgressLine(
                  isActive: currentStage >= 2, animation: glowAnimation);
            },
          ),
        ),
        _buildProgressPoint('Cooking', 2),
        Expanded(
          child: AnimatedBuilder(
            animation: glowAnimation,
            builder: (context, child) {
              return _buildGlowingProgressLine(
                  isActive: currentStage >= 3, animation: glowAnimation);
            },
          ),
        ),
        _buildProgressPoint('Packing', 3),
        Expanded(
          child: AnimatedBuilder(
            animation: glowAnimation,
            builder: (context, child) {
              return _buildGlowingProgressLine(
                  isActive: currentStage >= 4, animation: glowAnimation);
            },
          ),
        ),
        _buildProgressPoint('Complete', 4),
      ],
    );
  }

  Widget _buildProgressPoint(String label, int stage) {
    bool isActive = currentStage >= stage;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.orange : Colors.grey.shade700,
            border: Border.all(color: isActive ? Colors.blue : Colors.white70),
          ),
          child: Center(
            child: Icon(
              isActive
                  ? Icons.check
                  : Icons.close, // Conditionally set the IconData
              color: isActive
                  ? Colors.white
                  : Colors.white, // Keep color white, or adjust as needed
              size: 16,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(color: isActive ? Colors.white : Colors.white70),
        ),
      ],
    );
  }

  Widget _buildProgressLine({required bool isActive}) {
    return Container(
      height: 2,
      color: isActive ? Colors.blue : Colors.grey.shade700,
    );
  }

  Widget _buildGlowingProgressLine(
      {required bool isActive, required AnimationController animation}) {
    if (!isActive) {
      return _buildProgressLine(isActive: false);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.3),
                Colors.transparent,
                Colors.transparent,
              ],
              stops: [
                animation.value,
                math.max(0.0, animation.value - 0.1),
                math.max(0.0, animation.value - 0.4),
                1.0,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            height: 2,
            width: constraints.maxWidth,
            color: Colors.orange,
          ),
        );
      },
    );
  }
}
