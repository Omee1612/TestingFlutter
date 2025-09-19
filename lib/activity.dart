import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  // Helper to return item
  Future<void> returnItem(String docId) async {
    await FirebaseFirestore.instance
        .collection("borrowedItems")
        .doc(docId)
        .delete();
  }

  // Helper to cancel job
  Future<void> cancelJob(String docId) async {
    await FirebaseFirestore.instance
        .collection("jobsTaken")
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Please log in to see your activities."));
    }

    final DateFormat formatter = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- Borrowed Items ----------------
              const SectionTitle(
                title: "Borrowed Items",
                icon: Icons.shopping_bag,
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("borrowedItems")
                    .where("userId", isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final items = snapshot.data!.docs;
                  if (items.isEmpty) return const Text("No borrowed items.");

                  return Column(
                    children: items.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ActivityCard(
                        title: data['itemName'] ?? "Unnamed item",
                        subtitle:
                            "Borrowed on: ${data['timestamp'] != null ? formatter.format((data['timestamp'] as Timestamp).toDate()) : ""}",
                        icon: Icons.shopping_bag,
                        color: Colors.orangeAccent,
                        actionText: "Return",
                        onActionPressed: () => returnItem(doc.id),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              // ---------------- Jobs Taken ----------------
              const SectionTitle(title: "Jobs Taken", icon: Icons.work),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("jobsTaken")
                    .where("userId", isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final jobs = snapshot.data!.docs;
                  if (jobs.isEmpty) return const Text("No jobs taken.");

                  return Column(
                    children: jobs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ActivityCard(
                        title: data['jobTitle'] ?? "Unnamed job",
                        subtitle:
                            "Taken on: ${data['timestamp'] != null ? formatter.format((data['timestamp'] as Timestamp).toDate()) : ""}",
                        icon: Icons.work,
                        color: Colors.blueAccent,
                        actionText: "Cancel",
                        onActionPressed: () => cancelJob(doc.id),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              // ---------------- Blood Donations ----------------
              const SectionTitle(
                title: "Blood Donations",
                icon: Icons.bloodtype,
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("bloodDonations")
                    .where("userId", isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final donations = snapshot.data!.docs;
                  if (donations.isEmpty)
                    return const Text("No blood donations.");

                  return Column(
                    children: donations.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ActivityCard(
                        title: "Donation",
                        subtitle:
                            "Date: ${data['timestamp'] != null ? formatter.format((data['timestamp'] as Timestamp).toDate()) : ""}\nLocation: ${data['location'] ?? "N/A"}",
                        icon: Icons.bloodtype,
                        color: Colors.redAccent,
                        actionText: "",
                        onActionPressed: null,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------- Section Title Widget ----------------
class SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const SectionTitle({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 28),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }
}

/// ---------------- Activity Card Widget ----------------
class ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String actionText;
  final VoidCallback? onActionPressed;

  const ActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.actionText = "",
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Text(subtitle),
        trailing: actionText.isNotEmpty
            ? ElevatedButton(
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionText),
              )
            : null,
      ),
    );
  }
}
