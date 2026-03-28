// lib/providers/draft_provider.dart
import 'package:flutter/foundation.dart';
import '../models/draft.dart';
import '../utils/draft_storage.dart';

class DraftProvider extends ChangeNotifier {
  final _storage = DraftStorage();
  TaskDraft _draft = const TaskDraft();

  TaskDraft get draft => _draft;

  Future<void> load() async {
    final saved = await _storage.load();
    if (saved != null && !saved.isEmpty) {
      _draft = saved;
      notifyListeners();
    }
  }

  void update(TaskDraft d) {
    _draft = d;
    _storage.save(d);
    notifyListeners();
  }

  Future<void> clear() async {
    _draft = const TaskDraft();
    await _storage.clear();
    notifyListeners();
  }
}
