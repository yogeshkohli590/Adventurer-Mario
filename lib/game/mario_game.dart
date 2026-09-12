import 'package:flame/game.dart';

class MarioGame extends FlameGame {
  int score = 0;
  int coins = 0;
  int currentLevel = 1;
  int tunnelCoins = 0;
  bool tunnelHasOneUp = false;
  dynamic hud;

  void moveLeft(bool pressed) {}
  void moveRight(bool pressed) {}
  void jump() {}
  void shoot() {}
  void tryEnterTunnel() {}
  void togglePause() {}
  void restartGame() {}
  void startNextLevel() {}
  void pauseEngine() {}
  void resumeEngine() {}
  void exitTunnel(int coinsCollected) {}
  void enterTunnel() {}
  void gainLife() {}
}
