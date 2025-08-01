import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  Future<DocumentSnapshot<Map<String, dynamic>>> _getOrderDetails() async {
    return FirebaseFirestore.instance.collection('orders').doc(orderId).get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getBurgerDetails(
      String burgerId) async {
    return FirebaseFirestore.instance.collection('burgers').doc(burgerId).get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getIngredientDetails(
      String ingredientId) async {
    return FirebaseFirestore.instance
        .collection('ingredients')
        .doc(ingredientId)
        .get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getSideDetails(
      String sideId) async {
    return FirebaseFirestore.instance.collection('sides').doc(sideId).get();
  }

  Future<void> _cancelOrder() async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': 'cancelled'});
      // Optionally show a success message to the user
      print('Order status updated to cancelled');
    } catch (e) {
      // Handle error, e.g., show an error message
      print('Error updating order status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getOrderDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found'));
          }

          final orderData = snapshot.data!.data()!;
          final items = orderData['items'] as List<dynamic>? ?? [];
          final sides = orderData['sides'] as List<dynamic>? ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Number
                  Text(
                    'Order Number',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text('#${orderData['orderNumber'] ?? 'N/A'}'),
                  const SizedBox(height: 16),

                  // Delivery Location
                  Text(
                    'Delivery Location',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text('${orderData['shippingAddress'] ?? 'N/A'}'),
                  const SizedBox(height: 16),

                  // Total Price
                  Text(
                    'Total Price to Pay',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                      '\Kz${(orderData['totalPrice'] ?? 0).toStringAsFixed(2)}'),
                  const SizedBox(height: 16),

                  // Payment Method
                  Text(
                    'Payment Method',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text('${orderData['paymentMethod'] ?? 'N/A'}'),
                  const SizedBox(height: 32),

                  // Sides Section
                  if (sides.isNotEmpty) ...[
                    Text(
                      'Sides',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Divider(),
                    SizedBox(
                      height: 100, // Adjusted height for row layout
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: sides.length,
                        itemBuilder: (context, index) {
                          final sideItem = sides[index];
                          final sideId = sideItem['sideId'] as String? ?? '';
                          final quantity = sideItem['quantity'] as num? ?? 1;

                          return FutureBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                            future: _getSideDetails(sideId),
                            builder: (context, sideSnapshot) {
                              if (sideSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!sideSnapshot.hasData ||
                                  !sideSnapshot.data!.exists) {
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Side not found'),
                                );
                              }

                              final sideData = sideSnapshot.data!.data()!;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal:
                                        8.0), // Horizontal padding for spacing
                                width: 140, // Adjusted width
                                child: Row(
                                  // Changed to Row for horizontal layout
                                  children: [
                                    Image.network(
                                      sideData['imageUrl'] ??
                                          'https://via.placeholder.com/80', // Placeholder image - reduced size
                                      height: 60, // Reduced image height
                                      width: 60, // Reduced image width
                                      fit: BoxFit.cover,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment
                                            .center, // Center text vertically in the row
                                        children: [
                                          Text(
                                            '${quantity}x ${sideData['name'] ?? 'N/A'}', // Quantity before name
                                            textAlign: TextAlign.left,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                            // Removed overflow: TextOverflow.ellipsis, // REMOVE ELLIPSIS HERE
                                            // Text should now wrap to multiple lines if needed
                                          ),
                                          // Removed Quantity Text here as it's in the main text now
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  Text(
                    'Order Items',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return FutureBuilder<
                          DocumentSnapshot<Map<String, dynamic>>>(
                        future: _getBurgerDetails(
                            item['productId'] as String? ?? ''),
                        builder: (context, burgerSnapshot) {
                          if (burgerSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (!burgerSnapshot.hasData ||
                              !burgerSnapshot.data!.exists) {
                            return const Text('Burger not found');
                          }

                          final burgerData = burgerSnapshot.data!.data()!;
                          final quantity = item['quantity'] as num? ?? 1;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.network(
                                      burgerData['imageUrl'] ??
                                          'https://via.placeholder.com/150', // Placeholder image
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            burgerData['name'] ?? 'N/A',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text('Quantity: $quantity'),
                                          Text(
                                              'Price: \Kz${(item['totalPrice'] ?? 0).toStringAsFixed(2)}'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // Display Ingredients for Custom Burgers
                                if (burgerData['custom'] == true &&
                                    (burgerData['ingredients']
                                                as List<dynamic>? ??
                                            [])
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Ingredients:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: (burgerData['ingredients']
                                                as List<dynamic>? ??
                                            [])
                                        .map((ingredientId) => FutureBuilder<
                                                DocumentSnapshot<
                                                    Map<String, dynamic>>>(
                                              future: _getIngredientDetails(
                                                  ingredientId),
                                              builder: (context,
                                                  ingredientSnapshot) {
                                                if (ingredientSnapshot
                                                        .connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const CircularProgressIndicator();
                                                }
                                                if (!ingredientSnapshot
                                                        .hasData ||
                                                    !ingredientSnapshot
                                                        .data!.exists) {
                                                  return const Text(
                                                      'Ingredient not found');
                                                }
                                                final ingredientData =
                                                    ingredientSnapshot.data!
                                                        .data()!;
                                                return Chip(
                                                  avatar: CircleAvatar(
                                                    backgroundImage:
                                                        NetworkImage(
                                                      ingredientData[
                                                              'imageUrl'] ??
                                                          'https://via.placeholder.com/50', // Placeholder image
                                                    ),
                                                  ),
                                                  label: Text(
                                                      ingredientData['name'] ??
                                                          'N/A'),
                                                  backgroundColor:
                                                      const Color.fromARGB(
                                                          255, 255, 255, 255),
                                                );
                                              },
                                            ))
                                        .toList(),
                                  ),
                                ] else if (item['extras'] != null &&
                                    (item['extras'] as List<dynamic>? ?? [])
                                        .isNotEmpty) ...[
                                  // Changed condition here
                                  // Display Extras if not a custom burger and extras are present
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Extras:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: (item['extras']
                                                as List<dynamic>? ??
                                            []) // Changed here too
                                        .map((extraId) => FutureBuilder<
                                                DocumentSnapshot<
                                                    Map<String, dynamic>>>(
                                              future: _getIngredientDetails(
                                                  extraId),
                                              builder:
                                                  (context, extraSnapshot) {
                                                if (extraSnapshot
                                                        .connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const CircularProgressIndicator();
                                                }
                                                if (!extraSnapshot.hasData ||
                                                    !extraSnapshot
                                                        .data!.exists) {
                                                  return const Text(
                                                      'Extra not found');
                                                }
                                                final extraData =
                                                    extraSnapshot.data!.data()!;
                                                print(extraSnapshot.data);
                                                return Chip(
                                                  avatar: CircleAvatar(
                                                    backgroundImage:
                                                        NetworkImage(
                                                      extraData['imageUrl'] ??
                                                          'https://via.placeholder.com/50', // Placeholder image
                                                    ),
                                                  ),
                                                  label: Text(
                                                      extraData['name'] ??
                                                          'N/A'),
                                                  backgroundColor:
                                                      const Color.fromARGB(
                                                          255, 255, 255, 255),
                                                );
                                              },
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
