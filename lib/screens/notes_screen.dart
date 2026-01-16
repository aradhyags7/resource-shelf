import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'saved_notes_screen.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String searchText = "";
  String selectedSubjectId = "all";

  List<Map<String, String>> subjects = [
    {"id": "all", "name": "All"}
  ];

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  // ---------------- FETCH SUBJECTS ----------------
  Future<void> _fetchSubjects() async {
    final snap = await FirebaseFirestore.instance
        .collection("subjects")
        .orderBy("name")
        .get();

    if (!mounted) return;

    setState(() {
      subjects = [
        {"id": "all", "name": "All"},
        ...snap.docs.map(
          (d) => {"id": d.id, "name": d["name"].toString()},
        ),
      ];
    });
  }

  // ---------------- FETCH ALL NOTES (SAFE) ----------------
  Stream<QuerySnapshot> _notesStream() {
    return FirebaseFirestore.instance
        .collection("notes")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // ---------------- OPEN DRIVE ----------------
  Future<void> openDrive(String url) async {
    if (url.isEmpty) return;
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
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

  // ---------------- TOGGLE SAVE ----------------
  Future<void> toggleSave(DocumentSnapshot note, bool isSaved) async {
    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("saved_notes")
        .doc(note.id);

    if (isSaved) {
      await ref.delete();
    } else {
      final data = note.data() as Map<String, dynamic>;
      await ref.set({
        "title": data["title"],
        "subjectName":
            data["subjectName"] ?? data["subject"] ?? "Unknown",
        "driveUrl":
            data["driveViewUrl"] ?? data["driveUrl"] ?? "",
        "savedAt": FieldValue.serverTimestamp(),
      });
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notes")),
      body: Column(
        children: [
          // -------- SUBJECT FILTER --------
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: subjects.length,
              itemBuilder: (_, i) {
                final s = subjects[i];
                final selected = s["id"] == selectedSubjectId;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(s["name"]!),
                    selected: selected,
                    selectedColor: Colors.indigo,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedSubjectId = s["id"]!;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // -------- SEARCH --------
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search notes",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) =>
                  setState(() => searchText = v.toLowerCase()),
            ),
          ),

          // -------- NOTES GRID --------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _notesStream(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final title =
                      (data["title"] ?? "").toString().toLowerCase();

                  final subjectName =
                      (data["subjectName"] ?? data["subject"] ?? "")
                          .toString()
                          .toLowerCase();

                  final matchesSearch =
                      title.contains(searchText) ||
                      subjectName.contains(searchText);

                  final matchesSubject =
                      selectedSubjectId == "all" ||
                      data["subjectId"] == selectedSubjectId ||
                      subjectName ==
                          subjects
                              .firstWhere(
                                (s) => s["id"] == selectedSubjectId,
                                orElse: () => {"name": ""},
                              )["name"]!
                              .toLowerCase();

                  return matchesSearch && matchesSubject;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                      child: Text("No notes available"));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 270,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data =
                        doc.data() as Map<String, dynamic>;

                    final upvoters =
                        List<String>.from(data["upvoters"] ?? []);
                    final downvoters =
                        List<String>.from(data["downvoters"] ?? []);

                    final didUp = upvoters.contains(uid);
                    final didDown = downvoters.contains(uid);

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("users")
                          .doc(uid)
                          .collection("saved_notes")
                          .doc(doc.id)
                          .snapshots(),
                      builder: (_, savedSnap) {
                        final isSaved = savedSnap.hasData &&
                            savedSnap.data!.exists;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  final url =
                                      data["driveViewUrl"] ??
                                          data["driveUrl"] ??
                                          "";
                                  openDrive(url);
                                },
                                child: Image.asset(
                                  "assets/images/pdf_dummy.png",
                                  height: 110,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data["title"] ??
                                            "Untitled",
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        data["subjectName"] ??
                                            data["subject"] ??
                                            "Unknown",
                                        style: const TextStyle(
                                            fontSize: 12),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.thumb_up,
                                              size: 18,
                                              color: didUp
                                                  ? Colors.blue
                                                  : Colors.grey,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(),
                                            onPressed: () =>
                                                toggleVote(
                                                    doc.id,
                                                    true),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.thumb_down,
                                              size: 18,
                                              color: didDown
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(),
                                            onPressed: () =>
                                                toggleVote(
                                                    doc.id,
                                                    false),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              isSaved
                                                  ? Icons.bookmark
                                                  : Icons
                                                      .bookmark_border,
                                              size: 18,
                                              color: isSaved
                                                  ? Colors.indigo
                                                  : Colors.grey,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(),
                                            onPressed: () async {
                                              await toggleSave(
                                                  doc, isSaved);
                                              if (!isSaved &&
                                                  mounted) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const SavedNotesScreen(),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
