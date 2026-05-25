import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/data/services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

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
