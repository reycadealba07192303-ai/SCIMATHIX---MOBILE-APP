import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/logic/auth_provider.dart';

final lessonsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return await api.getLessons();
});

final quizzesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return await api.getQuizzes();
});

final teacherSectionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return await api.getTeacherSections();
});

final classroomFeedProvider = FutureProvider.family<List<dynamic>, String>((ref, sectionId) async {
  final api = ref.read(apiServiceProvider);
  return await api.getClassroomFeed(sectionId);
});

final sectionDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, sectionId) async {
  final api = ref.read(apiServiceProvider);
  return await api.getSectionDetails(sectionId);
});

final globalAnnouncementsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final user = ref.read(authProvider).user;
  String target = 'OVERALL';
  if (user?.role == 'student') {
    target = 'STUDENT ONLY';
  } else if (user?.role == 'teacher') {
    target = 'TEACHER ONLY';
  }
  final notifications = await api.getNotifications(target);
  return notifications.where((n) => n['type'] == 'announcement').toList();
});
