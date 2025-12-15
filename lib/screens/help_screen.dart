import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doubt_detail_screen.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  File? imageFile;
  String imageName = "";
  bool uploading = false;

  Future pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      setState(() {
        imageFile = File(result.files.single.path!);
        imageName = result.files.single.name;
      });
    }
  }

  Future uploadDoubt() async {
    if (titleController.text.isEmpty || descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter title and description")),
      );
      return;
    }

    setState(() => uploading = true);

    final user = FirebaseAuth.instance.currentUser!;

    // Fetch username from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final username = userDoc.data()?["name"] ?? user.email ?? "Unknown";

    // Upload image
    String imageUrl = "";
    if (imageFile != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child("doubt_images")
          .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

      await ref.putFile(imageFile!);
      imageUrl = await ref.getDownloadURL();
    }

    // Upload doubt data
    await FirebaseFirestore.instance.collection("doubts").add({
      "title": titleController.text.trim(),
      "description": descController.text.trim(),
      "imageUrl": imageUrl,
      "askedByUid": user.uid,
      "askedByName": username,
      "upvotes": [],
      "solved": false,
      "timestamp": DateTime.now(),
    });

    titleController.clear();
    descController.clear();
    imageFile = null;
    imageName = "";

    setState(() => uploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Doubt posted successfully!")),
    );
  }

  /// Toggle upvote
  Future toggleUpvote(String doubtId, List upvotes, String uid) async {
    if (upvotes.contains(uid)) {
      upvotes.remove(uid);
    } else {
      upvotes.add(uid);
    }

    await FirebaseFirestore.instance.collection("doubts")
        .doc(doubtId)
        .update({"upvotes": upvotes});
  }

  /// Delete doubt (owner only)
  Future deleteDoubt(String doubtId) async {
    await FirebaseFirestore.instance.collection("doubts").doc(doubtId).delete();
  }

  void confirmDelete(String doubtId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Doubt"),
        content: const Text("Are you sure you want to delete this doubt?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await deleteDoubt(doubtId);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Doubts & Help")),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => openAskDialog(),
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

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No doubts yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final isOwner = data["askedByUid"] == currentUid;
              final upvotes = List<String>.from(data["upvotes"] ?? []);

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoubtDetailScreen(doubtId: d.id),
                  ),
                ),
                child: Container(
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
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                            onPressed: () => toggleUpvote(d.id, upvotes, currentUid),
                          ),
                          Text("${upvotes.length} upvotes"),
                        ],
                      ),

                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

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
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text("Attach image"),
              onPressed: pickImage,
            ),

            if (imageName.isNotEmpty) Text("Selected: $imageName"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: uploadDoubt, child: const Text("Post")),
        ],
      ),
    );
  }
}
