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

    // fetch username from /users
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

  // ---------------- TOGGLE SOLVED ----------------
  Future<void> _toggleSolved(bool currentValue) async {
    await FirebaseFirestore.instance
        .collection("doubts")
        .doc(widget.doubtId)
        .update({"solved": !currentValue});
  }

  // ---------------- TOGGLE UPVOTE ----------------
  Future<void> _toggleUpvote(List<dynamic> upvotes, String uid) async {
    final List<String> updated = List<String>.from(upvotes);
    if (updated.contains(uid)) {
      updated.remove(uid);
    } else {
      updated.add(uid);
    }

    await FirebaseFirestore.instance
        .collection("doubts")
        .doc(widget.doubtId)
        .update({"upvotes": updated});
  }

  // ---------------- DELETE DOUBT ----------------
  Future<void> _deleteDoubt() async {
    // delete all answers first
    final answersSnap = await FirebaseFirestore.instance
        .collection("doubts")
        .doc(widget.doubtId)
        .collection("answers")
        .get();

    for (var doc in answersSnap.docs) {
      await doc.reference.delete();
    }

    // delete the doubt
    await FirebaseFirestore.instance
        .collection("doubts")
        .doc(widget.doubtId)
        .delete();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _confirmDeleteDoubt() {
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
              Navigator.pop(context);
              await _deleteDoubt();
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUid = currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doubt Details"),
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("doubts")
            .doc(widget.doubtId)
            .snapshots(),
        builder: (context, doubtSnap) {
          if (!doubtSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doubtDoc = doubtSnap.data!;
          final data = doubtDoc.data();

          if (data == null) {
            return const Center(child: Text("Doubt not found"));
          }

          final bool isOwner = data["askedByUid"] == currentUid;
          final List<dynamic> upvotes = data["upvotes"] ?? [];
          final bool isSolved = data["solved"] ?? false;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------- TITLE ROW ----------
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              data["title"] ?? "No title",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isOwner)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _confirmDeleteDoubt,
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ---------- ASKED BY & SOLVED ----------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Asked by: ${data["askedByName"] ?? 'Unknown'}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          Row(
                            children: [
                              if (isSolved)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "Solved",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              if (isOwner) ...[
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () =>
                                      _toggleSolved(isSolved),
                                  child: Text(
                                    isSolved ? "Mark Unsolved" : "Mark Solved",
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ---------- DESCRIPTION ----------
                      Text(
                        data["description"] ?? "",
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 16),

                      // ---------- IMAGE ----------
                      if (data["imageUrl"] != null &&
                          data["imageUrl"].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            data["imageUrl"],
                            fit: BoxFit.cover,
                          ),
                        ),

                      const SizedBox(height: 16),

                      // ---------- UPVOTES ----------
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              upvotes.contains(currentUid)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                            ),
                            onPressed: currentUid == null
                                ? null
                                : () => _toggleUpvote(upvotes, currentUid),
                          ),
                          Text("${upvotes.length} upvotes"),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Divider(),

                      const SizedBox(height: 10),

                      const Text(
                        "Answers",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ---------- ANSWERS LIST ----------
                      StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection("doubts")
                            .doc(widget.doubtId)
                            .collection("answers")
                            .orderBy("timestamp")
                            .snapshots(),
                        builder: (context, ansSnap) {
                          if (!ansSnap.hasData) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Center(
                                  child: CircularProgressIndicator()),
                            );
                          }

                          final answers = ansSnap.data!.docs;

                          if (answers.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                "No answers yet. Be the first to answer!",
                                style: TextStyle(color: Colors.black54),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: answers.length,
                            itemBuilder: (context, index) {
                              final ansDoc = answers[index];
                              final ansData = ansDoc.data();

                              final bool isAnswerOwner =
                                  ansData["answeredByUid"] == currentUid;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                      color: Colors.black
                                          .withOpacity(0.05),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ansData["answer"] ?? "",
                                      style: const TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "By: ${ansData["answeredByName"] ?? 'Unknown'}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        if (isAnswerOwner)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _confirmDeleteAnswer(
                                                    ansDoc.id),
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
                    ],
                  ),
                ),
              ),

              // ---------- ANSWER INPUT ----------
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: const Border(
                    top: BorderSide(color: Colors.black12),
                  ),
                ),
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
