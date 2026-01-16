import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/drive_utils.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final titleController = TextEditingController();
  final linkController = TextEditingController();

  bool uploading = false;

  List<Map<String, String>> subjects = [];
  String? selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  void dispose() {
    titleController.dispose();
    linkController.dispose();
    super.dispose();
  }

  // ---------------- FETCH SUBJECTS ----------------
  Future<void> _fetchSubjects() async {
    final snap = await FirebaseFirestore.instance
        .collection("subjects")
        .orderBy("name")
        .get();

    if (!mounted) return;

    subjects = snap.docs
        .map((d) => {"id": d.id, "name": d["name"].toString()})
        .toList();

    if (subjects.isEmpty) {
      subjects = [{"id": "general", "name": "General"}];
    }

    selectedSubjectId = subjects.first["id"];
    setState(() {});
  }

  // ---------------- ADD SUBJECT ----------------
  void _addSubjectDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Subject"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Subject name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection("subjects")
                  .add({"name": name});

              Navigator.pop(context);
              _fetchSubjects();
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ---------------- UPLOAD NOTE ----------------
  Future<void> uploadNote() async {
    if (uploading) return;

    final title = titleController.text.trim();
    final link = linkController.text.trim();

    if (title.isEmpty || link.isEmpty) {
      _snack("Fill all fields");
      return;
    }

    final fileId = extractDriveFileId(link);
    if (fileId.isEmpty) {
      _snack("Invalid Google Drive link");
      return;
    }

    setState(() => uploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final subject =
          subjects.firstWhere((s) => s["id"] == selectedSubjectId);

      await FirebaseFirestore.instance.collection("notes").add({
        "title": title,
        "subjectId": subject["id"],
        "subjectName": subject["name"],
        "driveFileId": fileId,
        "driveViewUrl": driveViewUrl(fileId),
        "uploadedByUid": user.uid,
        "uploadedByName": userDoc["name"] ?? "Unknown",
        "createdAt": FieldValue.serverTimestamp(),
        "upvotes": 0,
        "downvotes": 0,
        "upvoters": [],
        "downvoters": [],
      });

      titleController.clear();
      linkController.clear();
      _snack("Note uploaded successfully");
    } catch (e) {
      _snack("Upload failed. Try again.");
    } finally {
      if (mounted) {
        setState(() => uploading = false);
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(title: const Text("Upload Note")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Note Title",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Select Subject",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add Subject"),
                    onPressed: _addSubjectDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedSubjectId,
                items: subjects
                    .map(
                      (s) => DropdownMenuItem<String>(
                        value: s["id"],
                        child: Text(s["name"]!),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedSubjectId = v),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text("Google Drive PDF Link",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: uploading ? null : uploadNote,
                  child: uploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Upload Note"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
