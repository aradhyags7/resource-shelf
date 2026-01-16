import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help & Support")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "FAQs",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          // FAQ 1
          const ExpansionTile(
            title: Text("How do I upload notes?"),
            children: [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "Go to 'Upload Notes' → paste a Google Drive PDF link → add title → select subject → upload.\n\n"
                  "Make sure the Drive file access is set to 'Anyone with the link can view'.\n\n"
                  "Your uploaded notes will appear in 'Notes' and 'My Uploads'.",
                ),
              ),
            ],
          ),

          // FAQ 2
          const ExpansionTile(
            title: Text("How do I share a Google Drive PDF link?"),
            children: [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "Open Google Drive → select your PDF → tap 'Share' → change access to "
                  "'Anyone with the link' → copy the link → paste it in the upload section.",
                ),
              ),
            ],
          ),

          // FAQ 3
          const ExpansionTile(
            title: Text("How do I ask a doubt?"),
            children: [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "Go to 'Doubts' → tap the + button → enter your question → post.\n\n"
                  "Other users can view and answer your doubt.",
                ),
              ),
            ],
          ),

          // FAQ 4
          const ExpansionTile(
            title: Text("How do I view notes uploaded by others?"),
            children: [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "Go to 'Notes' → filter by subject or search → tap on a note to open the Google Drive PDF.",
                ),
              ),
            ],
          ),

          // FAQ 5
          const ExpansionTile(
            title: Text("Where can I find my uploaded notes?"),
            children: [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "Go to 'My Uploads' to see all the notes you have uploaded.\n"
                  "You can also delete your notes from there.",
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),
          const Divider(),

          const SizedBox(height: 10),
          const Text(
            "Support Options",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          // Contact Support
          ListTile(
            leading: const Icon(Icons.email, color: Colors.blue),
            title: const Text("Contact Support"),
            subtitle: const Text("resourceshelf.helpdesk@gmail.com"),
            onTap: () {},
          ),

          // Report a problem
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.red),
            title: const Text("Report a Problem"),
            subtitle: const Text("Tell us if something is not working."),
            onTap: () {
              Navigator.pushNamed(context, "/reportProblem");
            },
          ),

          // App guide
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.green),
            title: const Text("App User Guide"),
            subtitle: const Text(
              "Learn how to use Resource Shelf effectively.",
            ),
            onTap: () {
              Navigator.pushNamed(context, "/appGuide");
            },
          ),
        ],
      ),
    );
  }
}
