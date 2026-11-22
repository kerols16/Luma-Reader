import 'package:luma/domain/planning/planning_models.dart';

String words(int count) => List.filled(count, 'word').join(' ');

PlanningChapter makeChapter(
  String id,
  List<int> paragraphWords, {
  int difficulty = 1,
  String sectionId = 'section',
  Set<int> headingIndexes = const {},
  String? title,
}) {
  return PlanningChapter(
    id: id,
    title: title ?? 'Chapter $id',
    sectionId: sectionId,
    difficulty: difficulty,
    paragraphs: [
      for (var index = 0; index < paragraphWords.length; index++)
        PlanningParagraph(
          words(paragraphWords[index]),
          isSubHeading: headingIndexes.contains(index),
        ),
    ],
  );
}
