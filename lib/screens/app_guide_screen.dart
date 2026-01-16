import 'package:flutter/material.dart';

class AppGuideScreen extends StatelessWidget {
  const AppGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("App User Guide")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            Text(
              "📌 How to Use Resource Shelf",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            Text(
              "• Upload Notes:\n"
              "Go to Upload → paste a Google Drive PDF link → add a title → select a subject → upload.\n"
              "Ensure the PDF is set to 'Anyone with the link can view'.",
            ),
            SizedBox(height: 12),

            Text(
              "• View Notes:\n"
              "Go to Notes → filter by subject or use search → tap a note to open the PDF from Google Drive.",
            ),
            SizedBox(height: 12),

            Text(
              "• My Uploads:\n"
              "Go to My Uploads to view all notes you have uploaded.\n"
              "You can delete your notes from here if needed.",
            ),
            SizedBox(height: 12),

            Text(
              "• Ask Doubts:\n"
              "Go to Doubts → tap the + button → enter your question → post.",
            ),
            SizedBox(height: 12),

            Text(
              "• Answer Doubts:\n"
              "Tap any doubt → scroll to Answers → write and send your answer.",
            ),
            SizedBox(height: 12),

            Text(
              "• Saved Notes:\n"
              "You can bookmark notes to save them and access them later from Saved Notes.",
            ),
            SizedBox(height: 12),

            Text(
              "• Profile Management:\n"
              "Go to Profile → update your name and other details.",
            ),
          ],
        ),
      ),
    );
  }
}
