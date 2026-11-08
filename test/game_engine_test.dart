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

  test('Otomatik ateş mermi üretir', () {
    final game = BlockGame((_) {});
    game.phase = GamePhase.playing;
    game.auto = true;
    game.tick(.15, left: false, right: false, fire: false);
    expect(game.shots, isNotEmpty);
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
