import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../database/db_helper.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  bool _isDarkMode = false;
  String _searchQuery = '';
  String _sortBy = 'Due Date'; // 'Due Date', 'Priority'
  static const String _themeKey = 'isDarkMode';

  List<Task> get tasks => _tasks;
  bool get isDarkMode => _isDarkMode;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;

  final DBHelper _dbHelper = DBHelper();
  final NotificationService _notificationService = NotificationService();

  TaskProvider() {
    _loadTheme();
  }

  Future<void> loadTasks() async {
    _tasks = await _dbHelper.getTasks();
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    final id = await _dbHelper.insertTask(task);
    final newTask = task.copyWith(id: id);
    _tasks.add(newTask);
    if (newTask.reminderActive) {
      await _notificationService.scheduleNotification(newTask);
    }
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await _dbHelper.updateTask(task);
    int index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      if (task.reminderActive && !task.isCompleted) {
        await _notificationService.scheduleNotification(task);
      } else {
        await _notificationService.cancelNotification(task.id!);
      }
      notifyListeners();
    }
  }

  Future<void> deleteTask(int id) async {
    await _dbHelper.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    await _notificationService.cancelNotification(id);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  // Analytics
  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;
  double get completionRate => _tasks.isEmpty ? 0 : completedTasksCount / _tasks.length;

  // Filtering, Searching, and Sorting
  List<Task> getFilteredTasks(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    List<Task> filtered = _tasks;

    // 1. Filter by status/date
    switch (filter) {
      case 'Today':
        filtered = _tasks.where((t) => 
          DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day).isAtSameMomentAs(today) && !t.isCompleted
        ).toList();
        break;
      case 'Upcoming':
        filtered = _tasks.where((t) => t.dueDate.isAfter(today.add(const Duration(days: 1))) && !t.isCompleted).toList();
        break;
      case 'Completed':
        filtered = _tasks.where((t) => t.isCompleted).toList();
        break;
      default:
        // 'All' - basically everything
        break;
    }

    // 2. Search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) => 
        t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        t.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // 3. Sort
    if (_sortBy == 'Due Date') {
      filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } else if (_sortBy == 'Priority') {
      filtered.sort((a, b) => b.priority.index.compareTo(a.priority.index)); // High (2) to Low (0)
    }

    return filtered;
  }
}
