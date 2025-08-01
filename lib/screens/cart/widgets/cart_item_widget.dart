import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemWidget extends StatefulWidget {
  // Change to StatefulWidget
  final Map<String, dynamic> item;
  final Future<void> Function(String cartId, String productId) onRemoveItem;
  final Future<void> Function(String cartId, int quantity, String productId)
      onUpdateQuantity;
  final Future<void> Function() onLoadCartItems;
  final Function() showCheckoutBottomSheet;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    required this.onLoadCartItems,
    required this.showCheckoutBottomSheet,
  });

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  List<Map<String, String>> _extrasDetails = [];
  List<Map<String, String>> _ingredientsDetails = [];
  bool _detailsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItemDetails();
  }

  Future<void> _loadItemDetails() async {
    print(
        "CartItemWidget: _loadItemDetails started for product: ${widget.item['productName']}");
    setState(() {
      _detailsLoading = true;
    });

    List<Future<DocumentSnapshot>> extrasFutures = [];
    List<Future<DocumentSnapshot>> ingredientsFutures = [];

    String? productId = widget.item['productId'] as String?;
    bool isCustomBurger = false; // Initialize as false

    if (productId != null) {
      print(
          "CartItemWidget: Fetching product document for productId: $productId");
      DocumentSnapshot productDoc = await FirebaseFirestore.instance
          .collection(
              'burgers') // Replace 'burgers' with your product collection name if different
          .doc(productId)
          .get();

      if (productDoc.exists) {
        Map<String, dynamic>? productData =
            productDoc.data() as Map<String, dynamic>?;
        if (productData != null) {
          isCustomBurger = productData['custom'] as bool? ??
              false; // Determine if burger is custom
        } else {
          print(
              "CartItemWidget: Warning: Product document data is null for productId: $productId");
        }
      } else {
        print(
            "CartItemWidget: Warning: Product document does not exist for productId: $productId");
      }
    } else {
      print("CartItemWidget: Warning: productId is null in cart item.");
    }

    // 1. Fetch Extras (ONLY if burger is NOT custom)
    if (!isCustomBurger) {
      List<dynamic>? extrasData =
          widget.item['itemData']?['extras'] as List<dynamic>?;
      List<String> extraUids = extrasData?.cast<String>().toList() ?? [];
      print("CartItemWidget: (Non-Custom Burger) extraUids: $extraUids");
      for (String extraUid in extraUids) {
        print("CartItemWidget: Fetching extra with UID: $extraUid");
        extrasFutures.add(FirebaseFirestore.instance
            .collection('ingredients')
            .doc(extraUid)
            .get());
      }
    } else {
      print("CartItemWidget: (Custom Burger) Skipping extras fetch.");
    }

    // 2. Fetch Ingredients (ONLY if burger IS custom)
    if (isCustomBurger) {
      if (productId != null) {
        // Re-check productId to be safe
        DocumentSnapshot productDoc = await FirebaseFirestore.instance
            .collection('burgers') // Assuming 'burgers' collection
            .doc(productId)
            .get(); // Re-fetch productDoc if needed - or reuse from above if scope allows

        if (productDoc.exists) {
          Map<String, dynamic>? productData =
              productDoc.data() as Map<String, dynamic>?;
          if (productData != null) {
            List<dynamic>? ingredientUidsData =
                productData['ingredients'] as List<dynamic>?;
            List<String> ingredientUids =
                ingredientUidsData?.cast<String>().toList() ?? [];

            print(
                "CartItemWidget: (Custom Burger) Ingredient UIDs from product doc: $ingredientUids");
            for (String ingredientUid in ingredientUids) {
              print(
                  "CartItemWidget: Fetching ingredient with UID: $ingredientUid");
              ingredientsFutures.add(FirebaseFirestore.instance
                  .collection('ingredients')
                  .doc(ingredientUid)
                  .get());
            }
          } else {
            print(
                "CartItemWidget: Warning: Product document data is null for productId: $productId");
          }
        } else {
          print(
              "CartItemWidget: Warning: Product document does not exist for productId: $productId");
        }
      }
    } else {
      print("CartItemWidget: (Non-Custom Burger) Skipping ingredient fetch.");
    }

    print("CartItemWidget: Waiting for futures to complete...");
    List<DocumentSnapshot> extraDocs = await Future.wait(extrasFutures);
    List<DocumentSnapshot> ingredientDocs =
        await Future.wait(ingredientsFutures);
    print("CartItemWidget: Futures completed.");

    _extrasDetails = extraDocs.map((doc) {
      print("Mapping extra doc: ${doc.id}");
      return _mapExtraIngredientDocToMap(doc);
    }).toList();
    _ingredientsDetails = ingredientDocs.map((doc) {
      print("Mapping ingredient doc: ${doc.id}");
      return _mapExtraIngredientDocToMap(doc);
    }).toList();

    setState(() {
      _extrasDetails = _extrasDetails;
      _ingredientsDetails = _ingredientsDetails;
      _detailsLoading = false;
      print("CartItemWidget: _detailsLoading set to false, details updated.");
    });
  }

  // Helper function to map DocumentSnapshot to Map<String, String> for extras/ingredients
  Map<String, String> _mapExtraIngredientDocToMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data != null && data['name'] != null) {
      print(
          "Mapping successful for doc: ${doc.id}, name: ${data['name']}, imageUrl: ${data['imageUrl']}");
      return {
        'name': data['name'] as String? ?? '',
        'imageUrl': data['imageUrl'] as String? ?? '',
      };
    } else {
      print(
          "Warning: Missing 'name' or 'imageUrl' field in extra/ingredient document: ${doc.id}");
      return {'name': '', 'imageUrl': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    print("CartItemWidget build - widget.item: ${widget.item}");
    return Card(
      color: Colors.white, // Card color set to white
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          // Changed to Column to organize content vertically
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    widget.item['imageUrl'] ??
                        'URL_DE_IMAGEN_POR_DEFECTO', // Default image URL
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(
                            width: 80,
                            height: 80,
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700])), // Name heading
                      Text(
                        widget.item['productName'] ?? 'Product Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Price:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700])), // Price heading
                      Text(
                        '\Kz${widget.item['price']?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              Colors.orange.shade700, // Darker shade of orange
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        // Quantity Section as Column, moved outside of Row
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Quantity:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700])), // Quantity heading
                          Text(
                            widget.item['quantity'].toString(),
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Chips Section (Ingredients and Extras) - Conditionally render based on loading - Placed below main details
            if (!_detailsLoading)
              Padding(
                padding: const EdgeInsets.only(
                    top: 10.0), // Add some space above chips
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ingredients Chips (Show only if _ingredientsDetails is not empty)
                    if (_ingredientsDetails.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Ingredients:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black), // Black text
                          ),
                          Wrap(
                            children: _ingredientsDetails
                                .map<Widget>((ingredientMap) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Chip(
                                  avatar: (ingredientMap['imageUrl'] != null &&
                                          ingredientMap['imageUrl']!.isNotEmpty)
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(
                                              ingredientMap['imageUrl']!),
                                        )
                                      : null,
                                  label: Text(
                                    ingredientMap['name'] ?? 'N/A',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  backgroundColor:
                                      Colors.white, // Lighter grey for chips
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    // Extras Chips (Show only if _extrasDetails is not empty)
                    if (_extrasDetails.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Extras:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)), // Black text
                          Wrap(
                            children: _extrasDetails.map<Widget>((extraMap) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Chip(
                                  avatar: (extraMap['imageUrl'] != null &&
                                          extraMap['imageUrl']!.isNotEmpty)
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(
                                              extraMap['imageUrl']!))
                                      : null,
                                  label: Text(
                                    extraMap['name'] ?? 'N/A',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  backgroundColor:
                                      Colors.white, // Lighter grey for chips
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: CircularProgressIndicator(
                  color: Colors.orange,
                  strokeWidth: 2.0,
                ), // Loading indicator for details
              ),
            // Remove from cart button at the bottom
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Center(
                child: TextButton(
                  onPressed: () async {
                    await widget.onRemoveItem(
                        widget.item['cartId'], widget.item['productId']);
                    widget.onLoadCartItems();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red, // Red text color for remove
                  ),
                  child: const Text(
                    'Remove from cart',
                    style: TextStyle(color: Colors.red), // Red text color
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
