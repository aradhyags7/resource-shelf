import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ----------- ACCOUNT SECTION TITLE -----------
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                "Account",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),

            _settingsTile(
              icon: Icons.person,
              text: "Edit Profile",
              onTap: () {
                Navigator.pushNamed(context, '/editprofile');
              },
            ),

            _settingsTile(
              icon: Icons.lock,
              text: "Change Password",
              onTap: () {
                Navigator.pushNamed(context, '/changepassword');
              },
            ),

            const SizedBox(height: 30),

            // ----------- APP SECTION TITLE -----------
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                "App",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),

            _settingsTile(
              icon: Icons.info_outline,
              text: "About App",
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: "Resource Shelf",
                  applicationVersion: "1.0",
                  children: const [
                    Text(
                      "A student-friendly notes sharing and doubt solving app.",
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ----------- REUSABLE TILE WIDGET -----------
  Widget _settingsTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 3),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(text, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
