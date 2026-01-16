import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doubt_detail_screen.dart';

class DoubtScreen extends StatefulWidget {
  const DoubtScreen({super.key});

  @override
  State<DoubtScreen> createState() => _DoubtScreenState();
}

class _DoubtScreenState extends State<DoubtScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  // ---------------- POST DOUBT ----------------
  Future<void> postDoubt() async {
    if (titleController.text.trim().isEmpty ||
        descController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final username = userDoc.data()?["name"] ?? user.email ?? "Unknown";

    await FirebaseFirestore.instance.collection("doubts").add({
      "title": titleController.text.trim(),
      "description": descController.text.trim(),
      "askedByUid": user.uid,
      "askedByName": username,
      "timestamp": FieldValue.serverTimestamp(),
      "solved": false,
      "upvotes": [],
    });

    titleController.clear();
    descController.clear();
    Navigator.pop(context);
  }

  // ---------------- ASK DOUBT DIALOG ----------------
  void openAskDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ask a Doubt"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: postDoubt,
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }

  // ---------------- DELETE DOUBT ----------------
  void confirmDelete(String doubtId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Doubt"),
        content: const Text("Are you sure you want to delete this doubt?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("doubts")
                  .doc(doubtId)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(title: const Text("Doubts & Answers")),
      floatingActionButton: FloatingActionButton(
        onPressed: openAskDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("doubts")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return const Center(
              child: Text("Failed to load doubts"),
            );
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No doubts asked yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doubt = docs[i];
              final data = doubt.data() as Map<String, dynamic>;
              final bool isOwner = data["askedByUid"] == currentUid;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                      color: Colors.black.withOpacity(0.05),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data["title"] ?? "",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data["description"] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          child: const Text("View / Answer"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoubtDetailScreen(
                                  doubtId: doubt.id,
                                ),
                              ),
                            );
                          },
                        ),
                        if (isOwner)
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () =>
                                confirmDelete(doubt.id),
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
    );
  }
}
