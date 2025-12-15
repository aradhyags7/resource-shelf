import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pdf_viewer_screen.dart';
import 'image_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SavedNotesScreen extends StatefulWidget {
  const SavedNotesScreen({super.key});

  @override
  State<SavedNotesScreen> createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends State<SavedNotesScreen> {
  IconData getFileIcon(String type) {
    switch (type) {
      case "pdf":
        return Icons.picture_as_pdf;
      case "image":
        return Icons.image;
      case "doc":
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> toggleVote(String noteId, int voteType) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection('notes').doc(noteId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      List<dynamic> upvoters = List<dynamic>.from(data['upvoters'] ?? []);
      List<dynamic> downvoters = List<dynamic>.from(data['downvoters'] ?? []);
      int upvotes = (data['upvotes'] ?? 0) as int;
      int downvotes = (data['downvotes'] ?? 0) as int;

      bool didUp = upvoters.contains(uid);
      bool didDown = downvoters.contains(uid);

      if (voteType == 1) {
        if (didUp) {
          upvoters.remove(uid);
          upvotes = (upvotes > 0) ? upvotes - 1 : 0;
        } else {
          upvoters.add(uid);
          upvotes = upvotes + 1;
          if (didDown) {
            downvoters.remove(uid);
            downvotes = (downvotes > 0) ? downvotes - 1 : 0;
          }
        }
      } else {
        if (didDown) {
          downvoters.remove(uid);
          downvotes = (downvotes > 0) ? downvotes - 1 : 0;
        } else {
          downvoters.add(uid);
          downvotes = downvotes + 1;
          if (didUp) {
            upvoters.remove(uid);
            upvotes = (upvotes > 0) ? upvotes - 1 : 0;
          }
        }
      }

      tx.update(docRef, {
        'upvotes': upvotes,
        'downvotes': downvotes,
        'upvoters': upvoters,
        'downvoters': downvoters,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(title: const Text("Saved Notes")),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("saved_notes")
            .orderBy("savedAt", descending: true)
            .snapshots(),

        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No saved notes yet.", style: TextStyle(fontSize: 16, color: Colors.black54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final note = docs[i];
              final title = note["title"];
              final subject = note["subject"];
              final fileType = note["type"];
              final url = note["url"];
              final noteId = note.id; // this doc id matches original note id (we saved it that way)

              // To show live votes we read the original note doc as a small stream:
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection("notes").doc(noteId).snapshots(),
                builder: (context, nSnap) {
                  final noteData = nSnap.data;
                  int upvotes = 0;
                  int downvotes = 0;
                  bool didUp = false;
                  bool didDown = false;

                  if (noteData != null && noteData.exists) {
                    upvotes = (noteData["upvotes"] ?? 0) as int;
                    downvotes = (noteData["downvotes"] ?? 0) as int;
                    final upvoters = List<String>.from(noteData["upvoters"] ?? []);
                    final downvoters = List<String>.from(noteData["downvoters"] ?? []);
                    didUp = upvoters.contains(uid);
                    didDown = downvoters.contains(uid);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(blurRadius: 8, offset: const Offset(0,4), color: Colors.black.withOpacity(0.06))],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(getFileIcon(fileType), size: 28, color: Colors.indigo.shade700),
                      ),
                      title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      subtitle: Text(subject, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.thumb_up, color: didUp ? Colors.blue : Colors.grey),
                                onPressed: () => toggleVote(noteId, 1),
                              ),
                              Text("$upvotes", style: const TextStyle(fontSize: 12)),
                              IconButton(
                                icon: Icon(Icons.thumb_down, color: didDown ? Colors.red : Colors.grey),
                                onPressed: () => toggleVote(noteId, -1),
                              ),
                              Text("$downvotes", style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.bookmark_remove, color: Colors.red),
                            onPressed: () {
                              FirebaseFirestore.instance.collection("users").doc(uid).collection("saved_notes").doc(noteId).delete();
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        if (fileType == "pdf") {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PDFViewerScreen(pdfUrl: url)));
                        } else if (fileType == "image") {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewerScreen(imageUrl: url)));
                        } else if (fileType == "doc") {
                          final googleUrl = "https://docs.google.com/viewer?url=$url";
                          launchUrl(Uri.parse(googleUrl), mode: LaunchMode.externalApplication);
                        }
                      },
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
