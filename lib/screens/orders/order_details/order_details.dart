import 'package:flutter/material.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                'https://cdni.iconscout.com/illustration/premium/thumb/boy-with-no-goods-in-shopping-cart-illustration-download-svg-png-gif-file-formats--empty-order-data-basket-pack-e-commerce-illustrations-10018100.png', // Replace with your user's profile image URL
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Order',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Delivered'),
              ],
            ),

            const SizedBox(height: 16),

            // Restaurant Info
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://cdni.iconscout.com/illustration/premium/thumb/boy-with-no-goods-in-shopping-cart-illustration-download-svg-png-gif-file-formats--empty-order-data-basket-pack-e-commerce-illustrations-10018100.png', // Replace with your restaurant logo URL
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Pizza Hut',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Rembang, Jateng'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Order Date and Code
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('20 Jun 10:30'),
                Text('Code #264100'),
              ],
            ),

            const SizedBox(height: 32),

            // Order Item
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  'https://cdni.iconscout.com/illustration/premium/thumb/boy-with-no-goods-in-shopping-cart-illustration-download-svg-png-gif-file-formats--empty-order-data-basket-pack-e-commerce-illustrations-10018100.png', // Replace with your image URL
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Chicken Nuget',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Softdrink, Lettuce & Nuget'),
                      Text('\$8.80'),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Customer Info
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://cdni.iconscout.com/illustration/premium/thumb/boy-with-no-goods-in-shopping-cart-illustration-download-svg-png-gif-file-formats--empty-order-data-basket-pack-e-commerce-illustrations-10018100.png', // Replace with your customer's profile image URL
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Farion Wick',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('ID: DK5-501F9'),
                  ],
                ),
                const Spacer(), // Add spacer to push icons to the right
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.message),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.phone),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Payment Info
            Row(
              children: [
                Image.network(
                  'https://cdni.iconscout.com/illustration/premium/thumb/boy-with-no-goods-in-shopping-cart-illustration-download-svg-png-gif-file-formats--empty-order-data-basket-pack-e-commerce-illustrations-10018100.png', // Replace with your payment method logo URL
                  height: 40,
                  width: 40,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                const Text('Credit Card\n6219 8610 2888 8075'),
              ],
            ),

            const SizedBox(height: 32),

            // Totals
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Subtotal'),
                    Text('\$8.80'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Delivery'),
                    Text('\$2.20'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$11.00',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle "Rate" button press
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      textStyle: const TextStyle(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Rate'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle "Re-Order" button press
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      textStyle: const TextStyle(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Re-Order'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}