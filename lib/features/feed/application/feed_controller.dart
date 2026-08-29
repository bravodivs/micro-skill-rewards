import 'package:flutter/foundation.dart';
import 'package:momentum_learning_feed/features/feed/data/learning_content_repository.dart';
import 'package:momentum_learning_feed/features/feed/data/progress_store.dart';
import 'package:momentum_learning_feed/features/feed/domain/learning_item.dart';
import 'package:momentum_learning_feed/features/feed/domain/progress_snapshot.dart';

class FeedController extends ChangeNotifier {
  FeedController({
    required this.contentRepository,
    required this.progressStore,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final LearningContentRepository contentRepository;
  final ProgressStore progressStore;
  final DateTime Function() _now;

  late final List<LearningItem> _allItems;
  int _xp = 0;
  int _streak = 1;
  int _navigationIndex = 0;
  bool _onboardingSeen = false;
  LearningTopic? _selectedTopic;
  Set<String> _completedIds = {};
  Set<String> _savedIds = {};
  Map<String, int> _answers = {};
  String? _lastActiveDate;

  List<LearningItem> get allItems => List.unmodifiable(_allItems);
  List<LearningItem> get visibleItems {
    final topic = _selectedTopic;
    if (topic == null) return allItems;
    return _allItems.where((item) => item.topic == topic).toList();
  }

  List<LearningItem> get savedItems =>
      _allItems.where((item) => _savedIds.contains(item.id)).toList();

  int get xp => _xp;
  int get streak => _streak;
  int get navigationIndex => _navigationIndex;
  bool get onboardingSeen => _onboardingSeen;
  LearningTopic? get selectedTopic => _selectedTopic;
  int get completedCount => _completedIds.length;
  double get dailyProgress =>
      _allItems.isEmpty ? 0 : _completedIds.length / _allItems.length;

  Future<void> initialize() async {
    _allItems = contentRepository.dailyItems;
    final snapshot = await progressStore.load();
    _xp = snapshot.xp;
    _streak = snapshot.streak;
    _completedIds = Set.of(snapshot.completedIds);
    _savedIds = Set.of(snapshot.savedIds);
    _answers = Map.of(snapshot.answers);
    _onboardingSeen = snapshot.onboardingSeen;
    _lastActiveDate = snapshot.lastActiveDate;
    _updateStreak();
    await _persist();
  }

  bool isCompleted(String itemId) => _completedIds.contains(itemId);
  bool isSaved(String itemId) => _savedIds.contains(itemId);
  int? answerFor(String itemId) => _answers[itemId];

  void selectTopic(LearningTopic? topic) {
    if (_selectedTopic == topic) return;
    _selectedTopic = topic;
    notifyListeners();
  }

  void setNavigationIndex(int index) {
    if (_navigationIndex == index) return;
    _navigationIndex = index;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingSeen = true;
    notifyListeners();
    await _persist();
  }

  Future<int> completeItem(LearningItem item, {int? selectedOption}) async {
    if (_completedIds.contains(item.id)) return 0;

    if (item.isInteractive) {
      if (selectedOption == null) return 0;
      _answers[item.id] = selectedOption;
    }

    final earned = ProgressScoring.scoreFor(item, selectedOption);
    _completedIds.add(item.id);
    _xp += earned;
    notifyListeners();
    await _persist();
    return earned;
  }

  Future<void> toggleSaved(String itemId) async {
    if (_savedIds.contains(itemId)) {
      _savedIds.remove(itemId);
    } else {
      _savedIds.add(itemId);
    }
    notifyListeners();
    await _persist();
  }

  void _updateStreak() {
    final today = _dateOnly(_now());
    if (_lastActiveDate == today) return;

    if (_lastActiveDate != null) {
      final previous = DateTime.tryParse(_lastActiveDate!);
      final current = DateTime.parse(today);
      if (previous != null && current.difference(previous).inDays == 1) {
        _streak += 1;
      } else {
        _streak = 1;
      }
    } else {
      _streak = 1;
    }
    _lastActiveDate = today;
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  ProgressSnapshot get snapshot => ProgressSnapshot(
    xp: _xp,
    streak: _streak,
    completedIds: Set.unmodifiable(_completedIds),
    savedIds: Set.unmodifiable(_savedIds),
    answers: Map.unmodifiable(_answers),
    onboardingSeen: _onboardingSeen,
    lastActiveDate: _lastActiveDate,
  );

  Future<void> _persist() => progressStore.save(snapshot);
}
