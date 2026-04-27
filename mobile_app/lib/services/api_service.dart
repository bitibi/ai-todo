import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'https://todo-api-269547560191.us-central1.run.app';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> setToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove('access_token');
    } else {
      await prefs.setString('access_token', token);
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth
  Future<User?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['access_token']);
      return User.fromJson(data['user']);
    }
    return null;
  }

  Future<User?> register(String email, String password, String fullName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'full_name': fullName}),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await setToken(data['access_token']);
      return User.fromJson(data['user']);
    }
    return null;
  }

  Future<void> logout() async {
    final headers = await _getHeaders();
    await http.post(Uri.parse('$baseUrl/auth/logout'), headers: headers);
    await setToken(null);
  }

  Future<User?> getMe() async {
    final headers = await _getHeaders();
    if (!headers.containsKey('Authorization')) return null;
    final response = await http.get(Uri.parse('$baseUrl/auth/me'), headers: headers);
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // Lists
  Future<List<TodoList>> getLists() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/lists'), headers: headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => TodoList.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> createList(String name) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/lists'),
      headers: headers,
      body: jsonEncode({'name': name}),
    );
    return response.statusCode == 201;
  }

  Future<TodoList?> getListDetail(String listId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/lists/$listId'), headers: headers);
    if (response.statusCode == 200) {
      return TodoList.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // Tasks
  Future<List<Task>> getTasks({String? listId, String? sectionId, String? priority}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: {
      if (listId != null) 'list_id': listId,
      if (sectionId != null) 'section_id': sectionId,
      if (priority != null) 'priority': priority,
    });
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Task.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> createTask(String title, String listId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: headers,
      body: jsonEncode({'title': title, 'list_id': listId}),
    );
    return response.statusCode == 201;
  }

  Future<bool> updateTask(String taskId, Map<String, dynamic> updates) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: headers,
      body: jsonEncode(updates),
    );
    return response.statusCode == 200;
  }

  Future<bool> completeTask(String taskId) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/tasks/$taskId/complete'), headers: headers);
    return response.statusCode == 200;
  }

  Future<bool> uncompleteTask(String taskId) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/tasks/$taskId/uncomplete'), headers: headers);
    return response.statusCode == 200;
  }

  Future<bool> deleteTask(String taskId) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/tasks/$taskId'), headers: headers);
    return response.statusCode == 204;
  }

  // Drag and drop reordering
  Future<bool> reorderTasks(List<Map<String, dynamic>> items) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/reorder'),
      headers: headers,
      body: jsonEncode(items),
    );
    return response.statusCode == 200;
  }

  Future<bool> reorderSections(List<Map<String, dynamic>> items) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/sections/reorder'),
      headers: headers,
      body: jsonEncode(items),
    );
    return response.statusCode == 200;
  }

  // AI
  Future<String?> transcribe(String filePath) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/ai/transcribe'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('audio', filePath));
    
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      return data['text'];
    }
    return null;
  }
}
