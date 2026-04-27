import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AppProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? currentUser;
  List<TodoList> lists = [];
  Map<String, TodoList> listDetails = {};
  bool isLoading = true;

  Future<void> checkAuth() async {
    final user = await _apiService.getMe();
    if (user != null) {
      currentUser = user;
      await loadData();
    } else {
      await _apiService.setToken(null);
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = await _apiService.login(email, password);
      if (user != null) {
        currentUser = user;
        await loadData();
        return true;
      }
    } catch (e) {
      print("Login error: $e");
    }
    return false;
  }

  Future<bool> register(String email, String password, String fullName) async {
    try {
      final user = await _apiService.register(email, password, fullName);
      if (user != null) {
        currentUser = user;
        await loadData();
        return true;
      }
    } catch (e) {
      print("Register error: $e");
    }
    return false;
  }

  Future<void> logout() async {
    await _apiService.logout();
    currentUser = null;
    lists = [];
    notifyListeners();
  }

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();
    try {
      lists = await _apiService.getLists();
      // Pre-fetch all list details to populate tasks and stats globally
      await Future.wait(lists.map((l) => loadListDetail(l.id)));
    } catch (e) {
      print("Load data error: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadListDetail(String listId) async {
    try {
      final detail = await _apiService.getListDetail(listId);
      if (detail != null) {
        listDetails[listId] = detail;
        notifyListeners();
      }
    } catch (e) {
      print("Load list detail error: $e");
    }
  }

  Future<void> completeTask(String taskId, String listId) async {
    bool newState = true;
    
    // Optimistic update
    if (listDetails.containsKey(listId)) {
      final list = listDetails[listId]!;
      bool updated = false;

      // Update in main tasks
      if (list.tasks != null) {
        for (var i = 0; i < list.tasks!.length; i++) {
          if (list.tasks![i].id == taskId) {
            list.tasks![i] = list.tasks![i].copyWith(isCompleted: !list.tasks![i].isCompleted);
            newState = list.tasks![i].isCompleted;
            updated = true;
            break;
          }
        }
      }

      // Update in sections
      if (!updated && list.sections != null) {
        for (var section in list.sections!) {
          if (section.tasks != null) {
            for (var i = 0; i < section.tasks!.length; i++) {
              if (section.tasks![i].id == taskId) {
                section.tasks![i] = section.tasks![i].copyWith(isCompleted: !section.tasks![i].isCompleted);
                newState = section.tasks![i].isCompleted;
                updated = true;
                break;
              }
            }
          }
          if (updated) break;
        }
      }

      if (updated) notifyListeners();
    }

    if (newState) {
      await _apiService.completeTask(taskId);
    } else {
      await _apiService.uncompleteTask(taskId);
    }
    await loadListDetail(listId);
  }

  Future<void> addList(String name) async {
    // Optimistic update
    final tempList = TodoList(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      icon: '📋',
      isUrgent: false,
      position: lists.length,
    );
    lists.add(tempList);
    notifyListeners();

    final success = await _apiService.createList(name);
    await loadData();
  }

  Future<void> addTask(String title, String listId) async {
    // Optimistic update
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    if (listDetails.containsKey(listId)) {
      final currentList = listDetails[listId]!;
      final newTasks = List<Task>.from(currentList.tasks ?? []);
      newTasks.add(Task(
        id: tempId,
        listId: listId,
        title: title,
        priority: 'medium',
        isCompleted: false,
        position: newTasks.length,
      ));
      
      listDetails[listId] = currentList.copyWith(tasks: newTasks);
      notifyListeners();
    }

    final success = await _apiService.createTask(title, listId);
    await loadListDetail(listId);
  }

  Future<void> updateTask(String taskId, String listId, Map<String, dynamic> updates) async {
    // Optimistic update
    if (listDetails.containsKey(listId)) {
      final list = listDetails[listId]!;
      bool updated = false;

      void applyUpdates(Task t, int index, List<Task> taskList) {
        taskList[index] = t.copyWith(
          title: updates['title'],
          details: updates['details'],
          subText: updates['sub_text'],
          dueDate: updates['due_date'],
          priority: updates['priority'],
          timeEstimate: updates['time_estimate'],
        );
      }

      if (list.tasks != null) {
        for (var i = 0; i < list.tasks!.length; i++) {
          if (list.tasks![i].id == taskId) {
            applyUpdates(list.tasks![i], i, list.tasks!);
            updated = true;
            break;
          }
        }
      }

      if (!updated && list.sections != null) {
        for (var section in list.sections!) {
          if (section.tasks != null) {
            for (var i = 0; i < section.tasks!.length; i++) {
              if (section.tasks![i].id == taskId) {
                applyUpdates(section.tasks![i], i, section.tasks!);
                updated = true;
                break;
              }
            }
          }
          if (updated) break;
        }
      }

      if (updated) notifyListeners();
    }

    await _apiService.updateTask(taskId, updates);
    await loadListDetail(listId);
  }

  Future<void> deleteTask(String taskId, String listId) async {
    // Optimistic delete
    if (listDetails.containsKey(listId)) {
      final list = listDetails[listId]!;
      bool removed = false;

      // Remove from main tasks
      if (list.tasks != null) {
        final lengthBefore = list.tasks!.length;
        list.tasks!.removeWhere((t) => t.id == taskId);
        if (list.tasks!.length < lengthBefore) removed = true;
      }

      // Remove from sections
      if (!removed && list.sections != null) {
        for (var section in list.sections!) {
          if (section.tasks != null) {
            final lengthBefore = section.tasks!.length;
            section.tasks!.removeWhere((t) => t.id == taskId);
            if (section.tasks!.length < lengthBefore) {
              removed = true;
              break;
            }
          }
        }
      }

      if (removed) notifyListeners();
    }

    await _apiService.deleteTask(taskId);
    await loadListDetail(listId);
  }
}
