import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final formatter = DateFormat('dd MMM yyyy');

    if (user == null) {
      return const Center(child: Text("Please log in to see your activities."));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text(
          "Activity",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------- Borrow Requests ----------------
          const SectionTitle(
            title: "Borrow Requests",
            icon: Icons.notifications,
          ),
          const SizedBox(height: 8),
          StreamSection(
            query: FirebaseFirestore.instance
                .collection("quickBorrowRequests")
                .where("itemOwnerId", isEqualTo: user.uid),
            emptyText: "No incoming requests.",
            itemBuilder: (doc) {
              final data = doc.data();
              return ActivityCard(
                title: data?['itemName'] ?? "Unnamed item",
                subtitle:
                    "Requested by: ${data?['requesterName'] ?? 'Unknown'}\nStatus: ${data?['status'] ?? 'PENDING'}",
                icon: Icons.shopping_cart,
                color: Colors.orangeAccent,
                onDualAction: (accepted) async {
                  if (accepted) {
                    await FirebaseFirestore.instance
                        .collection("borrowedItems")
                        .add({
                          "itemName": data?['itemName'] ?? '',
                          "userId": data?['requesterId'] ?? '',
                          "ownerId": user.uid,
                          "timestamp": FieldValue.serverTimestamp(),
                        });
                  }
                  await FirebaseFirestore.instance
                      .collection("quickBorrowRequests")
                      .doc(doc.id)
                      .delete();
                },
              );
            },
          ),

          const SizedBox(height: 20),
          const SectionTitle(title: "Borrowed Items", icon: Icons.shopping_bag),
          const SizedBox(height: 8),
          StreamSection(
            query: FirebaseFirestore.instance
                .collection("borrowedItems")
                .where("userId", isEqualTo: user.uid),
            emptyText: "No borrowed items.",
            itemBuilder: (doc) {
              final data = doc.data();
              final timestamp = data?['timestamp'] as Timestamp?;
              return ActivityCard(
                title: data?['itemName'] ?? "Unnamed item",
                subtitle: timestamp != null
                    ? "Borrowed on: ${formatter.format(timestamp.toDate())}"
                    : "Borrowed on: N/A",
                icon: Icons.shopping_bag,
                color: Colors.orange,
                actionText: "Return",
                onActionPressed: () => FirebaseFirestore.instance
                    .collection("borrowedItems")
                    .doc(doc.id)
                    .delete(),
              );
            },
          ),

          const SizedBox(height: 20),
          const SectionTitle(title: "Jobs Taken", icon: Icons.work),
          const SizedBox(height: 8),
          StreamSection(
            query: FirebaseFirestore.instance
                .collection("jobsTaken")
                .where("userId", isEqualTo: user.uid),
            emptyText: "No jobs taken.",
            itemBuilder: (doc) {
              final data = doc.data();
              final timestamp = data?['timestamp'] as Timestamp?;
              return ActivityCard(
                title: data?['jobTitle'] ?? "Unnamed job",
                subtitle: timestamp != null
                    ? "Taken on: ${formatter.format(timestamp.toDate())}"
                    : "Taken on: N/A",
                icon: Icons.work,
                color: Colors.blueAccent,
                actionText: "Cancel",
                onActionPressed: () => FirebaseFirestore.instance
                    .collection("jobsTaken")
                    .doc(doc.id)
                    .delete(),
              );
            },
          ),

          const SizedBox(height: 20),
          const SectionTitle(title: "Jobs Posted", icon: Icons.post_add),
          const SizedBox(height: 8),
          StreamSection(
            query: FirebaseFirestore.instance
                .collection("oddjobs")
                .where("userId", isEqualTo: user.uid),
            emptyText: "No jobs posted.",
            itemBuilder: (doc) {
              final data = doc.data();
              final timestamp = data?['createdAt'] as Timestamp?;
              return ActivityCard(
                title: data?['title'] ?? "Unnamed job",
                subtitle: timestamp != null
                    ? "Posted on: ${formatter.format(timestamp.toDate())}"
                    : "Posted on: N/A",
                icon: Icons.work,
                color: Colors.purpleAccent,
              );
            },
          ),

          const SizedBox(height: 20),
          const SectionTitle(title: "Notifications", icon: Icons.notifications),
          const SizedBox(height: 8),
          StreamSection(
            query: FirebaseFirestore.instance
                .collection("donationNotifications")
                .where("userId", isEqualTo: user.uid),
            emptyText: "No notifications.",
            itemBuilder: (doc) {
              final data = doc.data();
              final timestamp = data?['timestamp'] as Timestamp?;
              return ActivityCard(
                title: "Notification",
                subtitle:
                    "${data?['message'] ?? ''}\n${timestamp != null ? formatter.format(timestamp.toDate()) : 'N/A'}",
                icon: Icons.notifications,
                color: Colors.teal,
              );
            },
          ),

          const SizedBox(height: 20),
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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text(emptyText);
        }

        final docs = snapshot.data!.docs;

        // Keep only documents with data
        final validDocs = docs.where((d) => d.data().isNotEmpty).toList();

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

// ---------------- Activity Card ----------------
class ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String actionText;
  final VoidCallback? onActionPressed;
  final Function(bool accepted)? onDualAction;

  const ActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.actionText = "",
    this.onActionPressed,
    this.onDualAction,
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
        trailing: onDualAction != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => onDualAction!(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("ACCEPT"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onDualAction!(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("DENY"),
                  ),
                ],
              )
            : (actionText.isNotEmpty
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
                  : null),
      ),
    );
  }
}
