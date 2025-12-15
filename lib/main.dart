import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Screens
import 'screens/auth_checker.dart';
import 'screens/notes_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/help_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/my_uploads_screen.dart';
import 'screens/doubt_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/report_problem_screen.dart';
import 'screens/app_guide_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/saved_notes_screen.dart';
import 'screens/community_screen.dart';
import 'screens/forgot_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ⭐ All routes defined here for easy access
  static final Map<String, WidgetBuilder> appRoutes = {
    '/splash': (context) => const SplashScreen(),
    '/': (context) => const AuthChecker(),

    '/login': (context) => const LoginScreen(),
    '/signup': (context) => const SignupScreen(),

    '/home': (context) => const HomeScreen(),
    '/notes': (context) => const NotesPage(),
    '/upload': (context) => const UploadScreen(),
    '/help': (context) => const HelpScreen(),
    '/profile': (context) => const ProfileScreen(),
    '/myuploads': (context) => const MyUploadsScreen(),
    '/doubts': (context) => const DoubtScreen(),
    '/savednotes': (context) => const SavedNotesScreen(),

    '/settings': (context) => const SettingsScreen(),
    '/editprofile': (context) => const EditProfileScreen(),
    '/changepassword': (context) => const ChangePasswordScreen(),
    '/help_support': (context) => const HelpSupportScreen(),
    '/reportProblem': (context) => const ReportProblemScreen(),
    '/appGuide': (context) => const AppGuideScreen(),

    '/pdfviewer': (context) => PDFViewerScreen(pdfUrl: ""),
    '/community': (context) => const CommunityScreen(),
    '/forgotpassword': (context) => const ForgotPasswordScreen(),

  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      onGenerateRoute: generatePremiumRoute,
      routes: appRoutes,
    );
  }
}

//
// ⭐⭐⭐ Fade Transition For All Screens ⭐⭐⭐
//

Route<dynamic> generatePremiumRoute(RouteSettings settings) {
  final builder = MyApp.appRoutes[settings.name];

  if (builder == null) {
    return MaterialPageRoute(
      builder: (_) =>
          const Scaffold(body: Center(child: Text("Route not found"))),
    );
  }

  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.fastOutSlowIn,
      );

      final scale = Tween<double>(
        begin: 0.94,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuad));

      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}
