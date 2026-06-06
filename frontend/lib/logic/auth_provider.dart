import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:scimathix/data/models/user_model.dart';
import 'package:scimathix/data/services/api_service.dart';
import 'package:scimathix/core/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
final apiServiceProvider = Provider((ref) => ApiService());

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkPersistence();
    return AuthState();
  }

  Future<void> _checkPersistence() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    
    if (token != null && role != null) {
      // Also check if there's a Firebase user still signed in
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final handledClassesJson = prefs.getString('handledClasses');
        List<HandledClassModel>? handledClasses;
        if (handledClassesJson != null) {
          try {
            final decoded = jsonDecode(handledClassesJson) as List<dynamic>;
            handledClasses = decoded.map((e) => HandledClassModel.fromJson(e)).toList();
          } catch (e) {
            handledClasses = null;
          }
        }

        final user = UserModel(
          id: prefs.getString('userId') ?? '',
          name: prefs.getString('name') ?? 'User', 
          email: firebaseUser.email ?? '', 
          role: role, 
          token: token,
          xp: prefs.getInt('xp') ?? 0,
          section: prefs.getString('section'),
          profilePicture: prefs.getString('profilePicture'),
          handledClasses: handledClasses,
        );
        state = state.copyWith(user: user, isLoading: false);
        // Silently fetch fresh user data (XP, section, etc.) from the backend
        refreshCurrentUser();
      } else {
        // Firebase session expired, clear saved data
        await prefs.remove('token');
        await prefs.remove('role');
        await prefs.remove('name');
        await prefs.remove('userId');
        await prefs.remove('profilePicture');
        await prefs.remove('handledClasses');
        state = state.copyWith(isLoading: false);
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  String _humanizeFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existing account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'No existing account found or incorrect password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact the administrator.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again later.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // 1. Authenticate with Firebase
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
          
      // 2. Try to authenticate with backend
      final apiService = ref.read(apiServiceProvider);
      
      try {
        final user = await apiService.login(email, password); 
        
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('name', user.name);
          await prefs.setString('userId', user.id);
          await prefs.setInt('xp', user.xp);
          if (user.section != null) await prefs.setString('section', user.section!);
          if (user.profilePicture != null) await prefs.setString('profilePicture', user.profilePicture!);
          if (user.handledClasses != null) await prefs.setString('handledClasses', jsonEncode(user.handledClasses!.map((e) => e.toJson()).toList()));
          state = state.copyWith(user: user, isLoading: false);
        } else {
          await firebase_auth.FirebaseAuth.instance.signOut();
          state = state.copyWith(isLoading: false, error: 'Unable to connect to server. Please try again.');
        }
      } catch (apiError) {
        // Firebase login succeeded but backend failed — user might exist in Firebase but not MongoDB
        // Try to auto-sync by registering in MongoDB
        try {
          final user = await apiService.register(
            firebaseUid: userCredential.user!.uid,
            email: email,
            name: userCredential.user?.displayName ?? email.split('@')[0],
            role: 'student',
            password: password,
          );
          
          if (user != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('name', user.name);
            await prefs.setString('userId', user.id);
            await prefs.setString('token', user.token);
            await prefs.setString('role', user.role);
            state = state.copyWith(user: user, isLoading: false);
          } else {
            await firebase_auth.FirebaseAuth.instance.signOut();
            state = state.copyWith(isLoading: false, error: 'Unable to sync your account. Please try again.');
          }
        } catch (syncError) {
          // Auto-sync also failed — maybe user already exists with different password
          await firebase_auth.FirebaseAuth.instance.signOut();
          final message = syncError.toString().replaceAll('Exception: ', '');
          state = state.copyWith(isLoading: false, error: 'Account sync failed: $message');
        }
      }

    } on firebase_auth.FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _humanizeFirebaseError(e.code));
    } catch (e) {
      await firebase_auth.FirebaseAuth.instance.signOut();
      final message = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> refreshCurrentUser() async {
    final apiService = ref.read(apiServiceProvider);
    final refreshedUser = await apiService.getCurrentUser();
    if (refreshedUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', refreshedUser.name);
    await prefs.setString('userId', refreshedUser.id);
    await prefs.setString('role', refreshedUser.role);
    await prefs.setInt('xp', refreshedUser.xp);
    if (refreshedUser.section != null) {
      await prefs.setString('section', refreshedUser.section!);
    } else {
      await prefs.remove('section');
    }
    if (refreshedUser.profilePicture != null) {
      await prefs.setString('profilePicture', refreshedUser.profilePicture!);
    }
    if (refreshedUser.handledClasses != null) {
      await prefs.setString(
        'handledClasses',
        jsonEncode(refreshedUser.handledClasses!.map((e) => e.toJson()).toList()),
      );
    } else {
      await prefs.remove('handledClasses');
    }

    state = state.copyWith(user: refreshedUser, isLoading: false);
  }

  Future<void> register(String email, String password, String name, String role) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // 1. Create account in Firebase
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
          
      // Send Email Verification
      await userCredential.user?.sendEmailVerification();
          
      // 2. Sync to MongoDB Backend
      if (userCredential.user != null) {
        final apiService = ref.read(apiServiceProvider);
        final user = await apiService.register(
          firebaseUid: userCredential.user!.uid,
          email: email,
          name: name,
          role: role,
          password: password, 
        );
        
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('name', name);
          await prefs.setString('userId', user.id);
          await prefs.setString('token', user.token);
          await prefs.setString('role', user.role);
          state = state.copyWith(user: user, isLoading: false);
        } else {
          state = state.copyWith(isLoading: false, error: 'Failed to create account on server.');
        }
      }

    } on firebase_auth.FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _humanizeFirebaseError(e.code));
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> logout() async {
    await firebase_auth.FirebaseAuth.instance.signOut();
    ref.read(apiServiceProvider).logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('name');
    await prefs.remove('userId');
    await prefs.remove('xp');
    await prefs.remove('section');
    await prefs.remove('profilePicture');
    await prefs.remove('handledClasses');
    state = AuthState();
  }

  void updateProfilePictureLocally(String filename) async {
    if (state.user != null) {
      ApiConfig.bustImageCache();
      state = state.copyWith(user: state.user!.copyWith(profilePicture: filename));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profilePicture', filename);
    }
  }
}
