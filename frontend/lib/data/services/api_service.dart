import 'package:scimathix/core/utils/app_logger.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:scimathix/core/config/api_config.dart';
import 'package:scimathix/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl => ApiConfig.apiBaseUrl;

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

  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        data['token'] = token;
        return UserModel.fromJson(data);
      }
    } catch (e) {
      AppLogger.error('Get Current User', e);
    }
    return null;
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

  Future<List<dynamic>> getLevels([String? schoolYear]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = schoolYear != null 
          ? '$baseUrl/academic/levels?schoolYear=$schoolYear'
          : '$baseUrl/academic/levels';
      final response = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Levels', e);
    }
    return [];
  }

  Future<List<dynamic>> getSchoolYears() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(Uri.parse('$baseUrl/academic/school-years'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get School Years', e);
    }
    return [];
  }

  Future<bool> createSchoolYear(String year) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/academic/school-years'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'year': year}),
      );
      return response.statusCode == 201;
    } catch (e) {
      AppLogger.error('Create School Year', e);
      return false;
    }
  }

  Future<List<dynamic>> getSections(String levelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(Uri.parse('$baseUrl/academic/sections/$levelId'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Sections', e);
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
      AppLogger.error('Get Teacher Sections', e);
    }
    return [];
  }

  Future<Map<String, dynamic>?> getSectionDetails(String sectionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(Uri.parse('$baseUrl/academic/sections/details/$sectionId'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Section Details', e);
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
      AppLogger.error('Upload Profile Picture', e);
    }
    return null;
  }

  Future<bool> createLevel(String name, String schoolYear) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/academic/levels'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'schoolYear': schoolYear}),
      );
      return response.statusCode == 201;
    } catch (e) {
      AppLogger.error('Create Level', e);
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
      AppLogger.error('Create Section', e);
      return false;
    }
  }


  Future<List<dynamic>> getSectionStudents(String sectionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(Uri.parse('$baseUrl/academic/sections/details/$sectionId'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['students'] ?? [];
      }
    } catch (e) {
      AppLogger.error('Get Section Students', e);
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
      AppLogger.error('Enroll Students', e);
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
      AppLogger.error('Remove Student', e);
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
      AppLogger.error('Assign Teacher', e);
    }
    return false;
  }

  Future<List<dynamic>> getTeachers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(Uri.parse('$baseUrl/academic/teachers'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Teachers', e);
    }
    return [];
  }

  Future<List<dynamic>> getStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(Uri.parse('$baseUrl/academic/students'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Students', e);
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
      AppLogger.error('Create User', e);
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
      AppLogger.error('Update User', e);
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
      AppLogger.error('Delete User', e);
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
      AppLogger.error('Update Teacher Role', e);
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
      AppLogger.error('Suspend User', e);
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
      AppLogger.error('Update Teacher Profile', e);
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
      AppLogger.error('Remove Handled Class', e);
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
      AppLogger.error('Assign Teacher', e);
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
      AppLogger.error('Enroll Student', e);
      return false;
    }
  }

  Future<List<dynamic>> getSubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(Uri.parse('$baseUrl/academic/subjects'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Subjects', e);
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
      AppLogger.error('Create Subject', e);
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
      AppLogger.error('Approve User', e);
    }
    return false;
  }


  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(Uri.parse('$baseUrl/academic/stats'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Admin Stats', e);
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
      AppLogger.error('Get Lessons', e);
    }
    return [];
  }

  Future<Map<String, dynamic>?> uploadLesson({
    required String title,
    required String subjectId,
    required String? content,
    required List<String> sectionIds,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
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
      
      if (fileBytes != null && fileName != null) {
        String ext = fileName.split('.').last.toLowerCase();
        String mimeType = 'application';
        String mimeSubtype = 'octet-stream';
        
        if (ext == 'pdf') {
          mimeType = 'application';
          mimeSubtype = 'pdf';
        } else if (ext == 'png') {
          mimeType = 'image';
          mimeSubtype = 'png';
        } else if (ext == 'jpg' || ext == 'jpeg') {
          mimeType = 'image';
          mimeSubtype = 'jpeg';
        } else if (ext == 'doc' || ext == 'docx') {
          mimeType = 'application';
          mimeSubtype = 'msword';
        }

        request.files.add(http.MultipartFile.fromBytes(
          'file', 
          fileBytes, 
          filename: fileName,
          contentType: MediaType(mimeType, mimeSubtype)
        ));
      } else if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) return jsonDecode(response.body);
      AppLogger.warning('Upload Lesson Failed [${response.statusCode}]: ${response.body}');
    } catch (e) {
      AppLogger.error('Upload Lesson', e);
    }
    return null;
  }

  Future<bool> updateOwnProfile({required String name}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Update Own Profile', e);
      return false;
    }
  }

  Future<Map<String, dynamic>?> uploadProfileImage({
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/users/profile-image'));
      request.headers['Authorization'] = 'Bearer $token';

      if (fileBytes != null && fileName != null) {
        String ext = fileName.split('.').last.toLowerCase();
        String mimeType = 'image';
        String mimeSubtype = 'jpeg';
        
        if (ext == 'png') {
          mimeSubtype = 'png';
        }

        request.files.add(http.MultipartFile.fromBytes(
          'image',
          fileBytes,
          filename: fileName,
          contentType: MediaType(mimeType, mimeSubtype)
        ));
      } else if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('image', filePath));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        AppLogger.warning('Upload Profile Image Failed: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('Upload Profile Image', e);
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
      AppLogger.error('Get Quizzes', e);
    }
    return [];
  }

  Future<List<dynamic>> getClassroomFeed(String sectionId, {String? subjectId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final uri = Uri.parse('$baseUrl/announcements/feed/$sectionId').replace(
        queryParameters: subjectId != null ? {'subjectId': subjectId} : null,
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Classroom Feed', e);
    }
    return [];
  }

  Future<void> createAnnouncement(
    String sectionId,
    String content, {
    String? subjectId,
    String? title,
    DateTime? scheduledDate,
    String? scheduledTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      await http.post(
        Uri.parse('$baseUrl/announcements'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'sectionId': sectionId,
          'subjectId': subjectId,
          'content': content,
          if (title != null) 'title': title,
          if (scheduledDate != null)
            'scheduledDate': scheduledDate.toIso8601String(),
          if (scheduledTime != null) 'scheduledTime': scheduledTime,
        }),
      );
    } catch (e) {
      AppLogger.error('Create Announcement', e);
    }
  }

  Future<List<dynamic>> getCalendarAnnouncements(String sectionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/announcements/calendar/$sectionId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Calendar Announcements', e);
    }
    return [];
  }

  Future<void> updateAnnouncement(String id, String content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      await http.put(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'content': content}),
      );
    } catch (e) {
      AppLogger.error('Update Announcement', e);
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      await http.delete(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      AppLogger.error('Delete Announcement', e);
    }
  }

  Future<Map<String, dynamic>?> generateQuiz({
    String? lessonId,
    List<String>? lessonIds,
    String? title,
    int count = 10,
    String? type,
    List<String>? types,
    bool isPractice = false,
    int timeLimit = 0,
    int? passingScore,
    String? scheduledDate,
    String? scheduledTime,
    String? endTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Prefer lessonIds if provided, fallback to lessonId for backward compatibility
      final Map<String, dynamic> body = {
        'count': count,
        'title': title,
        'type': type,
        'types': types,
        'isPractice': isPractice,
        'timeLimit': timeLimit,
      };
      if (passingScore != null) {
        body['passingScore'] = passingScore;
      }
      if (scheduledDate != null) body['scheduledDate'] = scheduledDate;
      if (scheduledTime != null) body['scheduledTime'] = scheduledTime;
      if (endTime != null) body['endTime'] = endTime;

      if (lessonIds != null && lessonIds.isNotEmpty) {
        body['lessonIds'] = lessonIds;
      } else if (lessonId != null) {
        body['lessonId'] = lessonId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/quizzes/generate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to generate quiz (${response.statusCode})';
      throw Exception(message);
    } catch (e) {
      AppLogger.error('Generate Quiz', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getQuiz(String quizId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/quizzes/$quizId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Quiz Detail', e);
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateQuiz(String quizId, Map<String, dynamic> body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/quizzes/$quizId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Update Quiz', e);
    }
    return null;
  }

  Future<bool> deleteQuiz(String quizId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/quizzes/$quizId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Delete Quiz', e);
    }
    return false;
  }

  Future<Map<String, dynamic>?> getQuizSubmissions(String quizId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/quizzes/$quizId/submissions'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Quiz Submissions', e);
    }
    return null;
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
      AppLogger.error('Get Quiz', e);
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
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        AppLogger.warning('Submit Quiz Failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('Submit Quiz', e);
    }
    return null;
  }

  Future<Map<String, dynamic>> getStudentStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/student/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      AppLogger.error('Get Student Stats', e);
    }
    return {
      'statistics': {
        'totalQuizzes': 0,
        'averageScore': 0,
        'passRate': 0,
        'bestScore': 0,
        'totalXp': 0,
        'totalTimeSeconds': 0,
      },
      'activityHistory': [],
      'achievements': [],
    };
  }

  Future<List<dynamic>> getLeaderboard({String? category, String? sectionId, String? period}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final params = <String, String>{};
      if (category != null) params['category'] = category;
      if (sectionId != null) params['section'] = sectionId;
      if (period != null && period != 'all') params['period'] = period;
      final uri = Uri.parse('$baseUrl/quizzes/leaderboard').replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Leaderboard', e);
    }
    return [];
  }

  // --- Chat API ---

  Future<Map<String, dynamic>?> sendMessage(String content, String? lessonId,
      {String? conversationId}) async {
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
          if (conversationId != null) 'conversationId': conversationId,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Send Message', e);
    }
    return null;
  }

  Future<List<dynamic>> getChatHistory(String lessonId,
      {String? conversationId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final uri = Uri.parse('$baseUrl/chat/$lessonId').replace(
        queryParameters:
            conversationId != null ? {'conversationId': conversationId} : null,
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Chat History', e);
    }
    return [];
  }

  Future<List<dynamic>> getAiConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/chat/conversations/list'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get AI Conversations', e);
    }
    return [];
  }

  Future<Map<String, dynamic>?> sendDirectMessage(String content, String receiverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/chat/direct'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
          'receiverId': receiverId,
        }),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Send Direct Message', e);
    }
    return null;
  }

  Future<List<dynamic>> getDirectMessageHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/chat/direct/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Direct Message History', e);
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
      AppLogger.error('Get Weak Topics', e);
    }
    return [];
  }
  Future<List<dynamic>> getLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/logs'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Logs', e);
    }
    return [];
  }

  Future<List<dynamic>> getNotifications(String target) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifications?target=$target'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Notifications', e);
    }
    return [];
  }

  Future<bool> createNotification({
    required String title,
    required String message,
    required String target,
    String type = 'system',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'message': message,
          'target': target,
          'type': type,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      AppLogger.error('Create Notification', e);
      return false;
    }
  }

  Future<bool> updateNotification(
    String id, {
    String? title,
    String? message,
    String? target,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (title != null) 'title': title,
          if (message != null) 'message': message,
          if (target != null) 'target': target,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Update Notification', e);
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Delete Notification', e);
      return false;
    }
  }

  Future<bool> markNotificationAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Mark Notification Read', e);
      return false;
    }
  }

  Future<Map<String, dynamic>> getAdminReports() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception('Not logged in. Please sign in again.');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/admin-reports'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    final message = body is Map && body['message'] != null
        ? body['message'].toString()
        : 'Failed to load reports (${response.statusCode})';
    throw Exception(message);
  }
  Future<Map<String, dynamic>> getTeacherReports() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception('Not logged in. Please sign in again.');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/teacher-reports'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    final message = body is Map && body['message'] != null
        ? body['message'].toString()
        : 'Failed to load teacher reports (${response.statusCode})';
    throw Exception(message);
  }

  Future<List<dynamic>> getTeacherSectionPerformance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/teacher/section-performance'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Teacher Section Performance', e);
    }
    return [];
  }

  Future<List<dynamic>> getTeacherWeakTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/teacher/weak-topics'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Teacher Weak Topics', e);
    }
    return [];
  }

  Future<Map<String, dynamic>> getTeacherMonitoring() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/teacher/monitoring'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      AppLogger.error('Get Teacher Monitoring', e);
    }
    return {
      'recentActivity': [],
      'inactiveStudents': [],
      'completion': {
        'totalStudents': 0,
        'activeStudents': 0,
        'inactiveCount': 0,
        'completionRate': 0,
      },
    };
  }

  // AI Chat and Mock Quiz
  Future<Map<String, dynamic>?> getQuizByLesson(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/quizzes/lesson/$lessonId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      AppLogger.error('Get Quiz By Lesson', e);
    }
    return null;
  }

  // --- AI CHAT ---

  // --- DIRECT MESSAGING ---

  // --- DELETE (CRUD) ---

  Future<bool> deleteLesson(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/lessons/$lessonId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Delete Lesson', e);
      return false;
    }
  }

  Future<bool> updateLesson(String lessonId, Map<String, dynamic> body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/lessons/$lessonId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Update Lesson', e);
      return false;
    }
  }
}
