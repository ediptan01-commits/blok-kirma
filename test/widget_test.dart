import 'package:flutter_test/flutter_test.dart';
import 'package:blok_kirma/main.dart';

void main() {
  testWidgets('Blok Kırma açılış ekranı ve kontrolleri görünür', (tester) async {
    await tester.pumpWidget(const BlokKirmaApp());
    expect(find.text('BLOK KIRMA'), findsOneWidget);
    expect(find.text('▶ Başlat'), findsOneWidget);
    expect(find.text('🛒 Mağaza'), findsOneWidget);
  });
}
