import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'subject_community_page.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  Stream<QuerySnapshot> getSubjectsStream() {
    return FirebaseFirestore.instance
        .collection("subjects")
        .orderBy("name")
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Communities"),
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: getSubjectsStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjects = snap.data!.docs;

          if (subjects.isEmpty) {
            return const Center(
              child: Text("No communities available yet."),
            );
          }

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, i) {
              final s = subjects[i];
              final subjectName = s["name"];

              final members = s.data().toString().contains("members")
                  ? List<String>.from(s["members"])
                  : <String>[];

              final isJoined = members.contains(uid);

              return Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

                    // LEADING ICON
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: Icon(
                        isJoined ? Icons.check_circle : Icons.groups,
                        color: isJoined ? Colors.green : Colors.indigo,
                      ),
                    ),

                    // TITLE
                    title: Text(
                      "$subjectName Community",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),

                    // SUBTITLE → Members count + Joined badge
                    subtitle: Row(
                      children: [
                        Text(
                          "${members.length} members",
                          style: const TextStyle(color: Colors.black54),
                        ),

                        if (isJoined)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              "Joined",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // TRAILING ARROW
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                    // ON TAP → Go to community
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubjectCommunityPage(
                            subjectId: s.id,
                            subjectName: subjectName,
                          ),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
