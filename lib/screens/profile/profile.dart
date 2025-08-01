import 'package:auth_bloc/logic/cubit/auth_cubit.dart';
import 'package:auth_bloc/routing/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _phoneController;

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();

    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();

    super.dispose();
  }

  void _updatePhoneNumber(String userId) async {
    if (_phoneController.text.isEmpty) return;
    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'phoneNumber': _phoneController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor:
                Colors.grey, // Background color for visibility on black

            content: Text('Phone number updated successfully!',
                style: TextStyle(color: Colors.white))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor:
                Colors.grey, // Background color for visibility on black

            content: Text('Error updating phone number: $e',
                style: TextStyle(color: Colors.white))),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = context.watch<AuthCubit>();

    final user = authCubit.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(
            child: Text("No user logged in", style: TextStyle(fontSize: 18))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black, // Black background

      appBar: AppBar(
        title: const Text("User Profile",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white)), // White text

        backgroundColor: Colors.black, // Black AppBar background

        elevation: 0, // Removes shadow

        iconTheme: const IconThemeData(color: Colors.white), // White back arrow
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Colors.white)); // White indicator
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white))); // White text
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: Text('No user data found.',
                    style: TextStyle(color: Colors.white))); // White text
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
// Center content vertically and horizontally

              child: SingleChildScrollView(
// Added for scrollability

                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center vertically

                  crossAxisAlignment: CrossAxisAlignment
                      .center, // Center horizontally in column

                  children: [
                    Center(

                      child: CircleAvatar(
                        radius: 60, // Slightly larger avatar

                        backgroundImage: NetworkImage(
                          userData['photoURL'] ??
                              'https://cdn4.iconfinder.com/data/icons/glyphs/24/icons_user-512.png',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildProfileRow("Name", userData['name'] ?? ''),
                    _buildProfileRow("Email", userData['email'] ?? ''),
                    _buildProfileRow("Phone", userData['phoneNumber'] ?? ''),
                    const SizedBox(height: 24),
                    const Text(
                      "Do you wish to change your phone number?",

                      textAlign: TextAlign.center, // Center text

                      style: TextStyle(
                        fontSize: 18,

                        fontWeight: FontWeight.bold,

                        color: Colors.white, // White text
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,

                      style: const TextStyle(
                          color: Colors.white), // White input text

                      decoration: const InputDecoration(
                        labelText: "Change Number",

                        labelStyle: TextStyle(
                            color: Colors.white70), // Light white for label

                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.white70), // Light white border
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.white), // White focused border
                        ),
                      ),

                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    Center(
// Center the buttons

                      child: ElevatedButton(
                        onPressed: _isUpdating
                            ? null
                            : () => _updatePhoneNumber(user.uid),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.white, // White background for button

                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12), // Adjusted padding

                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: _isUpdating
                            ? const CircularProgressIndicator(
                                color: Colors.black) // Black loading indicator
                            : const Text(
                                'Update Phone Number',
                                style: TextStyle(
                                    color:
                                        Colors.black), // Black text for button
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
// Center the buttons

                      child: ElevatedButton(
                        onPressed: () async {
                          await authCubit.signOut();

                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              Routes.loginScreen,
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 12),
                          textStyle: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Center align text in rows

        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white)), // White bold label

          Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, color: Colors.white)), // White value
        ],
      ),
    );
  }
}
