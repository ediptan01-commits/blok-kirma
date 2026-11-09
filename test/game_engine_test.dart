import 'package:flutter_test/flutter_test.dart';
import 'package:blok_kirma/game_engine.dart';

void main() {
  test('Oyunda başlangıç blokları ve beş can bulunur', () {
    final game = BlockGame((_) {});
    expect(game.bricks.length, greaterThan(40));
    expect(game.lives, 5);
    expect(game.level, 1);
    expect(game.coins, 120);
    expect(game.phase, GamePhase.ready);
  });

  test('Oyun başlayınca otomatik ateş etmez', () {
    final game = BlockGame((_) {});
    game.phase = GamePhase.playing;
    game.tick(.35, left: false, right: false, fire: false);
    expect(game.shots, isEmpty);
  });

  test('Basılı tutarken ateş eder, bırakınca durur', () {
    final game = BlockGame((_) {});
    game.phase = GamePhase.playing;
    game.tick(.15, left: false, right: false, fire: true);
    expect(game.shots, isNotEmpty);
    final before = game.shots.length;
    game.tick(.02, left: false, right: false, fire: false);
    expect(game.shots.length, lessThanOrEqualTo(before));
  });

  test('İsteğe bağlı otomatik mod ateş eder', () {
    final game = BlockGame((_) {});
    game.phase = GamePhase.playing;
    game.auto = true;
    game.tick(.15, left: false, right: false, fire: false);
    expect(game.shots, isNotEmpty);
  });

  test('Yeni blok türleri sonraki bölümlerde açılır', () {
    final game = BlockGame((_) {});
    game.level = 2;game.bricks.clear();game.rowNumber=0;game.addRow(67);
    expect(game.bricks.any((b) => b.kind == BrickKind.armored), isTrue);
    game.level = 3;game.bricks.clear();game.rowNumber=0;game.addRow(67);
    expect(game.bricks.any((b) => b.kind == BrickKind.prism), isTrue);
    game.level = 4;game.bricks.clear();game.rowNumber=0;game.addRow(67);
    expect(game.bricks.any((b) => b.kind == BrickKind.column), isTrue);
  });

  test('Buz blokları ve dondurma kutuları kaldırılmıştır', () {
    expect(BrickKind.values.map((kind) => kind.name), isNot(contains('ice')));
    expect(DropKind.values.map((kind) => kind.name), isNot(contains('freeze')));
  });

  test('Beşinci bölümde boss savaşı çalışır', () {
    final game = BlockGame((_) {});
    game.bossDemo();
    expect(game.boss, isNotNull);
    expect(game.level, 5);
    expect(game.phase, GamePhase.playing);
  });

  test('Silah satın alınınca altın düşer', () {
    final game = BlockGame((_) {});
    expect(game.purchaseWeapon(Weapon.spread), isTrue);
    expect(game.coins, 30);
    expect(game.unlocked.contains(Weapon.spread), isTrue);
  });
}
