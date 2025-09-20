import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationsScreen extends StatefulWidget {
  const DonationsScreen({super.key});

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
  String selectedBloodGroup = "All";

  void _showAddDonationDialog() {
    final nameController = TextEditingController();
    final bloodGroupController = TextEditingController();
    final locationController = TextEditingController();
    final contactController = TextEditingController();
    final notesController = TextEditingController();
    String urgency = "High";

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Add Donation Request",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E90FF),
                  ),
                ),
                const SizedBox(height: 15),
                _buildTextField(nameController, "Patient Name"),
                const SizedBox(height: 12),
                _buildTextField(
                  bloodGroupController,
                  "Blood Group (A+, O-, etc.)",
                ),
                const SizedBox(height: 12),
                _buildTextField(locationController, "Location / Hospital"),
                const SizedBox(height: 12),
                _buildTextField(contactController, "Contact Number"),
                const SizedBox(height: 12),
                _buildTextField(notesController, "Notes / Details"),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Urgency:",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    DropdownButton<String>(
                      value: urgency,
                      items: ["High", "Medium", "Low"]
                          .map(
                            (level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        urgency = value!;
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E90FF),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        bloodGroupController.text.isNotEmpty &&
                        locationController.text.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection("bloodDonations")
                          .add({
                            "patientName": nameController.text,
                            "bloodGroup": bloodGroupController.text
                                .toUpperCase(),
                            "location": locationController.text,
                            "contact": contactController.text,
                            "urgency": urgency,
                            "notes": notesController.text,
                            "timestamp": FieldValue.serverTimestamp(),
                            "createdBy": user.uid,
                            "confirmedVolunteers": [],
                          });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "Submit",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _volunteerForDonation(
    DocumentSnapshot doc,
    Map<String, dynamic> req,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1️⃣ Record volunteer
    await FirebaseFirestore.instance.collection("volunteers").add({
      "donationId": doc.id,
      "userId": user.uid,
      "username": user.displayName ?? "Anonymous",
      "timestamp": FieldValue.serverTimestamp(),
      "status": "PENDING",
    });

    // 2️⃣ Notify volunteer themselves
    await FirebaseFirestore.instance.collection("donationNotifications").add({
      "userId": user.uid,
      "message": "You volunteered for ${req['patientName']}!",
      "timestamp": FieldValue.serverTimestamp(),
    });

    // 3️⃣ Notify the poster
    await FirebaseFirestore.instance
        .collection('userNotifications')
        .doc(req['createdBy'])
        .collection('notifications')
        .add({
          "message":
              "${user.displayName ?? "Someone"} volunteered for your blood donation request: ${req['patientName']}",
          "timestamp": FieldValue.serverTimestamp(),
          "seen": false,
        });

    // 4️⃣ Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("You volunteered for ${req['patientName']}!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to see donations."));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF87CEFA), Color(0xFFB0E0E6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Urgent Donations",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    DropdownButton<String>(
                      value: selectedBloodGroup,
                      dropdownColor: Colors.white,
                      underline: const SizedBox(),
                      items:
                          [
                                "All",
                                "A+",
                                "A-",
                                "B+",
                                "B-",
                                "O+",
                                "O-",
                                "AB+",
                                "AB-",
                              ]
                              .map(
                                (group) => DropdownMenuItem(
                                  value: group,
                                  child: Text(group),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedBloodGroup = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("bloodDonations")
                      .orderBy("timestamp", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var donations = snapshot.data!.docs;
                    if (selectedBloodGroup != "All") {
                      donations = donations.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return data['bloodGroup'] == selectedBloodGroup;
                      }).toList();
                    }

                    if (donations.isEmpty) {
                      return const Center(
                        child: Text("No donation requests found"),
                      );
                    }

                    donations.sort((a, b) {
                      const urgencyOrder = {"High": 0, "Medium": 1, "Low": 2};
                      final da = a.data() as Map<String, dynamic>;
                      final db = b.data() as Map<String, dynamic>;
                      return urgencyOrder[da['urgency']]!.compareTo(
                        urgencyOrder[db['urgency']]!,
                      );
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: donations.length,
                      itemBuilder: (context, index) {
                        final doc = donations[index];
                        final req = doc.data() as Map<String, dynamic>;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: const Color(0xFF87CEFA),
                                    child: Text(
                                      req['bloodGroup'],
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "${req['patientName']} • ${req['location']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Urgency: ${req['urgency']}",
                                style: TextStyle(
                                  color: req['urgency'] == "High"
                                      ? Colors.red.shade700
                                      : (req['urgency'] == "Medium"
                                            ? Colors.orange.shade700
                                            : Colors.green.shade700),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (req['notes'] != null &&
                                  req['notes'].isNotEmpty)
                                Text(
                                  req['notes'],
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "📞 ${req['contact']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                    ),
                                    onPressed: () =>
                                        _volunteerForDonation(doc, req),
                                    child: const Text(
                                      "Donate",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDonationDialog,
        backgroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Color(0xFF1E90FF)),
        label: const Text(
          "New Request",
          style: TextStyle(color: Color(0xFF1E90FF)),
        ),
      ),
    );
  }
}
