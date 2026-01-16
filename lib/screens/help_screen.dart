import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  bool uploading = false;

  // ---------------- POST DOUBT ----------------
  Future<void> uploadDoubt() async {
    if (titleController.text.isEmpty || descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter title and description")),
      );
      return;
    }

    setState(() => uploading = true);

    final user = FirebaseAuth.instance.currentUser!;

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final username = userDoc.data()?["name"] ?? user.email ?? "Unknown";

    await FirebaseFirestore.instance.collection("doubts").add({
      "title": titleController.text.trim(),
      "description": descController.text.trim(),
      "imageUrl": "", // Image upload disabled
      "askedByUid": user.uid,
      "askedByName": username,
      "upvotes": [],
      "solved": false,
      "timestamp": DateTime.now(),
    });

    titleController.clear();
    descController.clear();

    setState(() => uploading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Doubt posted successfully!")),
    );
  }

  // ---------------- TOGGLE UPVOTE ----------------
  Future<void> toggleUpvote(String doubtId, List<String> upvotes) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (upvotes.contains(uid)) {
      upvotes.remove(uid);
    } else {
      upvotes.add(uid);
    }

    await FirebaseFirestore.instance
        .collection("doubts")
        .doc(doubtId)
        .update({"upvotes": upvotes});
  }

  // ---------------- DELETE DOUBT (OWNER ONLY) ----------------
  Future<void> deleteDoubt(String doubtId) async {
    await FirebaseFirestore.instance.collection("doubts").doc(doubtId).delete();
  }

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
              await deleteDoubt(doubtId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Doubts & Help")),

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
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No doubts yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final isOwner = data["askedByUid"] == currentUid;
              final upvotes = List<String>.from(data["upvotes"] ?? []);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                      color: Colors.black.withOpacity(0.06),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data["title"],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isOwner)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => confirmDelete(d.id),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      data["description"],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Asked by: ${data["askedByName"]}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),

                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            upvotes.contains(currentUid)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              toggleUpvote(d.id, List<String>.from(upvotes)),
                        ),
                        Text("${upvotes.length} upvotes"),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios, size: 16),
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
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Image upload coming soon",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: uploading ? null : uploadDoubt,
            child: uploading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Post"),
          ),
        ],
      ),
    );
  }
}
