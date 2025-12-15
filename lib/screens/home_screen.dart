import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "";
  bool showGreeting = true;
  DateTime? lastBackTime;

  @override
  void initState() {
    super.initState();
    fetchUserName();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => showGreeting = false);
    });
  }

  Future<void> fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (doc.exists) setState(() => userName = doc["name"] ?? "User");
  }

  // 🔥 SUPER PREMIUM EXIT DIALOG (Blur + Slide + Haptics)
  Future<bool> handleExit() async {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      isScrollControlled: true,
      builder: (context) {
        return _exitSheet(context);
      },
    );

    return false; // prevent app from exiting immediately
  }

  Widget _exitSheet(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 14, right: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.exit_to_app_rounded,
                    size: 42, color: Colors.redAccent),

                const SizedBox(height: 12),

                const Text(
                  "Exit Resource Shelf?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Are you sure you want to exit the app?",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.black26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          SystemNavigator.pop();
                        },
                        child: const Text(
                          "Exit",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: handleExit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),

        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            "Resource Shelf",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.indigo.shade700,
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.person, color: Colors.black87),
                ),
              ),
            )
          ],
        ),

        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: showGreeting
                  ? Padding(
                      key: const ValueKey("greet"),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Welcome back,",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              )),
                          const SizedBox(height: 4),
                          Text(
                            userName.isEmpty ? "Loading..." : userName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            Expanded(
              child: GridView(
                padding: const EdgeInsets.all(20),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.05,
                ),
                children: [
                  _tile(
                    icon: Icons.menu_book_rounded,
                    title: "Notes",
                    color: Colors.blue.shade100,
                    iconColor: Colors.blue.shade700,
                    onTap: () => Navigator.pushNamed(context, '/notes'),
                  ),
                  _tile(
                    icon: Icons.upload_file_rounded,
                    title: "Upload Notes",
                    color: Colors.green.shade100,
                    iconColor: Colors.green.shade700,
                    onTap: () => Navigator.pushNamed(context, '/upload'),
                  ),
                  _tile(
                    icon: Icons.folder_copy_rounded,
                    title: "My Uploads",
                    color: Colors.orange.shade100,
                    iconColor: Colors.orange.shade700,
                    onTap: () => Navigator.pushNamed(context, '/myuploads'),
                  ),
                  _tile(
                    icon: Icons.question_answer_rounded,
                    title: "Doubts",
                    color: Colors.purple.shade100,
                    iconColor: Colors.purple.shade700,
                    onTap: () => Navigator.pushNamed(context, '/doubts'),
                  ),
                  _tile(
                    icon: Icons.bookmark_rounded,
                    title: "Saved Notes",
                    color: Colors.amber.shade100,
                    iconColor: const Color.fromARGB(255, 216, 151, 29),
                    onTap: () => Navigator.pushNamed(context, '/savednotes'),
                  ),
                  _tile(
                    icon: Icons.groups_rounded,
                    title: "Community",
                    color: Colors.teal.shade100,
                    iconColor: Colors.teal.shade700,
                    onTap: () => Navigator.pushNamed(context, '/community'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(icon, size: 30, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
