import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SubjectChatScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const SubjectChatScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubjectChatScreen> createState() => _SubjectChatScreenState();
}

class _SubjectChatScreenState extends State<SubjectChatScreen> {
  final TextEditingController msgController = TextEditingController();
  final TextEditingController editController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late final String uid;
  String userName = "User";

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    if (doc.exists) {
      userName = doc["name"] ?? "User";
    }
  }

  // ---------------- SEND ----------------
  Future<void> sendMessage() async {
    final text = msgController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection("community_chats")
        .doc(widget.subjectId)
        .collection("messages")
        .add({
          "text": text,
          "uid": uid,
          "sentBy": userName,
          "timestamp": FieldValue.serverTimestamp(),
          "edited": false,
        });

    msgController.clear();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------- DELETE ----------------
  Future<void> deleteMessage(String msgId) async {
    await FirebaseFirestore.instance
        .collection("community_chats")
        .doc(widget.subjectId)
        .collection("messages")
        .doc(msgId)
        .delete();
  }

  // ---------------- EDIT ----------------
  Future<void> editMessage(String msgId, String oldText) async {
    editController.text = oldText;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit message"),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection("community_chats")
                  .doc(widget.subjectId)
                  .collection("messages")
                  .doc(msgId)
                  .update({"text": newText, "edited": true});

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> leaveCommunity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Leave community?"),
        content: const Text(
          "You will stop receiving messages from this community.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Leave", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection("subjects")
        .doc(widget.subjectId)
        .update({
          "members": FieldValue.arrayRemove([uid]),
        });

    if (!mounted) return;

    Navigator.pop(context); // back to community list
  }

  // ---------------- MESSAGE BUBBLE (FIXED) ----------------
  Widget messageBubble(Map<String, dynamic> m, String msgId) {
    final isMe = m["uid"] == uid;
    final text = m["text"] ?? "";
    final sender = m["sentBy"] ?? "User";
    final edited = m["edited"] == true;

    final ts = m["timestamp"] as Timestamp?;
    final time = ts == null ? "" : DateFormat("hh:mm a").format(ts.toDate());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe
            ? () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text("Edit"),
                        onTap: () {
                          Navigator.pop(context);
                          editMessage(msgId, text);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          await deleteMessage(msgId);
                        },
                      ),
                    ],
                  ),
                );
              }
            : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          decoration: BoxDecoration(
            color: isMe ? Colors.indigo.shade200 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMe)
                Text(
                  sender,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              // MESSAGE + TIME
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(text, style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (edited)
                        const Text(
                          "edited",
                          style: TextStyle(fontSize: 9, color: Colors.black54),
                        ),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: Text(widget.subjectName),
  actions: [
    PopupMenuButton<String>(
      onSelected: (value) {
        if (value == "leave") {
          leaveCommunity();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: "leave",
          child: Text(
            "Leave Community",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  ],
),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("community_chats")
                  .doc(widget.subjectId)
                  .collection("messages")
                  .orderBy("timestamp")
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return messageBubble(data, docs[i].id);
                  },
                );
              },
            ),
          ),

          // INPUT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: msgController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
