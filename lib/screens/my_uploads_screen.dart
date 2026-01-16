import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class MyUploadsScreen extends StatefulWidget {
  const MyUploadsScreen({super.key});

  @override
  State<MyUploadsScreen> createState() => _MyUploadsScreenState();
}

class _MyUploadsScreenState extends State<MyUploadsScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // ---------------- OPEN DRIVE ----------------
  Future<void> openDrive(String url) async {
    if (url.isEmpty) return;
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  // ---------------- DELETE NOTE EVERYWHERE ----------------
  Future<void> deleteNoteEverywhere(String noteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete note"),
        content: const Text(
          "This will permanently delete the note for everyone.\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final firestore = FirebaseFirestore.instance;

    // 1️⃣ Delete from main notes collection
    await firestore.collection("notes").doc(noteId).delete();

    // 2️⃣ Remove from ALL users' saved_notes
    final usersSnap = await firestore.collection("users").get();

    for (final user in usersSnap.docs) {
      await firestore
          .collection("users")
          .doc(user.id)
          .collection("saved_notes")
          .doc(noteId)
          .delete()
          .catchError((_) {});
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Note deleted everywhere")),
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
      appBar: AppBar(title: const Text("My Uploads")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
    .collection("notes")
    .where("uploadedByUid", isEqualTo: uid)
    .snapshots(),

        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "You haven’t uploaded anything yet.",
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          final notes = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            itemBuilder: (_, i) {
              final note = notes[i];
              final data = note.data() as Map<String, dynamic>;

              final driveUrl =
                  data["driveViewUrl"] ?? data["driveUrl"] ?? "";

              final upvotes = data["upvotes"] ?? 0;
              final downvotes = data["downvotes"] ?? 0;

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
                      // -------- SAME DUMMY THUMBNAIL --------
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.asset(
                          "assets/images/pdf_dummy.png",
                          height: 70,
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
                                    data["title"] ?? "Untitled",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      deleteNoteEverywhere(note.id),
                                ),
                              ],
                            ),

                            Text(
                              data["subjectName"] ??
                                  data["subject"] ??
                                  "Unknown",
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
                                      toggleVote(note.id, true),
                                ),
                                Text("$upvotes"),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.thumb_down),
                                  onPressed: () =>
                                      toggleVote(note.id, false),
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
      ),
    );
  }
}
