import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final educationController = TextEditingController();
  String selectedYear = "1";

  bool loading = false;
  bool initialLoading = true;

  List<String> yearOptions = ["1", "2", "3", "4", "Graduated"];

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    educationController.dispose();
    super.dispose();
  }

  String normalizeYear(dynamic value) {
    if (value == null) return "1";

    String v = value.toString().trim().toLowerCase();

    if (v.contains("1")) return "1";
    if (v.contains("2")) return "2";
    if (v.contains("3")) return "3";
    if (v.contains("4")) return "4";
    if (v.contains("grad")) return "Graduated";

    return "1";
  }

  Future<void> loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        nameController.text = data["name"] ?? "";
        educationController.text = data["education"] ?? "";
        selectedYear = normalizeYear(data["year"]);
      }
    } catch (_) {}
    finally {
      setState(() => initialLoading = false);
    }
  }

  Future<void> updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (nameController.text.trim().isEmpty ||
        educationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields.")),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "name": nameController.text.trim(),
        "education": educationController.text.trim(),
        "year": selectedYear,
      }, SetOptions(merge: true));

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.3),
        builder: (_) => _successSheet(),
      );

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _successSheet() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 14, right: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 60, color: Colors.green),

                const SizedBox(height: 10),

                const Text(
                  "Profile Updated!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Your changes have been saved successfully.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------ UI ------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        elevation: 0,
      ),

      body: initialLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child:

                  /// CARD UI
                  Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      color: Colors.black.withOpacity(0.08),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    /// 🔵 PROFILE AVATAR
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.indigo.shade100,
                      child: Icon(
                        Icons.person_rounded,
                        size: 55,
                        color: Colors.indigo.shade600,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Name Field
                    TextField(
                      controller: nameController,
                      decoration: _input("Name"),
                    ),

                    const SizedBox(height: 18),

                    // Education Field
                    TextField(
                      controller: educationController,
                      decoration: _input("Education"),
                    ),

                    const SizedBox(height: 18),

                    DropdownButtonFormField<String>(
                      value: selectedYear,
                      decoration: _input("Year"),
                      items: yearOptions
                          .map((y) =>
                              DropdownMenuItem(value: y, child: Text(y)))
                          .toList(),
                      onChanged: (v) => setState(() => selectedYear = v!),
                    ),

                    const SizedBox(height: 28),

                    // SAVE BUTTON (Gradient Premium)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : updateProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: Colors.indigo.shade600,
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Save Changes",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
