import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoubtDetailScreen extends StatefulWidget {
  final String doubtId;

  const DoubtDetailScreen({super.key, required this.doubtId});

  @override
  State<DoubtDetailScreen> createState() => _DoubtDetailScreenState();
}

class _DoubtDetailScreenState extends State<DoubtDetailScreen> {
  final TextEditingController answerController = TextEditingController();

  // ---------------- POST ANSWER ----------------
  Future<void> _postAnswer() async {
    if (answerController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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
      "timestamp": FieldValue.serverTimestamp(),
    });

    answerController.clear();
  }

  // ---------------- DELETE ANSWER ----------------
  Future<void> _deleteAnswer(String answerId) async {
    await FirebaseFirestore.instance
        .collection("doubts")
        .doc(widget.doubtId)
        .collection("answers")
        .doc(answerId)
        .delete();
  }

  void _confirmDeleteAnswer(String answerId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Answer"),
        content: const Text("Are you sure you want to delete this answer?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAnswer(answerId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(title: const Text("Doubt Details")),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("doubts")
            .doc(widget.doubtId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.data() == null) {
            return const Center(child: Text("Doubt not found"));
          }

          final data = snap.data!.data()!;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------- DOUBT CARD --------
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                              color: Colors.black.withOpacity(0.05),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data["title"] ?? "",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              data["description"] ?? "",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Answers",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // -------- ANSWERS LIST (NEW UI) --------
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection("doubts")
                            .doc(widget.doubtId)
                            .collection("answers")
                            .snapshots(),
                        builder: (context, ansSnap) {
                          if (ansSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final answers = ansSnap.data?.docs ?? [];

                          if (answers.isEmpty) {
                            return const Text(
                              "No answers yet. Be the first to answer!",
                              style: TextStyle(color: Colors.black54),
                            );
                          }

                          return Column(
                            children: answers.map((ansDoc) {
                              final ans = ansDoc.data();
                              final bool isOwner =
                                  ans["answeredByUid"] == currentUid;

                              final String name =
                                  ans["answeredByName"] ?? "User";
                              final String initial =
                                  name.isNotEmpty ? name[0].toUpperCase() : "U";

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                      color:
                                          Colors.black.withOpacity(0.05),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          Colors.indigo.withOpacity(0.15),
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            ans["answer"] ?? "",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Delete (owner only)
                                    if (isOwner)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _confirmDeleteAnswer(ansDoc.id),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // -------- ANSWER INPUT --------
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.black12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: answerController,
                        decoration: InputDecoration(
                          hintText: "Write an answer...",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _postAnswer,
                      child: const Text("Send"),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
