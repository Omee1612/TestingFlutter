import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OddJobScreen extends StatefulWidget {
  const OddJobScreen({super.key});

  @override
  State<OddJobScreen> createState() => _OddJobScreenState();
}

class _OddJobScreenState extends State<OddJobScreen> {
  List<Map<String, dynamic>> oddJobs = [];

  @override
  void initState() {
    super.initState();
    _loadOddJobs();
  }

  Future<void> _loadOddJobs() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('oddjobs')
        .orderBy('createdAt', descending: true)
        .get();
    setState(() {
      oddJobs = snapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data()})
          .toList();
    });
  }

  void _addOddJob() {
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _payController = TextEditingController();

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
                "Add New Odd Job",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: _payController,
                decoration: const InputDecoration(labelText: "Pay (in \BDT)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF601EF9),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_titleController.text.isEmpty ||
                      _descriptionController.text.isEmpty ||
                      _payController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  final user = FirebaseAuth.instance.currentUser;
                  final username = user?.displayName ?? "Anonymous";

                  final newJob = {
                    "title": _titleController.text,
                    "description": _descriptionController.text,
                    "pay": double.tryParse(_payController.text) ?? 0,
                    "userId": user?.uid ?? "",
                    "username": username,
                    "createdAt": FieldValue.serverTimestamp(),
                  };

                  final doc = await FirebaseFirestore.instance
                      .collection('oddjobs')
                      .add(newJob);

                  setState(() {
                    oddJobs.insert(0, {"id": doc.id, ...newJob});
                  });

                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text("Add Odd Job"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _takeJob(Map<String, dynamic> job) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You accepted the job: ${job['title']}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Odd Jobs"),
        centerTitle: true,
        backgroundColor: const Color(0xFF601EF9),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: oddJobs.isEmpty
            ? const Center(
                child: Text(
                  "No odd jobs yet. Tap '+' to add one!",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: oddJobs.length,
                itemBuilder: (context, index) {
                  final job = oddJobs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _takeJob(job),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF601EF9).withOpacity(0.9),
                              const Color(0xFF8B3CFF).withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job['title'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              job['description'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.money,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${job['pay']} BDT",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      job['username'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _takeJob(job),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF601EF9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("Take Job"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addOddJob,
        label: const Text("Post Job"),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF601EF9),
      ),
    );
  }
}
