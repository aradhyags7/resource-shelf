import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewPostScreen extends StatefulWidget {
  final String subject;

  const NewPostScreen({super.key, required this.subject});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  bool loading = false;

  Future submitPost() async {
    if (titleController.text.isEmpty || contentController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    setState(() => loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    final name = userDoc["name"] ?? "Unknown";

    await FirebaseFirestore.instance
        .collection("community")
        .doc(widget.subject)
        .collection("posts")
        .add({
      "title": titleController.text,
      "content": contentController.text,
      "postedBy": name,
      "uid": uid,
      "timestamp": DateTime.now(),
    });

    setState(() => loading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("New ${widget.subject} Post")),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Post Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Write something...",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : submitPost,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Post"),
            )
          ],
        ),
      ),
    );
  }
}
