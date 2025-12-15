import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnswerScreen extends StatefulWidget {
  final String doubtId;

  const AnswerScreen({super.key, required this.doubtId});

  @override
  State<AnswerScreen> createState() => _AnswerScreenState();
}

class _AnswerScreenState extends State<AnswerScreen> {
  final answerController = TextEditingController();

  // ----------------------- POST ANSWER -----------------------
  Future postAnswer() async {
    if (answerController.text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;

    // Fetch user's name from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final username = userDoc.data()?["name"] ?? user.email ?? "Unknown";

    await FirebaseFirestore.instance
        .collection("doubts")
        .doc(widget.doubtId)
        .collection("answers")
        .add({
          "answer": answerController.text.trim(),
          "answeredByUid": user.uid,
          "answeredByName": username,
          "timestamp": DateTime.now(),
        });

    answerController.clear();
  }

  // ----------------------- UI -----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Answers")),

      body: Column(
        children: [
          // ----------------------- ANSWERS LIST -----------------------
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("doubts")
                  .doc(widget.doubtId)
                  .collection("answers")
                  .orderBy("timestamp")
                  .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No answers yet"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    var ans = docs[i].data();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
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
                          Text(
                            ans["answer"] ?? "",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "By: ${ans['answeredByName'] ?? 'Unknown'}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ----------------------- ANSWER INPUT BOX -----------------------
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: answerController,
                    decoration: const InputDecoration(
                      hintText: "Write an answer...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: postAnswer,
                  child: const Text("Send"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
