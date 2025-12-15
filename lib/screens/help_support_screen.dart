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
          ExpansionTile(
            title: const Text("How do I upload notes?"),
            children: const [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "Go to 'Upload Notes' → choose PDF → add title → select subject → upload.\n"
                  "Your notes will appear in 'My Uploads'.",
                ),
              ),
            ],
          ),

          // FAQ 2
          ExpansionTile(
            title: const Text("How do I ask a doubt?"),
            children: const [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "Go to 'Doubts' → tap the + button → enter question → post.\n"
                  "Others can view and answer it.",
                ),
              ),
            ],
          ),

          // FAQ 3
          ExpansionTile(
            title: const Text("How do I view notes from others?"),
            children: const [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "Go to 'Notes' → filter by subject → tap a note to open it.",
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
