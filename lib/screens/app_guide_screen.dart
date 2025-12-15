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
            Text("📌 How to Use Resource Shelf", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            SizedBox(height: 20),

            Text("• Upload Notes: Go to Upload → select PDF → give title → select subject."),
            SizedBox(height: 10),

            Text("• View Notes: Go to Notes → filter by subject → tap to open."),
            SizedBox(height: 10),

            Text("• Ask Doubts: Go to Doubts → tap + → type your question."),
            SizedBox(height: 10),

            Text("• Answer Doubts: Tap any doubt → write your answer."),
            SizedBox(height: 10),

            Text("• Manage Profile: Go to Profile → update name, education, year."),
          ],
        ),
      ),
    );
  }
}
