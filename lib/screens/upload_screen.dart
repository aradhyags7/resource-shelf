import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? pickedFile;
  Uint8List? pickedBytes;
  String fileName = "";
  String selectedSubject = "";
  final titleController = TextEditingController();

  List<String> subjects = [];
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  // ---------------- FETCH SUBJECTS ----------------
  Future fetchSubjects() async {
    final snap = await FirebaseFirestore.instance
        .collection("subjects")
        .orderBy("name")
        .get();

    subjects = snap.docs.map((d) => d["name"].toString()).toList();

    if (subjects.isEmpty) subjects = ["General"];

    selectedSubject = subjects.first;

    setState(() {});
  }

  // ---------------- ADD SUBJECT POPUP ----------------
  void openAddSubjectDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Create Subject"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "Subject Name",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Add"),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                // prevent duplicates
                final existing = await FirebaseFirestore.instance
                    .collection("subjects")
                    .where("name", isEqualTo: name)
                    .get();

                if (existing.docs.isEmpty) {
                  await FirebaseFirestore.instance
                      .collection("subjects")
                      .add({
                    "name": name,
                    "members": [],          // <-- CRUCIAL FIX
                    "createdAt": DateTime.now(),
                  });
                }

                Navigator.pop(context);
                fetchSubjects();
              },
            ),
          ],
        );
      },
    );
  }

  // ---------------- FILE PICKER ----------------
  Future pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result == null) return;

    setState(() {
      fileName = result.files.single.name;
      pickedBytes = result.files.single.bytes;
      pickedFile = result.files.single.path != null
          ? File(result.files.single.path!)
          : null;
    });
  }

  // ---------------- UPLOAD NOTE ----------------
  Future uploadNote() async {
    if (fileName.isEmpty || titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields properly")),
      );
      return;
    }

    setState(() => uploading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    // get user name
    final userDoc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    final uploaderName = userDoc["name"] ?? "Unknown";

    String ext = fileName.split('.').last.toLowerCase();

    final storageRef = FirebaseStorage.instance
        .ref()
        .child("notes")
        .child("${DateTime.now().millisecondsSinceEpoch}.$ext");

    // upload file
    if (pickedBytes != null) {
      await storageRef.putData(pickedBytes!);
    } else if (pickedFile != null) {
      await storageRef.putFile(pickedFile!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File error. Try again.")),
      );
      setState(() => uploading = false);
      return;
    }

    final downloadURL = await storageRef.getDownloadURL();

    String fileType = ext == "pdf"
        ? "pdf"
        : (["jpg", "jpeg", "png"].contains(ext))
            ? "image"
            : "doc";

    // Save entry
    await FirebaseFirestore.instance.collection("notes").add({
      "title": titleController.text,
      "subject": selectedSubject,
      "url": downloadURL,
      "type": fileType,
      "uploadedBy": uploaderName,
      "uploadedByUid": uid,
      "timestamp": DateTime.now(),
    });

    setState(() {
      uploading = false;
      pickedBytes = null;
      pickedFile = null;
      fileName = "";
      titleController.clear();
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Upload successful!")));
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("Upload Notes"),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ----------- TITLE CARD -----------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    color: Colors.black.withOpacity(0.06),
                  )
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
                      hintText: "Enter note title...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text("Select Subject",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: selectedSubject.isEmpty ? null : selectedSubject,
                    items: subjects
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedSubject = v!),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Create subject"),
                      onPressed: openAddSubjectDialog,
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ----------- FILE PICKER CARD -----------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    color: Colors.black.withOpacity(0.06),
                  )
                ],
              ),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Choose File"),
                  ),
                  const SizedBox(height: 10),
                  if (fileName.isNotEmpty)
                    Text("Selected: $fileName",
                        style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ----------- UPLOAD BUTTON -----------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: uploading ? null : uploadNote,
                child: uploading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Text("Upload Note",
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
