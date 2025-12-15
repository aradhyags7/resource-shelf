import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'answer_screen.dart';

class DoubtScreen extends StatefulWidget {
  const DoubtScreen({super.key});

  @override
  State<DoubtScreen> createState() => _DoubtScreenState();
}

class _DoubtScreenState extends State<DoubtScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  // ----------------------- POST DOUBT -----------------------
  Future postDoubt() async {
    if (titleController.text.isEmpty || descController.text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    
    // fetch user name from /users collection
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
      "timestamp": DateTime.now(),
      "answer": "",
      "answeredByUid": "",
      "answeredByName": "",
    });

    titleController.clear();
    descController.clear();
    Navigator.pop(context);
  }

  // ----------------------- ASK DOUBT POPUP -----------------------
  void openAskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ask a Doubt"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
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
        );
      },
    );
  }

  // ----------------------- DELETE DOUBT -----------------------
  void confirmDelete(String doubtId) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Doubt"),
          content: const Text("Are you sure you want to delete this doubt?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("doubts")
                    .doc(doubtId)
                    .delete();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // ----------------------- UI -----------------------
  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Doubts & Answers")),

      floatingActionButton: FloatingActionButton(
        onPressed: openAskDialog,
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("doubts")
            .orderBy("timestamp", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No doubts asked yet"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var doubt = docs[i];
              var data = doubt.data(); // no unnecessary cast

              final bool isOwner = data["askedByUid"] == currentUid;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    // Title
                    Text(
                      data["title"] ?? "No Title",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Description
                    Text(
                      data["description"] ?? "",
                      style: const TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 10),

                    // Asked By
                    Text(
                      "Asked by: ${data['askedByName'] ?? 'Unknown'}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // View/Answer Button
                        TextButton(
                          child: const Text("View / Answer"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AnswerScreen(doubtId: doubt.id),
                              ),
                            );
                          },
                        ),

                        // Delete (only owner)
                        if (isOwner)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => confirmDelete(doubt.id),
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
