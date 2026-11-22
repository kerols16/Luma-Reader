import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/theme/reading_column.dart';
import 'package:luma/domain/entities/reader_settings.dart';

void main() {
  testWidgets('reading column is capped at 680 logical px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ReadingColumn(child: Text('page'))),
      ),
    );

    final box = tester.widget<ConstrainedBox>(
      find
          .descendant(
            of: find.byType(ReadingColumn),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    expect(box.constraints.maxWidth, 680);
  });

  testWidgets('reading column uses directional padding', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ReadingColumn(child: Text('page'))),
      ),
    );

    final padding = tester.widget<Padding>(
      find
          .descendant(
            of: find.byType(ReadingColumn),
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(padding.padding, isA<EdgeInsetsDirectional>());
  });

  testWidgets('reading text takes direction from its content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadingText(
            'مرحبا بالعالم',
            isArabic: true,
            settings: ReaderSettings(),
          ),
        ),
      ),
    );

    final direction = tester.widget<Directionality>(
      find
          .ancestor(
            of: find.text('مرحبا بالعالم'),
            matching: find.byType(Directionality),
          )
          .first,
    );
    final text = tester.widget<Text>(find.text('مرحبا بالعالم'));

    expect(direction.textDirection, TextDirection.rtl);
    expect(text.textAlign, TextAlign.start);
  });
}
