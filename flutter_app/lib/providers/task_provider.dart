// lib/providers/task_provider.dart
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../utils/api_service.dart';

enum ProviderState { idle, loading, saving, error }

class TaskProvider extends ChangeNotifier {
  List<Task>    _tasks       = [];
  ProviderState _state       = ProviderState.idle;
  String?       _error;
  String        _searchQuery = '';
  TaskStatus?   _statusFilter;

  List<Task>    get tasks        => _tasks;
  ProviderState get state        => _state;
  String?       get error        => _error;
  String        get searchQuery  => _searchQuery;
  TaskStatus?   get statusFilter => _statusFilter;
  bool          get isSaving     => _state == ProviderState.saving;
  bool          get isLoading    => _state == ProviderState.loading;

  // ── Derived ────────────────────────────────────────────────────────────

  bool isBlocked(Task task) {
    if (task.blockedById == null) return false;
    final blocker = _taskById(task.blockedById!);
    return blocker != null && blocker.status != TaskStatus.done;
  }

  Task? _taskById(String id) {
    try { return _tasks.firstWhere((t) => t.id == id); }
    catch (_) { return null; }
  }

  Task? taskById(String? id) => id == null ? null : _taskById(id);

  // Tasks available to be a "blocked by" selector (excludes self)
  List<Task> blockerChoices(String? excludeId) =>
      _tasks.where((t) => t.id != excludeId).toList();

  // ── Filter / search ────────────────────────────────────────────────────

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setStatusFilter(TaskStatus? s) {
    _statusFilter = s;
    notifyListeners();
  }

  List<Task> get filteredTasks {
    var list = List<Task>.from(_tasks);
    if (_statusFilter != null) {
      list = list.where((t) => t.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) => t.title.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // ── Data loading ───────────────────────────────────────────────────────

  Future<void> loadTasks() async {
    _setState(ProviderState.loading);
    try {
      _tasks = await ApiService.listTasks();
      _setState(ProviderState.idle);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── CRUD ───────────────────────────────────────────────────────────────

  Future<bool> createTask(Map<String, dynamic> body) async {
    _setState(ProviderState.saving);
    try {
      final task = await ApiService.createTask(body);
      _tasks.add(task);
      _setState(ProviderState.idle);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> updateTask(String id, Map<String, dynamic> body) async {
    _setState(ProviderState.saving);
    try {
      final updated = await ApiService.updateTask(id, body);
      final idx = _tasks.indexWhere((t) => t.id == id);
      if (idx != -1) _tasks[idx] = updated;
      _setState(ProviderState.idle);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      await ApiService.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, item);
    notifyListeners();
    await ApiService.reorderTasks(_tasks.map((t) => t.id).toList());
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  void clearError() { _error = null; notifyListeners(); }

  void _setState(ProviderState s) {
    _state = s; _error = null; notifyListeners();
  }

  void _setError(String msg) {
    _state = ProviderState.error; _error = msg; notifyListeners();
  }
}
