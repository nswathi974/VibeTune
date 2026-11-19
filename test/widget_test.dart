import 'package:flutter_test/flutter_test.dart';
import 'package:vibetune/main.dart';
import 'package:vibetune/data/song_catalog.dart';

void main() {
  testWidgets('VibeTune basic smoke test', (WidgetTester tester) async {
    // Verify song catalog has verified songs
    expect(SongCatalog.allSongs.length, 10);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const VibeTuneApp());
    await tester.pump();

    // Verify VibeTune branding appears
    expect(find.text('VIBETUNE'), findsOneWidget);

    // Fast-forward through splash timer to avoid pending timers
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
