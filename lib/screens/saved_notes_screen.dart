import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SavedNotesScreen extends StatefulWidget {
  const SavedNotesScreen({super.key});

  @override
  State<SavedNotesScreen> createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends State<SavedNotesScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // ---------------- OPEN DRIVE ----------------
  Future<void> openDrive(String url) async {
    if (url.isEmpty) return;
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  // ---------------- REMOVE SAVED ----------------
  Future<void> removeSaved(String noteId) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("saved_notes")
        .doc(noteId)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Removed from saved notes")),
    );
  }

  // ---------------- TOGGLE VOTE ----------------
  Future<void> toggleVote(String noteId, bool isUpvote) async {
    final ref =
        FirebaseFirestore.instance.collection("notes").doc(noteId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;

      final upvoters = List<String>.from(data["upvoters"] ?? []);
      final downvoters = List<String>.from(data["downvoters"] ?? []);

      int upvotes = data["upvotes"] ?? 0;
      int downvotes = data["downvotes"] ?? 0;

      if (isUpvote) {
        if (upvoters.remove(uid)) {
          upvotes--;
        } else {
          upvoters.add(uid);
          upvotes++;
          downvoters.remove(uid);
        }
      } else {
        if (downvoters.remove(uid)) {
          downvotes--;
        } else {
          downvoters.add(uid);
          downvotes++;
          upvoters.remove(uid);
        }
      }

      tx.update(ref, {
        "upvotes": upvotes < 0 ? 0 : upvotes,
        "downvotes": downvotes < 0 ? 0 : downvotes,
        "upvoters": upvoters,
        "downvoters": downvoters,
      });
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(title: const Text("Saved Notes")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("saved_notes")
            .orderBy("savedAt", descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No saved notes yet.",
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          final savedDocs = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: savedDocs.length,
            itemBuilder: (_, i) {
              final noteId = savedDocs[i].id;

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("notes")
                    .doc(noteId)
                    .snapshots(),
                builder: (context, noteSnap) {
                  if (!noteSnap.hasData || !noteSnap.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final note =
                      noteSnap.data!.data() as Map<String, dynamic>;

                  final title = note["title"] ?? "Untitled";
                  final subject =
                      note["subjectName"] ?? note["subject"] ?? "Unknown";
                  final driveUrl =
                      note["driveViewUrl"] ?? note["driveUrl"] ?? "";

                  final upvotes = note["upvotes"] ?? 0;
                  final downvotes = note["downvotes"] ?? 0;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => openDrive(driveUrl),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // -------- SMALLER DUMMY THUMBNAIL --------
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.asset(
                              "assets/images/pdf_dummy.png",
                              height: 70, // 🔑 reduced height
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.bookmark_remove,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          removeSaved(noteId),
                                    ),
                                  ],
                                ),

                                Text(
                                  subject,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.thumb_up),
                                      onPressed: () =>
                                          toggleVote(noteId, true),
                                    ),
                                    Text("$upvotes"),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon:
                                          const Icon(Icons.thumb_down),
                                      onPressed: () =>
                                          toggleVote(noteId, false),
                                    ),
                                    Text("$downvotes"),
                                    const Spacer(),
                                    const Icon(
                                      Icons.open_in_new,
                                      size: 18,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
