import 'package:momentum_learning_feed/features/feed/domain/learning_item.dart';

class LearningContentRepository {
  const LearningContentRepository();

  List<LearningItem> get dailyItems => const [
    LearningItem(
      id: 'dsa-hash-map',
      topic: LearningTopic.dsa,
      type: LearningItemType.concept,
      title: 'Trade memory for speed',
      body: 'A hash map turns repeated lookups into near-instant checks. In Two Sum, store each number as you scan and ask whether its complement is already present.',
      code: '''for (final n in nums) {
  if (seen.containsKey(target - n)) return true;
  seen[n] = true;
}''',
      takeaway:
          'Use a hash map when you keep searching for things you have seen.',
    ),
    LearningItem(
      id: 'craft-null-aware',
      topic: LearningTopic.codeCraft,
      type: LearningItemType.codeTip,
      title: 'Replace a branch with ??',
      body: 'Null-aware operators make defaults explicit and keep the useful value in focus.',
      code: '''// Noisy
final name = user.name != null ? user.name! : 'Guest';

// Clear
final name = user.name ?? 'Guest';''',
      takeaway:
          'Prefer the smallest expression that still communicates intent.',
    ),
    LearningItem(
      id: 'dsa-binary-search',
      topic: LearningTopic.dsa,
      type: LearningItemType.quiz,
      title: 'When does binary search fit?',
      body: 'You need to find a value in a collection. Which condition makes classic binary search valid?',
      options: [
        'The collection is sorted',
        'The collection has unique values',
        'The collection is a linked list',
      ],
      correctOptionIndex: 0,
      takeaway: 'Binary search relies on sorted order so every comparison can discard half the search space.',
    ),
    LearningItem(
      id: 'functional-pure',
      topic: LearningTopic.functional,
      type: LearningItemType.concept,
      title: 'Pure functions are predictable',
      body: 'A pure function returns the same output for the same input and changes nothing outside itself. That makes it easy to test, cache, and run in parallel.',
      code: '''int totalWithTax(int cents, double rate) {
  return (cents * (1 + rate)).round();
}''',
      takeaway: 'Push side effects to the edges; keep business rules pure.',
    ),
    LearningItem(
      id: 'craft-async-bug',
      topic: LearningTopic.codeCraft,
      type: LearningItemType.bugHunt,
      title: 'Why does this finish too early?',
      body: 'The function prints “done” before every save completes. Pick the cause.',
      code: '''items.forEach((item) async {
  await save(item);
});
print('done');''',
      options: [
        'forEach does not await async callbacks',
        'save must return void',
        'print always runs asynchronously',
      ],
      correctOptionIndex: 0,
      takeaway: 'Use a for-in loop with await, or Future.wait when operations may run concurrently.',
    ),
    LearningItem(
      id: 'dsa-stack',
      topic: LearningTopic.dsa,
      type: LearningItemType.quiz,
      title: 'Choose the right structure',
      body: 'An editor needs an Undo feature. Which structure naturally restores the most recent action first?',
      options: ['Queue', 'Stack', 'Heap'],
      correctOptionIndex: 1,
      takeaway:
          'A stack is LIFO: the last action added is the first one removed.',
    ),
    LearningItem(
      id: 'functional-map',
      topic: LearningTopic.functional,
      type: LearningItemType.codeTip,
      title: 'Transform without bookkeeping',
      body: 'Use map when every input becomes one output. It separates the transformation from iteration details.',
      code: '''final labels = users
    .map((user) => user.displayName)
    .toList();''',
      takeaway: 'Map answers “what should each item become?”',
    ),
    LearningItem(
      id: 'dsa-complexity',
      topic: LearningTopic.dsa,
      type: LearningItemType.quiz,
      title: 'Read the nested loop',
      body: 'A loop visits every pair of n items. What is its time complexity?',
      code: '''for (var i = 0; i < n; i++) {
  for (var j = 0; j < n; j++) {
    compare(i, j);
  }
}''',
      options: ['O(n)', 'O(log n)', 'O(n²)'],
      correctOptionIndex: 2,
      takeaway: 'n iterations multiplied by n iterations gives n² operations.',
    ),
    LearningItem(
      id: 'craft-early-return',
      topic: LearningTopic.codeCraft,
      type: LearningItemType.codeTip,
      title: 'Flatten code with guard clauses',
      body: 'Handle invalid or uninteresting cases first. The happy path stays unindented and easier to scan.',
      code: '''Result checkout(Cart cart) {
  if (cart.isEmpty) return Result.empty();
  if (!cart.isValid) return Result.invalid();

  return charge(cart);
}''',
      takeaway: 'Early returns reduce nesting and expose the main flow.',
    ),
    LearningItem(
      id: 'functional-immutability',
      topic: LearningTopic.functional,
      type: LearningItemType.quiz,
      title: 'Why favor immutable data?',
      body: 'What is the biggest day-to-day benefit of creating a changed copy instead of mutating shared data?',
      options: [
        'Every operation uses less memory',
        'State changes become easier to reason about',
        'The compiler removes all runtime errors',
      ],
      correctOptionIndex: 1,
      takeaway: 'Immutable values prevent distant code from changing data behind your back.',
    ),
  ];
}
