import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Login first"));

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------- Borrow Requests ----------------
          const SectionTitle(
            title: "Borrow Requests",
            icon: Icons.shopping_bag,
          ),
          const SizedBox(height: 8),
          StreamSection(
            query: FirebaseFirestore.instance
                .collection("quickBorrowRequests")
                .where("itemOwnerId", isEqualTo: user.uid)
                .orderBy('timestamp', descending: true),
            emptyText: "No incoming requests.",
            itemBuilder: (doc) {
              final data = doc.data();
              final status = data?['status'] ?? 'PENDING';
              final timestamp = data?['timestamp'] as Timestamp?;
              return InfoCard(
                title: data?['itemName'] ?? "Unnamed item",
                subtitle:
                    "Requested by: ${data?['requesterName'] ?? 'Unknown'}\nStatus: $status\nRequested on: ${timestamp != null ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate()) : 'N/A'}",
                icon: Icons.shopping_cart,
                color: Colors.orangeAccent,
              );
            },
          ),

          const SizedBox(height: 20),
          // ---------------- Job Requests ----------------
          const SectionTitle(title: "Job Requests", icon: Icons.work),
          const SizedBox(height: 8),
          StreamSection(
            query: FirebaseFirestore.instance
                .collection("oddJobRequests")
                .where("ownerId", isEqualTo: user.uid)
                .orderBy('timestamp', descending: true),
            emptyText: "No job requests.",
            itemBuilder: (doc) {
              final data = doc.data();
              final status = data?['status'] ?? 'PENDING';
              final timestamp = data?['timestamp'] as Timestamp?;
              return InfoCard(
                title: data?['jobTitle'] ?? "Unnamed job",
                subtitle:
                    "Requested by: ${data?['requesterName'] ?? 'Unknown'}\nStatus: $status\nRequested on: ${timestamp != null ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate()) : 'N/A'}",
                icon: Icons.work,
                color: Colors.blueAccent,
              );
            },
          ),

          const SizedBox(height: 20),
          // ---------------- Blood Donation Requests ----------------
          const SectionTitle(
            title: "Blood Donation Requests",
            icon: Icons.bloodtype,
          ),
          const SizedBox(height: 8),
          StreamSection(
            query: FirebaseFirestore.instance
                .collection("bloodDonationRequests")
                .where("ownerId", isEqualTo: user.uid)
                .orderBy('timestamp', descending: true),
            emptyText: "No blood donation requests.",
            itemBuilder: (doc) {
              final data = doc.data();
              final status = data?['status'] ?? 'PENDING';
              final timestamp = data?['timestamp'] as Timestamp?;
              return InfoCard(
                title: "Blood Donation",
                subtitle:
                    "Requested by: ${data?['requesterName'] ?? 'Unknown'}\nStatus: $status\nRequested on: ${timestamp != null ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate()) : 'N/A'}",
                icon: Icons.bloodtype,
                color: Colors.redAccent,
              );
            },
          ),

          const SizedBox(height: 20),
          // ---------------- Poster Notifications ----------------
          const SectionTitle(
            title: "My Notifications",
            icon: Icons.notifications,
          ),
          const SizedBox(height: 8),
          StreamSection(
            query: FirebaseFirestore.instance
                .collection('userNotifications')
                .doc(user.uid)
                .collection('notifications')
                .orderBy('timestamp', descending: true),
            emptyText: "No notifications yet.",
            itemBuilder: (doc) {
              final data = doc.data();
              final timestamp = data?['timestamp'] as Timestamp?;
              final seen = data?['seen'] ?? false;
              return InkWell(
                onTap: () async {
                  if (!seen) await doc.reference.update({'seen': true});
                },
                child: InfoCard(
                  title: data?['message'] ?? "No message",
                  subtitle: timestamp != null
                      ? DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(timestamp.toDate())
                      : "",
                  icon: Icons.notifications,
                  color: seen ? Colors.grey : Colors.deepPurple,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------- Stream Section ----------------
class StreamSection extends StatelessWidget {
  final Query<Map<String, dynamic>> query;
  final Widget Function(DocumentSnapshot<Map<String, dynamic>>) itemBuilder;
  final String emptyText;

  const StreamSection({
    super.key,
    required this.query,
    required this.itemBuilder,
    this.emptyText = "No items.",
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return Text(emptyText);
        final validDocs = snapshot.data!.docs
            .where((d) => d.data().isNotEmpty)
            .toList();
        if (validDocs.isEmpty) return Text(emptyText);
        return Column(children: validDocs.map(itemBuilder).toList());
      },
    );
  }
}

// ---------------- Section Title ----------------
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

// ---------------- Info Card ----------------
class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const InfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
