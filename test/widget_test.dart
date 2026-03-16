import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:datetime_demo/main.dart';

void main() {
  testWidgets('leave request example renders and can open picker', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('请假'), findsOneWidget);
    expect(find.text('请假类型'), findsOneWidget);
    expect(find.text('开始时间'), findsAtLeastNWidgets(1));
    expect(find.text('结束时间'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('开始时间').first);
    await tester.pumpAndSettle();

    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('提交'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('提交'));
    await tester.pump();

    expect(find.textContaining('已提交示例：'), findsOneWidget);
  });
}
