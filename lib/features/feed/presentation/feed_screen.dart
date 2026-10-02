import 'package:flutter/material.dart';
import 'package:momentum_learning_feed/core/theme/app_theme.dart';
import 'package:momentum_learning_feed/core/widgets/progress_ring.dart';
import 'package:momentum_learning_feed/features/feed/application/feed_controller.dart';
import 'package:momentum_learning_feed/features/feed/domain/learning_item.dart';
import 'package:momentum_learning_feed/features/feed/presentation/widgets/completion_card.dart';
import 'package:momentum_learning_feed/features/feed/presentation/widgets/learning_card.dart';
import 'package:momentum_learning_feed/features/feed/presentation/widgets/topic_filter_bar.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.controller});

  final FeedController controller;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final ScrollController _scrollController;
  final _cardKeys = <String, GlobalKey>{};
  final _endKey = GlobalKey();
  bool _showBackToTop = false;

  GlobalKey _keyFor(String id) => _cardKeys.putIfAbsent(id, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.offset > 720;
    if (show == _showBackToTop) return;
    setState(() => _showBackToTop = show);
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(microseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToKey(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectTopic(LearningTopic? topic) {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() => _showBackToTop = false);
    widget.controller.selectTopic(topic);
  }

  void _reviewFeed() => _selectTopic(null);

  void _openSavedItem(LearningItem item) {
    widget.controller.selectTopic(null);
    widget.controller.setNavigationIndex(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToKey(_keyFor(item.id));
    });
  }

  void _scrollToCard(int index) {
    final context = _cardKeys[index]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _answer(LearningItem item, int option) async {
    final earned = await widget.controller.completeItem(
      item,
      selectedOption: option,
    );
    if (!mounted || earned == 0) return;
    final isCorrect = option == item.correctOptionIndex;
    _showReward(
      isCorrect ? 'Correct · +$earned XP' : 'Good attempt · +$earned XP',
      isCorrect ? Icons.auto_awesome_rounded : Icons.psychology_alt_rounded,
    );
  }

  Future<void> _complete(LearningItem item) async {
    final earned = await widget.controller.completeItem(item);
    if (!mounted || earned == 0) return;
    _showReward('Locked in · +$earned XP', Icons.bolt_rounded);
  }

  void _showReward(String message, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          duration: const Duration(milliseconds: 1400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              Icon(icon, color: AppColors.lime),
              const SizedBox(width: 10),
              Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: controller.navigationIndex == 0
                    ? _buildFeed(controller)
                    : _SavedLessons(
                        items: controller.savedItems,
                        onRemove: controller.toggleSaved,
                        onBrowse: () => controller.setNavigationIndex(0),
                        onOpen: _openSavedItem,
                      ),
              ),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: controller.navigationIndex,
            onDestinationSelected: controller.setNavigationIndex,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dynamic_feed_outlined),
                selectedIcon: Icon(Icons.dynamic_feed_rounded),
                label: 'Learn',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_border_rounded),
                selectedIcon: Icon(Icons.bookmark_rounded),
                label: 'Saved',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeed(FeedController controller) {
    final items = controller.visibleItems;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.bolt_rounded, color: AppColors.lime),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  children: [
                    items.isEmpty
                        ? _EmptyFilter(
                            onReset: () => _selectTopic(null),
                            message: controller.catalogSyncError == null
                                ? null
                                : 'No cached cards are available. Connect once to download today`s pack.',
                          )
                        : NotificationListener<ScrollUpdateNotification>(
                            onNotification: (notification) {
                              final metrics = notification.metrics;
                              if (metrics.maxScrollExtent <= 0) return false;
                              final index =
                                  (metrics.pixels /
                                          metrics.maxScrollExtent *
                                          items.length)
                                      .floor()
                                      .clamp(0, items.length - 1);
                              controller.onPageViewed(index);
                              return false;
                            },
                            child: ListView.builder(
                              key: ValueKey(controller.selectedTopic),
                              controller: _scrollController,
                              padding: const EdgeInsets.only(bottom: 88),
                              itemCount: items.length + 1,
                              itemBuilder: (context, index) {
                                if (index == items.length) {
                                  final completedInFilter = items
                                      .where(
                                        (item) =>
                                            controller.isCompleted(item.id),
                                      )
                                      .length;
                                  return CompletionCard(
                                    completedCount: completedInFilter,
                                    totalCount: items.length,
                                    xp: controller.xp,
                                    onReview: _reviewFeed,
                                    onSaved: () =>
                                        controller.setNavigationIndex(1),
                                    key: _endKey,
                                  );
                                }
                                final item = items[index];
                                return LearningCard(
                                  item: item,
                                  isSaved: controller.isSaved(item.id),
                                  isCompleted: controller.isCompleted(item.id),
                                  selectedAnswer: controller.answerFor(item.id),
                                  onSaved: () =>
                                      controller.toggleSaved(item.id),
                                  onAnswer: (option) => _answer(item, option),
                                  onComplete: () => _complete(item),
                                  onNext: () => _scrollToKey(
                                    index + 1 == items.length
                                        ? _endKey
                                        : _keyFor(items[index + 1].id),
                                  ),
                                );
                              },
                            ),
                          ),
                    if (_showBackToTop)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.small(
                          onPressed: _scrollToTop,
                          heroTag: 'back-to-top',
                          tooltip: 'Back to top',
                          backgroundColor: AppColors.ink,
                          foregroundColor: AppColors.lime,
                          child: const Icon(Icons.arrow_upward_rounded),
                        ),
                      ),
                  ],
                ),
              ),
              _XpPill(xp: controller.xp),
              const SizedBox(width: 10),
              ProgressRing(
                progress: controller.dailyProgress,
                label: '${controller.completedCount}',
                size: 42,
              ),
            ],
          ),
        ),
        TopicFilterBar(
          selectedTopic: controller.selectedTopic,
          onSelected: _selectTopic,
        ),
        const SizedBox(height: 2),
        if (controller.isPrefetching)
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.ink,
            backgroundColor: Colors.transparent,
          ),
        Expanded(
          child: items.isEmpty
              ? _EmptyFilter(
                  onReset: () => _selectTopic(null),
                  message: controller.catalogSyncError == null ? null : 'No cached cards are available. Connect once to download today’s pack.',
                )
              : ListView.builder(
                  key: ValueKey(controller.selectedTopic),
                  controller: _scrollController,
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index < items.length) {
                      controller.onPageViewed(index);
                    }
                    if (index == items.length) {
                      final completedInFilter = items
                          .where((item) => controller.isCompleted(item.id))
                          .length;
                      return CompletionCard(
                        completedCount: completedInFilter,
                        totalCount: items.length,
                        xp: controller.xp,
                        onReview: _reviewFeed,
                        onSaved: () => controller.setNavigationIndex(1),
                      );
                    }
                    final item = items[index];
                    return LearningCard(
                      key: ValueKey(item.id),
                      item: item,
                      isSaved: controller.isSaved(item.id),
                      isCompleted: controller.isCompleted(item.id),
                      selectedAnswer: controller.answerFor(item.id),
                      onSaved: () => controller.toggleSaved(item.id),
                      onAnswer: (option) => _answer(item, option),
                      onComplete: () => _complete(item),
                      onNext: () => _scrollToCard(index + 1),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _XpPill extends StatelessWidget {
  const _XpPill({required this.xp});

  final int xp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, size: 17),
          const SizedBox(width: 3),
          Text(
            '$xp XP',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SavedLessons extends StatelessWidget {
  const _SavedLessons({
    required this.items,
    required this.onRemove,
    required this.onBrowse,
    required this.onOpen,
  });

  final List<LearningItem> items;
  final ValueChanged<String> onRemove;
  final VoidCallback onBrowse;
  final ValueChanged<LearningItem> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
          child: Text(
            'Saved lessons',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Your quick-reference shelf.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.lilac,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bookmark_add_outlined,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Nothing saved yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the bookmark on any card to keep it here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: onBrowse,
                          child: const Text('Browse today’s feed'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Material(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => onOpen(item),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: _topicColor(item.topic),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(_topicIcon(item.topic)),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.topic.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => onRemove(item.id),
                                tooltip: 'Remove bookmark',
                                icon: const Icon(Icons.bookmark_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static Color _topicColor(LearningTopic topic) => switch (topic) {
    LearningTopic.dsa => AppColors.mint,
    LearningTopic.functional => AppColors.lilac,
    LearningTopic.codeCraft => AppColors.peach,
  };

  static IconData _topicIcon(LearningTopic topic) => switch (topic) {
    LearningTopic.dsa => Icons.account_tree_rounded,
    LearningTopic.functional => Icons.functions_rounded,
    LearningTopic.codeCraft => Icons.code_rounded,
  };
}

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter({required this.onReset, this.message});

  final VoidCallback onReset;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt_off_rounded, size: 48),
          const SizedBox(height: 12),
          Text(
            message ?? 'No cards in this topic',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onReset, child: const Text('Show all')),
        ],
      ),
    );
  }
}
