import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:scimathix/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Using adb reverse: phone connects via USB, no same-network needed
  // Run: adb reverse tcp:5000 tcp:5000
  static const String baseUrl = 'http://localhost:5000/api';

  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data);
        
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', user.token);
        await prefs.setString('role', user.role);
        
        return user;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> register({
    required String firebaseUid,
    required String email,
    required String name,
    required String role,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebaseUid': firebaseUid,
          'email': email,
          'name': name,
          'role': role,
          'password': password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
  }

  // --- Academic API ---

  Future<List<dynamic>> getLevels() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/academic/levels'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Levels Error: $e');
    }
    return [];
  }

  Future<List<dynamic>> getSections(String levelId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/academic/sections/$levelId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Sections Error: $e');
    }
    return [];
  }

  Future<List<dynamic>> getTeacherSections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/academic/sections/my-sections'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Teacher Sections Error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getSectionDetails(String sectionId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/academic/sections/details/$sectionId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Section Details Error: $e');
    }
    return null;
  }

  Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/profile-picture'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('profilePicture', imageFile.path));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['profilePicture'];
      }
    } catch (e) {
      print('Upload Profile Picture Error: $e');
    }
    return null;
  }

  Future<bool> createLevel(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/academic/levels'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Create Level Error: $e');
      return false;
    }
  }

  Future<bool> createSection(String name, String levelId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/academic/sections'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'level': levelId}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Create Section Error: $e');
      return false;
    }
  }


  Future<List<dynamic>> getSectionStudents(String sectionId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/academic/sections/details/$sectionId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['students'] ?? [];
      }
    } catch (e) {
      print('Get Section Students Error: $e');
    }
    return [];
  }


  Future<bool> enrollStudents(List<String> studentIds, String sectionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/academic/sections/enroll-student'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'studentIds': studentIds, 'sectionId': sectionId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Enroll Students Error: $e');
    }
    return false;
  }

  Future<bool> removeStudentFromSection(String studentId, String sectionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/academic/sections/remove-student'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'studentId': studentId, 'sectionId': sectionId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Remove Student Error: $e');
    }
    return false;
  }


  Future<bool> assignTeacher(String teacherId, String sectionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/academic/sections/assign-teacher'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'teacherId': teacherId, 'sectionId': sectionId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Assign Teacher Error: $e');
    }
    return false;
  }

  Future<List<dynamic>> getTeachers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/academic/teachers'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Teachers Error: $e');
    }
    return [];
  }

  Future<List<dynamic>> getStudents() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/academic/students'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Students Error: $e');
    }
    return [];
  }

  // --- USER CRUD (Admin) ---

  Future<bool> createUser(String name, String email, String password, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Create User Error: $e');
      return false;
    }
  }

  Future<bool> updateUser(String id, String name, String email, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'role': role,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update User Error: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Delete User Error: $e');
      return false;
    }
  }

  // --- TEACHER ROLE ASSIGNMENT ---

  Future<bool> updateUserRoleSubject(String teacherId, String specialty) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/academic/teachers/$teacherId/assign-role'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'specialty': specialty}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update Teacher Role Error: $e');
      return false;
    }
  }

  Future<bool> suspendUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/academic/users/$userId/suspend'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Suspend User Error: $e');
      return false;
    }
  }

  Future<bool> updateTeacherProfile(String teacherId, String name, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/academic/teachers/$teacherId/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update Teacher Profile Error: $e');
      return false;
    }
  }

  Future<bool> removeHandledClass(String teacherId, String handledClassId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/academic/teachers/$teacherId/handled-classes/$handledClassId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Remove Handled Class Error: $e');
      return false;
    }
  }

  // --- ACADEMIC ASSIGNMENTS ---



  Future<bool> assignTeacherToSection(String teacherId, String sectionId, String subjectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/academic/sections/assign-teacher'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'teacherId': teacherId,
          'sectionId': sectionId,
          'subjectId': subjectId
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Assign Teacher Error: $e');
      return false;
    }
  }

  Future<bool> enrollStudentToSection(String studentId, String sectionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/academic/sections/enroll-student'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'studentId': studentId,
          'sectionId': sectionId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Enroll Student Error: $e');
      return false;
    }
  }

  Future<List<dynamic>> getSubjects() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/academic/subjects'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Subjects Error: $e');
    }
    return [];
  }



  Future<Map<String, dynamic>?> createSubject(String name, String code, String category, {String? sectionId}) async {
    try {
      final body = {'name': name, 'code': code, 'category': category};
      if (sectionId != null) body['sectionId'] = sectionId;
      final response = await http.post(
        Uri.parse('$baseUrl/academic/subjects'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to create subject');
      }
    } catch (e) {
      print('Create Subject Error: $e');
      rethrow;
    }
  }

  Future<bool> approveUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/academic/approve-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Approve User Error: $e');
    }
    return false;
  }


  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/academic/stats'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Admin Stats Error: $e');
    }
    return {
      "studentCount": 0,
      "teacherCount": 0,
      "lessonCount": 0,
    };
  }

  // --- Lessons API ---

  Future<List<dynamic>> getLessons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/lessons'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Lessons Error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> uploadLesson({
    required String title,
    required String subjectId,
    required String? content,
    required List<String> sectionIds,
    String? filePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/lessons'));
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['title'] = title;
      request.fields['subject'] = subjectId;
      if (content != null) request.fields['content'] = content;
      request.fields['sections'] = jsonEncode(sectionIds);
      
      if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) return jsonDecode(response.body);
    } catch (e) {
      print('Upload Lesson Error: $e');
    }
    return null;
  }

  // --- Quizzes API ---

  Future<List<dynamic>> getQuizzes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/quizzes'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Quizzes Error: $e');
    }
    return [];
  }

  Future<List<dynamic>> getClassroomFeed(String sectionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/announcements/feed/$sectionId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Classroom Feed Error: $e');
    }
    return [];
  }

  Future<void> createAnnouncement(String sectionId, String content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      await http.post(
        Uri.parse('$baseUrl/announcements'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'sectionId': sectionId, 'content': content}),
      );
    } catch (e) {
      print('Create Announcement Error: $e');
    }
  }

  Future<Map<String, dynamic>?> getQuizToTake(String quizId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/quizzes/$quizId/take'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Quiz Error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> submitQuizResults({
    required String quizId,
    required List<Map<String, dynamic>> answers,
    required int timeTaken,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/quizzes/$quizId/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'answers': answers,
          'timeTaken': timeTaken,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Submit Quiz Error: $e');
    }
    return null;
  }

  Future<List<dynamic>> getLeaderboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/quizzes/leaderboard'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Leaderboard Error: $e');
    }
    return [];
  }

  // --- Chat API ---

  Future<Map<String, dynamic>?> sendMessage(String content, String? lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
          'lessonId': lessonId,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Send Message Error: $e');
    }
    return null;
  }

  Future<List<dynamic>> getChatHistory(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/chat/$lessonId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Chat History Error: $e');
    }
    return [];
  }

  // --- Analytics API ---

  Future<List<dynamic>> getWeakTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/weak-topics'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Weak Topics Error: $e');
    }
    return [];
  }
  Future<List<dynamic>> getLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/logs'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Logs Error: $e');
    }
    return [];
  }

  Future<List<dynamic>> getNotifications(String target) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifications?target=$target'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Notifications Error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getAdminReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/admin-reports'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Get Admin Reports Error: $e');
    }
    return null;
  }
}
