import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuickBorrowScreen extends StatefulWidget {
  const QuickBorrowScreen({super.key});

  @override
  State<QuickBorrowScreen> createState() => _QuickBorrowScreenState();
}

class _QuickBorrowScreenState extends State<QuickBorrowScreen> {
  final CollectionReference itemsRef = FirebaseFirestore.instance.collection(
    'quick_borrow_items',
  );

  final CollectionReference requestsRef = FirebaseFirestore.instance.collection(
    'quickBorrowRequests',
  );

  void _addNewItem() {
    final _titleController = TextEditingController();
    final _imageController = TextEditingController();
    final _durationController = TextEditingController();

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to add items")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add New Item",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Item Name"),
              ),
              TextField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: "Image URL (optional)",
                ),
              ),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: "Duration"),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_titleController.text.isEmpty ||
                      _durationController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  await itemsRef.add({
                    'title': _titleController.text,
                    'image': _imageController.text.isEmpty
                        ? 'https://via.placeholder.com/150'
                        : _imageController.text,
                    'duration': _durationController.text,
                    'description': 'User added item',
                    'ownerId': user.uid,
                    'ownerName': user.displayName ?? "Anonymous",
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text("Add Item"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDetails(Map<String, dynamic> item, String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuickBorrowDetailScreen(item: item, docId: docId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Quick Borrow",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: itemsRef.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No items available."));
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index].data() as Map<String, dynamic>;
              final docId = items[index].id;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openDetails(item, docId),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: Image.network(
                          item["image"],
                          height: 90,
                          width: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["title"],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Available for: ${item["duration"]}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Owner: ${item['ownerName']}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewItem,
        label: const Text("Add Item"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

/// ------------------ DETAILS SCREEN ------------------

class QuickBorrowDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final String docId;
  const QuickBorrowDetailScreen({
    super.key,
    required this.item,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(item["title"])),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.network(item["image"], height: 250, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["title"],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Available for: ${item["duration"]}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(item["description"] ?? "No description available."),
                const SizedBox(height: 16),
                Text(
                  "Owner: ${item['ownerName']}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (user != null && user.uid != item['ownerId'])
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Create borrow request
                  await FirebaseFirestore.instance
                      .collection('quickBorrowRequests')
                      .add({
                        'itemId': docId,
                        'itemName': item['title'],
                        'itemOwnerId': item['ownerId'],
                        'ownerName': item['ownerName'],
                        'requesterId': user.uid,
                        'requesterName': user.displayName ?? "Anonymous",
                        'status': "PENDING",
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Request sent for ${item['title']}!"),
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text("BORROW"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
