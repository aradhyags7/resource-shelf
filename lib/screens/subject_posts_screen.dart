import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'new_post_screen.dart';

class SubjectPostsScreen extends StatelessWidget {
  final String subject;

  const SubjectPostsScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("$subject Community"),
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
       
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewPostScreen(subject: subject),
            ),
          );
        },
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("community")
            .doc(subject)
            .collection("posts")
            .orderBy("timestamp", descending: true)
            .snapshots(),

        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snap.data!.docs;

          if (posts.isEmpty) {
            return const Center(
              child: Text("No posts yet"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: posts.length,

            itemBuilder: (context, i) {
              final p = posts[i];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
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
                    Text(
                      p["title"],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      p["content"],
                      style: const TextStyle(fontSize: 15),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Posted by: ${p["postedBy"]}",
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
