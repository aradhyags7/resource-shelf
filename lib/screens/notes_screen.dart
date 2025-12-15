import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pdf_viewer_screen.dart';
import 'image_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    final snap = await FirebaseFirestore.instance
        .collection("subjects")
        .orderBy("name")
        .get();

    final fetched = snap.docs.map((d) => d["name"].toString()).toList();

    setState(() {
      subjects = ["All", ...fetched];
      if (!subjects.contains(selectedSubject)) {
        selectedSubject = "All";
      }
    });
  }

  List<String> subjects = ["All"];

  String selectedSubject = "All";
  String searchText = "";

  Stream<QuerySnapshot> getNotesStream() {
    Query q = FirebaseFirestore.instance.collection("notes");

    if (selectedSubject != "All") {
      q = q.where("subject", isEqualTo: selectedSubject);
    }

    // keep timestamp ordering; popularity sorting can be added as a filter
    return q.orderBy("timestamp", descending: true).snapshots();
  }

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

  // ---------------- Voting logic (Up / Down) ----------------
  Future<void> toggleVote(String noteId, int voteType) async {
    // voteType: 1 => upvote, -1 => downvote
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
          // remove upvote
          upvoters.remove(uid);
          upvotes = (upvotes > 0) ? upvotes - 1 : 0;
        } else {
          // add upvote, and if previously downvoted remove downvote
          upvoters.add(uid);
          upvotes = upvotes + 1;
          if (didDown) {
            downvoters.remove(uid);
            downvotes = (downvotes > 0) ? downvotes - 1 : 0;
          }
        }
      } else if (voteType == -1) {
        if (didDown) {
          // remove downvote
          downvoters.remove(uid);
          downvotes = (downvotes > 0) ? downvotes - 1 : 0;
        } else {
          // add downvote, and if previously upvoted remove upvote
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

  // ---------------- Save / Unsave (your existing function) ----------------
  Future toggleSave(DocumentSnapshot note) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("saved_notes")
        .doc(note.id);

    final exists = await ref.get();

    if (exists.exists) {
      await ref.delete();
    } else {
      await ref.set({
        "title": note["title"],
        "subject": note["subject"],
        "type": note["type"],
        "url": note["url"],
        "savedAt": DateTime.now(),
      });
    }
  }

  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(title: const Text("Notes"), elevation: 0),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject chips
          SizedBox(
            height: 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: subjects.length,
              itemBuilder: (context, i) {
                final s = subjects[i];
                final isSelected = selectedSubject == s;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: isSelected,
                    selectedColor: Colors.indigo.shade600,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() => selectedSubject = s);
                    },
                  ),
                );
              },
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search notes...",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                setState(() => searchText = v.toLowerCase());
              },
            ),
          ),

          // Notes List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getNotesStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No notes found. Be the first one to upload 🚀",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                final docs = snap.data!.docs;

                // local search
                final filtered = docs.where((doc) {
                  final title = doc["title"].toString().toLowerCase();
                  return title.contains(searchText);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      "No notes found",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final note = filtered[i];
                    final title = note["title"];
                    final subject = note["subject"];
                    final type = note["type"];
                    final url = note["url"];
                    final uploader = note["uploadedBy"] ?? "Unknown";
                    final timestamp = note["timestamp"] != null
                        ? (note["timestamp"] as Timestamp).toDate()
                        : null;

                    // votes data
                    final upvotes = (note["upvotes"] ?? 0) as int;
                    final downvotes = (note["downvotes"] ?? 0) as int;
                    final upvoters = List<String>.from(note["upvoters"] ?? []);
                    final downvoters = List<String>.from(
                      note["downvoters"] ?? [],
                    );
                    final didUp = upvoters.contains(uid);
                    final didDown = downvoters.contains(uid);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            getFileIcon(type),
                            size: 28,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            if (timestamp != null)
                              Text(
                                "Uploaded on: ${timestamp.day}/${timestamp.month}/${timestamp.year}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black38,
                                ),
                              ),
                            Text(
                              "Uploaded by: $uploader",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Save button (existing)
                            StreamBuilder(
                              stream: FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(uid)
                                  .collection("saved_notes")
                                  .doc(note.id)
                                  .snapshots(),
                              builder: (context, snap2) {
                                bool isSaved = snap2.data?.exists ?? false;
                                return IconButton(
                                  icon: Icon(
                                    isSaved
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: isSaved ? Colors.amber : Colors.grey,
                                  ),
                                  onPressed: () => toggleSave(note),
                                );
                              },
                            ),

                            // Votes column
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.thumb_up,
                                    color: didUp ? Colors.blue : Colors.grey,
                                  ),
                                  onPressed: () => toggleVote(note.id, 1),
                                ),
                                Text(
                                  "$upvotes",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                IconButton(
                                  icon: Icon(
                                    Icons.thumb_down,
                                    color: didDown ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () => toggleVote(note.id, -1),
                                ),
                                Text(
                                  "$downvotes",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_ios, size: 18),
                          ],
                        ),

                        onTap: () {
                          if (type == "pdf") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PDFViewerScreen(pdfUrl: url),
                              ),
                            );
                          } else if (type == "image") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ImageViewerScreen(imageUrl: url),
                              ),
                            );
                          } else if (type == "doc") {
                            final googleUrl =
                                "https://docs.google.com/viewer?url=$url";
                            launchUrl(
                              Uri.parse(googleUrl),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
