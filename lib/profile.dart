import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person, size: 80, color: Colors.blue),
                const SizedBox(height: 20),

                Text(
                  "Username: ${user?.displayName ?? "Not set"}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),

                Text(
                  "Email: ${user?.email ?? "Not available"}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),

                Text(
                  "Phone: ${user?.phoneNumber ?? "Not provided"}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
