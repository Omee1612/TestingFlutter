import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  // ---------------- Universal Points Helper ----------------
  Future<void> _addPointsToUser(String userId, int points) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        transaction.set(userRef, {'points': points});
      } else {
        final currentPoints = snapshot.data()?['points'] ?? 0;
        transaction.update(userRef, {'points': currentPoints + points});
      }
    });
  }

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
            icon: Icons.shopping_cart,
          ),
          const SizedBox(height: 8),
          StreamSection(
            query: FirebaseFirestore.instance
                .collection("quickBorrowRequests")
                .where("itemOwnerId", isEqualTo: user.uid),
            emptyText: "No incoming borrow requests.",
            itemBuilder: (doc) {
              final data = doc.data();
              final status = data?['status'] ?? 'PENDING';
              final isHandled = status == 'ACCEPTED' || status == 'DENIED';

              return ActivityCard(
                title: data?['itemName'] ?? "Unnamed item",
                subtitle:
                    "Requested by: ${data?['requesterName'] ?? 'Unknown'}\nStatus: $status",
                icon: Icons.shopping_cart,
                color: Colors.orangeAccent,
                onDualAction: isHandled
                    ? null
                    : (accepted) async {
                        final requesterId = data?['requesterId'];
                        if (accepted) {
                          // Add borrowed item
                          await FirebaseFirestore.instance
                              .collection("borrowedItems")
                              .add({
                                "itemName": data?['itemName'] ?? '',
                                "userId": requesterId ?? '',
                                "ownerId": user.uid,
                                "timestamp": FieldValue.serverTimestamp(),
                              });

                          // Points
                          await _addPointsToUser(user.uid, 5); // Poster
                          if (requesterId != null) {
                            await _addPointsToUser(
                              requesterId,
                              15,
                            ); // Requester
                          }
                        }

                        // Update request status
                        await FirebaseFirestore.instance
                            .collection("quickBorrowRequests")
                            .doc(doc.id)
                            .update({
                              "status": accepted ? "ACCEPTED" : "DENIED",
                            });

                        // Notify requester
                        if (requesterId != null) {
                          await FirebaseFirestore.instance
                              .collection('userNotifications')
                              .doc(requesterId)
                              .collection('notifications')
                              .add({
                                "message": accepted
                                    ? "Your borrow request for ${data?['itemName'] ?? 'an item'} was ACCEPTED"
                                    : "Your borrow request was DENIED",
                                "timestamp": FieldValue.serverTimestamp(),
                                "seen": false,
                              });
                        }
                      },
              );
            },
          ),

          const SizedBox(height: 20),

          // ---------------- Borrowed Items ----------------
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

          // ---------------- Jobs Posted ----------------
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
              final status = data?['status'] ?? 'PENDING';
              final isHandled = status == 'ACCEPTED' || status == 'DENIED';
              final takerId = data?['takerId'];

              return ActivityCard(
                title: data?['title'] ?? "Unnamed job",
                subtitle: timestamp != null
                    ? "Posted on: ${formatter.format(timestamp.toDate())}\nStatus: $status"
                    : "Posted on: N/A\nStatus: $status",
                icon: Icons.work,
                color: Colors.purpleAccent,
                onDualAction: isHandled || takerId == null
                    ? null
                    : (accepted) async {
                        // Update status
                        await FirebaseFirestore.instance
                            .collection("oddjobs")
                            .doc(doc.id)
                            .update({
                              "status": accepted ? "ACCEPTED" : "DENIED",
                            });

                        // Points
                        if (accepted) {
                          await _addPointsToUser(user.uid, 5); // Poster
                          if (takerId != null)
                            await _addPointsToUser(takerId, 15);
                        }

                        // Notify taker
                        if (takerId != null) {
                          final posterName = user.displayName ?? "Poster";
                          await FirebaseFirestore.instance
                              .collection("userNotifications")
                              .doc(takerId)
                              .collection("notifications")
                              .add({
                                "message": accepted
                                    ? "$posterName accepted your job application"
                                    : "$posterName denied your job application",
                                "timestamp": FieldValue.serverTimestamp(),
                                "seen": false,
                              });
                        }
                      },
              );
            },
          ),

          const SizedBox(height: 20),

          // ---------------- Jobs Taken ----------------
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

          // ---------------- Blood Donations ----------------
          const SectionTitle(title: "Blood Donations", icon: Icons.bloodtype),
          const SizedBox(height: 8),
          StreamSection(
            query: FirebaseFirestore.instance
                .collection("bloodDonations")
                .where("createdBy", isEqualTo: user.uid),
            emptyText: "No blood donations.",
            itemBuilder: (donDoc) {
              final donation = donDoc.data();

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection("volunteers")
                    .where("donationId", isEqualTo: donDoc.id)
                    .snapshots(),
                builder: (context, volSnapshot) {
                  if (!volSnapshot.hasData || volSnapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final volunteers = volSnapshot.data!.docs;
                  return Column(
                    children: volunteers.map((volDoc) {
                      final vol = volDoc.data();
                      final volUserId = vol['userId'] as String?;
                      final volTimestamp = vol['timestamp'] as Timestamp?;
                      final status = vol['status'] ?? 'PENDING';
                      final isHandled =
                          status == 'ACCEPTED' || status == 'DENIED';
                      final volName =
                          vol['username'] ?? vol['displayName'] ?? "Volunteer";

                      return ActivityCard(
                        title: "Volunteer",
                        subtitle:
                            "Volunteer: $volName\nStatus: $status\nVolunteered on: ${volTimestamp != null ? formatter.format(volTimestamp.toDate()) : 'N/A'}",
                        icon: Icons.bloodtype,
                        color: Colors.redAccent,
                        onDualAction: isHandled
                            ? null
                            : (accepted) async {
                                await FirebaseFirestore.instance
                                    .collection("volunteers")
                                    .doc(volDoc.id)
                                    .update({
                                      "status": accepted
                                          ? "ACCEPTED"
                                          : "DENIED",
                                    });

                                if (accepted) {
                                  await _addPointsToUser(user.uid, 5);
                                  if (volUserId != null)
                                    await _addPointsToUser(volUserId, 15);
                                }

                                if (volUserId != null) {
                                  final posterName =
                                      user.displayName ?? "Poster";
                                  await FirebaseFirestore.instance
                                      .collection("userNotifications")
                                      .doc(volUserId)
                                      .collection("notifications")
                                      .add({
                                        "message": accepted
                                            ? "$posterName accepted your volunteer offer"
                                            : "$posterName denied your volunteer offer",
                                        "timestamp":
                                            FieldValue.serverTimestamp(),
                                        "seen": false,
                                      });
                                }

                                if (accepted && volUserId != null) {
                                  await FirebaseFirestore.instance
                                      .collection("bloodDonations")
                                      .doc(donDoc.id)
                                      .update({
                                        "confirmedVolunteers":
                                            FieldValue.arrayUnion([volUserId]),
                                      });
                                }
                              },
                      );
                    }).toList(),
                  );
                },
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
