import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'subject_chat_screen.dart';

class SubjectCommunityPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const SubjectCommunityPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubjectCommunityPage> createState() => _SubjectCommunityPageState();
}

class _SubjectCommunityPageState extends State<SubjectCommunityPage> {
  bool loading = true;

  @override
  void initState() {
    super.initState();
    checkMembership();
  }

  Future<void> checkMembership() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("subjects")
        .doc(widget.subjectId)
        .get();

    final members = doc.data()?["members"] == null
        ? <String>[]
        : List<String>.from(doc["members"]);

    if (members.contains(uid)) {
      /// ✔ FIXED: Always open SubjectChatScreen only
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectChatScreen(
              subjectId: widget.subjectId,
              subjectName: widget.subjectName,
            ),
          ),
        );
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> joinCommunity() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("subjects")
        .doc(widget.subjectId)
        .update({
      "members": FieldValue.arrayUnion([uid])
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectChatScreen(
          subjectId: widget.subjectId,
          subjectName: widget.subjectName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.subjectName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("${widget.subjectName} Community")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups, size: 60, color: Colors.indigo),
            const SizedBox(height: 20),
            Text(
              "Join the ${widget.subjectName} Community!",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text("Share notes, ask questions, help others.",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: joinCommunity,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Join Community"),
            ),
          ],
        ),
      ),
    );
  }
}
