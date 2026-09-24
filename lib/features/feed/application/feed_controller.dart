import 'package:flutter/foundation.dart';
import 'package:momentum_learning_feed/features/feed/data/learning_content_repository.dart';
import 'package:momentum_learning_feed/features/feed/data/progress_store.dart';
import 'package:momentum_learning_feed/features/feed/domain/daily_pack.dart';
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

  List<LearningItem> _allItems = [];
  List<LearningItem> _savedItems = [];
  int _xp = 0;
  int _streak = 1;
  int _navigationIndex = 0;
  bool _onboardingSeen = false;
  bool _isPrefetching = false;
  final Set<String> _prefetchChecks = {};
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

  List<LearningItem> get savedItems => List.unmodifiable(_savedItems);

  int get xp => _xp;
  int get streak => _streak;
  int get navigationIndex => _navigationIndex;
  bool get onboardingSeen => _onboardingSeen;
  bool get isPrefetching => _isPrefetching;
  String? get catalogSyncError => contentRepository.lastSyncError;
  LearningTopic? get selectedTopic => _selectedTopic;
  int get completedCount => _completedIds.length;
  int get dailyLimit => contentRepository.dailyCap;
  double get dailyProgress =>
      _allItems.isEmpty ? 0 : _completedIds.length / _allItems.length;

  Future<void> initialize() async {
    final snapshot = await progressStore.load();
    _xp = snapshot.xp;
    _streak = snapshot.streak;
    _savedIds = Set.of(snapshot.savedIds);
    _onboardingSeen = snapshot.onboardingSeen;
    _lastActiveDate = snapshot.lastActiveDate;
    _updateStreak();

    final entries = await contentRepository.prepareDailyPack(_now());
    _applyDailyEntries(entries);
    _savedItems = await contentRepository.loadCardsByIds(_savedIds);
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

  Future<void> onPageViewed(int index) async {
    final checkKey = '${_allItems.length}:$index';
    if (_isPrefetching ||
        index >= _allItems.length ||
        _prefetchChecks.contains(checkKey)) {
      return;
    }
    _prefetchChecks.add(checkKey);
    _isPrefetching = true;
    notifyListeners();
    try {
      final entries = await contentRepository.prefetchNearEnd(
        date: _now(),
        currentIndex: index,
      );
      if (entries.length != _allItems.length) {
        _applyDailyEntries(entries);
      }
    } finally {
      _isPrefetching = false;
      notifyListeners();
    }
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
    await contentRepository.completeCard(
      dateKey: _dateOnly(_now()),
      item: item,
      selectedAnswer: selectedOption,
    );
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
    _savedItems = await contentRepository.loadCardsByIds(_savedIds);
    notifyListeners();
    await _persist();
  }

  void _applyDailyEntries(List<DailyPackEntry> entries) {
    _allItems = entries.map((entry) => entry.item).toList(growable: false);
    _completedIds = {
      for (final entry in entries)
        if (entry.completed) entry.item.id,
    };
    _answers = {
      for (final entry in entries)
        if (entry.selectedAnswer != null) entry.item.id: entry.selectedAnswer!,
    };
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
