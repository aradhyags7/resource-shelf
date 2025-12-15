import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'image_viewer_screen.dart';
import 'pdf_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MyUploadsScreen extends StatefulWidget {
  const MyUploadsScreen({super.key});

  @override
  State<MyUploadsScreen> createState() => _MyUploadsScreenState();
}

class _MyUploadsScreenState extends State<MyUploadsScreen> {
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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("My Uploads")),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notes")
            .where("uploadedByUid", isEqualTo: user!.uid)
            .orderBy("timestamp", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No uploads yet.", style: TextStyle(fontSize: 18, color: Colors.grey)));
          }

          final notes = snapshot.data!.docs;
          final uid = user.uid;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final fileType = note["type"];
              final url = note["url"];
              final title = note["title"];
              final subject = note["subject"];

              final upvotes = (note["upvotes"] ?? 0) as int;
              final downvotes = (note["downvotes"] ?? 0) as int;
              final upvoters = List<String>.from(note["upvoters"] ?? []);
              final downvoters = List<String>.from(note["downvoters"] ?? []);
              final didUp = upvoters.contains(uid);
              final didDown = downvoters.contains(uid);

              IconData icon = Icons.description;
              if (fileType == "pdf") icon = Icons.picture_as_pdf;
              else if (fileType == "image") icon = Icons.image;

              return Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(icon, size: 30),
                  title: Text(title),
                  subtitle: Text("Subject: $subject"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.thumb_up, color: didUp ? Colors.blue : Colors.grey),
                            onPressed: () => toggleVote(note.id, 1),
                          ),
                          Text("$upvotes", style: const TextStyle(fontSize: 12)),
                          IconButton(
                            icon: Icon(Icons.thumb_down, color: didDown ? Colors.red : Colors.grey),
                            onPressed: () => toggleVote(note.id, -1),
                          ),
                          Text("$downvotes", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () {
                    if (fileType == "pdf") {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PDFViewerScreen(pdfUrl: url)));
                    } else if (fileType == "image") {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewerScreen(imageUrl: url)));
                    } else {
                      final gviewUrl = "https://docs.google.com/viewer?url=$url";
                      launchUrl(Uri.parse(gviewUrl), mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
