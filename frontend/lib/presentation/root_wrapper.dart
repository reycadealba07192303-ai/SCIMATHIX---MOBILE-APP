import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/presentation/screens/student/student_dashboard.dart';
import 'package:scimathix/presentation/screens/teacher/teacher_dashboard.dart';
import 'package:scimathix/presentation/screens/admin/admin_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:scimathix/presentation/screens/auth/verify_email_screen.dart';
import 'package:scimathix/presentation/screens/auth/login_screen.dart';

class RootWrapper extends ConsumerWidget {
  const RootWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.user != null) {
      // Check Firebase Verification Status
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && !firebaseUser.emailVerified) {
        return const VerifyEmailScreen();
      }

      final role = authState.user!.role;
      if (role == 'admin') return const AdminDashboard();
      if (role == 'teacher') return const TeacherDashboard();
      return const StudentDashboard();
    }

    return const LoginScreen();
  }
}
