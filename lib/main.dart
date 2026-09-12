import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/mario_game.dart';
import 'game/game_constants.dart';
import 'game/levels/level_data.dart';
import 'home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MarioApp());
}

class MarioApp extends StatelessWidget {
  const MarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Mario Adventure',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'monospace'),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    if (_playing) {
      return GameScreen(onHome: () => setState(() => _playing = false));
    }
    return HomeScreen(onPlay: () => setState(() => _playing = true));
  }
}

class GameScreen extends StatefulWidget {
  final VoidCallback? onHome;

  const GameScreen({super.key, this.onHome});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late MarioGame _game;

  @override
  void initState() {
    super.initState();
    _game = MarioGame();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;
    final safeBottom = mq.padding.bottom;

    final btnSize = (screenH * 0.10).clamp(40.0, 68.0);
    final edgePad = (screenW * 0.02).clamp(8.0, 20.0);
    final bottomPad = safeBottom + (screenH * 0.02).clamp(6.0, 16.0);
    final btnGap = (screenW * 0.015).clamp(4.0, 12.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget(
              game: _game,
              overlayBuilderMap: {
                'GameOver': (ctx, game) => _gameOverOverlay(),
                'Win': (ctx, game) => _winOverlay(),
                'Paused': (ctx, game) => _pausedOverlay(),
                'LevelComplete': (ctx, game) => _levelCompleteOverlay(),
                'TunnelEnter': (ctx, game) => _tunnelOverlay(),
                'TunnelScreen': (ctx, game) => _tunnelScreen(),
              },
            ),
          ),
          Positioned(
            bottom: bottomPad,
            left: edgePad,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _btn(Icons.arrow_left_rounded, Colors.blue, btnSize,
                    onDown: () => _game.moveLeft(true),
                    onUp: () => _game.moveLeft(false)),
                SizedBox(width: btnGap),
                _btn(Icons.arrow_right_rounded, Colors.blue, btnSize,
                    onDown: () => _game.moveRight(true),
                    onUp: () => _game.moveRight(false)),
              ],
            ),
          ),
          Positioned(
            bottom: bottomPad,
            left: screenW / 2 - btnSize / 2,
            child: _btn(
              Icons.keyboard_arrow_down_rounded,
              Colors.green,
              btnSize,
              onDown: () => _game.tryEnterTunnel(),
              onUp: null,
            ),
          ),
          Positioned(
            bottom: bottomPad,
            right: edgePad,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _btn(Icons.keyboard_arrow_up_rounded, Colors.red, btnSize,
                    onDown: () => _game.jump(), onUp: null),
                SizedBox(width: btnGap),
                _btn(Icons.radio_button_checked, Colors.orange, btnSize,
                    onDown: () => _game.shoot(), onUp: null),
                SizedBox(width: btnGap),
                _btn(Icons.pause_rounded, Colors.grey.shade600, btnSize,
                    onDown: () => _game.togglePause(), onUp: null),
              ],
            ),
          ),
          Positioned(
            top: mq.padding.top + 4,
            right: edgePad,
            child: GestureDetector(
              onTap: () {
                _game.pauseEngine();
                widget.onHome?.call();
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (screenW * 0.02).clamp(8.0, 14.0),
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(((0.65) * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white38, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded,
                        color: Colors.white,
                        size: (screenH * 0.025).clamp(14.0, 20.0)),
                    const SizedBox(width: 4),
                    Text('HOME',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (screenH * 0.018).clamp(10.0, 14.0),
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, Color color, double size,
      {required VoidCallback onDown, required VoidCallback? onUp}) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: onUp != null ? (_) => onUp() : null,
      onTapCancel: onUp,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withAlpha(((0.75) * 255).round()),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
                color: color.withAlpha(((0.4) * 255).round()), blurRadius: 8)
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }

  Widget _tunnelScreen() {
    return _TunnelScreenWidget(
      game: _game,
      onExit: (coinsCollected) {
        _game.overlays.remove('TunnelScreen');
        _game.exitTunnel(coinsCollected);
      },
    );
  }

  Widget _tunnelOverlay() {
    return Center(
      child: _overlayBox(
        borderColor: Colors.green,
        children: [
          const Text('🌿 SECRET TUNNEL!',
              style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Press ↓ to enter\nCoins & 1-UP inside!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _overlayBtn('ENTER ↓', Colors.green, () {
                _game.overlays.remove('TunnelEnter');
                _game.enterTunnel();
              }),
              const SizedBox(width: 12),
              _overlayBtn('SKIP', Colors.grey, () {
                _game.overlays.remove('TunnelEnter');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gameOverOverlay() {
    return Center(
      child: _overlayBox(
        borderColor: Colors.red,
        children: [
          const Text('GAME OVER',
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 44,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Score: ${_game.score}',
              style: const TextStyle(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 24),
          _overlayBtn('PLAY AGAIN', Colors.red, () {
            _game.overlays.remove('GameOver');
            _game.restartGame();
          }),
        ],
      ),
    );
  }

  Widget _winOverlay() {
    return Center(
      child: _overlayBox(
        borderColor: Colors.yellow,
        children: [
          const Text('YOU WIN! 🎉',
              style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 44,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Final Score: ${_game.score}',
              style: const TextStyle(color: Colors.white, fontSize: 22)),
          Text('Coins: ${_game.coins} 🪙',
              style: const TextStyle(color: Colors.yellow, fontSize: 18)),
          const SizedBox(height: 24),
          _overlayBtn('PLAY AGAIN', Colors.green, () {
            _game.overlays.remove('Win');
            _game.restartGame();
          }),
        ],
      ),
    );
  }

  Widget _pausedOverlay() {
    return Center(
      child: _overlayBox(
        borderColor: Colors.white,
        children: [
          const Text('PAUSED ⏸',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Level ${_game.currentLevel}/50 • Score: ${_game.score}',
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 24),
          _overlayBtn('RESUME', Colors.blue, () => _game.togglePause()),
          const SizedBox(height: 12),
          _overlayBtn('RESTART', Colors.orange, () {
            _game.overlays.remove('Paused');
            _game.resumeEngine();
            _game.restartGame();
          }),
          const SizedBox(height: 12),
          _overlayBtn('🏠 HOME', Colors.grey, () {
            _game.overlays.remove('Paused');
            _game.resumeEngine();
            widget.onHome?.call();
          }),
        ],
      ),
    );
  }

  Widget _levelCompleteOverlay() {
    final level = _game.currentLevel;
    final prevName = LevelData.levels[(level - 2).clamp(0, 49)].name;
    final nextName = level <= GameConstants.totalLevels
        ? LevelData.levels[(level - 1).clamp(0, 49)].name
        : 'Final Level Complete!';
    return Center(
      child: _overlayBox(
        borderColor: Colors.green,
        children: [
          const Text('LEVEL CLEAR! ✅',
              style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 38,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(prevName,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Text('Score: ${_game.score}',
              style: const TextStyle(color: Colors.yellow, fontSize: 20)),
          const SizedBox(height: 6),
          Text('Next: $nextName',
              style:
                  const TextStyle(color: Colors.lightBlueAccent, fontSize: 15)),
          const SizedBox(height: 24),
          _overlayBtn(
              'NEXT LEVEL ▶', Colors.green, () => _game.startNextLevel()),
        ],
      ),
    );
  }

  Widget _overlayBox(
      {required Color borderColor, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(((0.88) * 255).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
              color: borderColor.withAlpha(((0.3) * 255).round()),
              blurRadius: 20)
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _overlayBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: color.withAlpha(((0.4) * 255).round()), blurRadius: 8)
          ],
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _TunnelItem {
  Offset pos;
  final bool isOneUp;
  bool collected = false;
  _TunnelItem({required this.pos, required this.isOneUp});
}

class _TunnelScreenWidget extends StatefulWidget {
  final MarioGame game;
  final void Function(int coinsCollected) onExit;

  const _TunnelScreenWidget({required this.game, required this.onExit});

  @override
  State<_TunnelScreenWidget> createState() => _TunnelScreenState();
}

class _TunnelScreenState extends State<_TunnelScreenWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static const double W = 760;
  static const double H = 280;

  Offset _playerPos = const Offset(60, 180);
  Offset _playerVel = Offset.zero;
  bool _onGround = false;
  bool _facingRight = true;

  late List<_TunnelItem> _items;
  int _collected = 0;
  bool _gotOneUp = false;

  final List<Rect> _platforms = [
    const Rect.fromLTWH(0, 216, 760, 64),
    const Rect.fromLTWH(0, 0, 760, 32),
    const Rect.fromLTWH(0, 32, 32, 184),
    const Rect.fromLTWH(728, 32, 32, 184),
    const Rect.fromLTWH(160, 152, 192, 16),
    const Rect.fromLTWH(400, 120, 128, 16),
    const Rect.fromLTWH(560, 152, 128, 16),
  ];

  bool _leftHeld = false;
  bool _rightHeld = false;

  @override
  void initState() {
    super.initState();
    _buildItems();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )
      ..addListener(_tick)
      ..repeat();
  }

  void _buildItems() {
    _items = [];
    final coinCount = widget.game.tunnelCoins;
    final hasOneUp = widget.game.tunnelHasOneUp;

    final coinSpots = [
      const Offset(120, 180),
      const Offset(180, 180),
      const Offset(240, 130),
      const Offset(300, 130),
      const Offset(360, 180),
      const Offset(420, 180),
      const Offset(460, 95),
      const Offset(500, 95),
      const Offset(540, 130),
      const Offset(600, 130),
      const Offset(640, 180),
      const Offset(680, 180),
      const Offset(150, 130),
      const Offset(390, 95),
      const Offset(570, 180),
    ];
    for (int i = 0; i < coinCount && i < coinSpots.length; i++) {
      _items.add(_TunnelItem(pos: coinSpots[i], isOneUp: false));
    }
    if (hasOneUp) {
      _items.add(_TunnelItem(pos: const Offset(380, 90), isOneUp: true));
    }
  }

  void _tick() {
    if (!mounted) return;
    const double dt = 0.016;
    const double gravity = 900;
    const double speed = 180;
    const double pW = 36, pH = 48;

    double vx = _playerVel.dx;
    double vy = _playerVel.dy + gravity * dt;
    double px = _playerPos.dx;
    double py = _playerPos.dy;

    if (_leftHeld) {
      vx = -speed;
      _facingRight = false;
    }
    if (_rightHeld) {
      vx = speed;
      _facingRight = true;
    }
    if (!_leftHeld && !_rightHeld) {
      vx = 0;
    }

    px += vx * dt;
    py += vy * dt;

    bool onGround = false;
    for (final plat in _platforms) {
      final pRect = Rect.fromLTWH(px, py, pW, pH);
      if (!pRect.overlaps(plat)) continue;
      final ox = _overlapX(pRect, plat);
      final oy = _overlapY(pRect, plat);
      if (oy.abs() < ox.abs()) {
        py += oy;
        if (oy < 0) {
          vy = 0;
          onGround = true;
        } else if (vy < 0) {
          vy = 0;
        }
      } else {
        px += ox;
        vx = 0;
      }
    }

    final playerRect = Rect.fromLTWH(px, py, pW, pH);
    for (final item in _items) {
      if (item.collected) continue;
      final iRect = Rect.fromLTWH(item.pos.dx - 14, item.pos.dy - 14, 28, 28);
      if (playerRect.overlaps(iRect)) {
        item.collected = true;
        if (item.isOneUp) {
          _gotOneUp = true;
          widget.game.gainLife();
          widget.game.hud?.showMessage('1-UP! ❤️ (Tunnel Bonus)');
        } else {
          _collected++;
        }
      }
    }

    if (px > 680) {
      _ctrl.stop();
      widget.onExit(_collected);
      return;
    }

    setState(() {
      _playerPos = Offset(px, py);
      _playerVel = Offset(vx, vy);
      _onGround = onGround;
    });
  }

  double _overlapX(Rect a, Rect b) {
    final cAX = a.left + a.width / 2;
    final cBX = b.left + b.width / 2;
    final ov = (a.width + b.width) / 2 - (cAX - cBX).abs();
    return cAX < cBX ? -ov : ov;
  }

  double _overlapY(Rect a, Rect b) {
    final cAY = a.top + a.height / 2;
    final cBY = b.top + b.height / 2;
    final ov = (a.height + b.height) / 2 - (cAY - cBY).abs();
    return cAY < cBY ? -ov : ov;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(((0.92) * 255).round()),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A00),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌿 SECRET TUNNEL  ',
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('Coins: $_collected  ',
                      style:
                          const TextStyle(color: Colors.yellow, fontSize: 16)),
                  if (_gotOneUp)
                    const Text('1-UP! ❤️',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  const Text('  → Reach EXIT pipe →',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: W,
              height: H,
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A00),
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CustomPaint(
                  painter: _TunnelPainter(
                    playerPos: _playerPos,
                    facingRight: _facingRight,
                    items: _items,
                    platforms: _platforms,
                    time: _ctrl.value * 100,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tBtn(Icons.arrow_left_rounded, Colors.blue,
                    onDown: () => setState(() => _leftHeld = true),
                    onUp: () => setState(() => _leftHeld = false)),
                const SizedBox(width: 8),
                _tBtn(Icons.arrow_right_rounded, Colors.blue,
                    onDown: () => setState(() => _rightHeld = true),
                    onUp: () => setState(() => _rightHeld = false)),
                const SizedBox(width: 24),
                _tBtn(Icons.keyboard_arrow_up_rounded, Colors.red, onDown: () {
                  if (_onGround) {
                    setState(() => _playerVel = Offset(_playerVel.dx, -420));
                  }
                }, onUp: null),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    _ctrl.stop();
                    widget.onExit(_collected);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('EXIT TUNNEL',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tBtn(IconData icon, Color color,
      {required VoidCallback onDown, required VoidCallback? onUp}) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: onUp != null ? (_) => onUp() : null,
      onTapCancel: onUp,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withAlpha(((0.8) * 255).round()),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _TunnelPainter extends CustomPainter {
  final Offset playerPos;
  final bool facingRight;
  final List<_TunnelItem> items;
  final List<Rect> platforms;
  final double time;

  _TunnelPainter({
    required this.playerPos,
    required this.facingRight,
    required this.items,
    required this.platforms,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF1A0A00));

    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(80 + i * 180.0, 200),
        35 + sin(time * 0.3 + i) * 4,
        Paint()..color = Colors.orange.withAlpha(((0.07) * 255).round()),
      );
    }

    for (final p in platforms) {
      canvas.drawRect(p, Paint()..color = const Color(0xFF555555));
      canvas.drawRect(
        Rect.fromLTWH(p.left, p.top, p.width, 10),
        Paint()..color = const Color(0xFF888888),
      );
      canvas.drawRect(
          p,
          Paint()
            ..color = Colors.black.withAlpha(((0.2) * 255).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }

    for (int i = 0; i < 4; i++) {
      final tx = 80.0 + i * 180;
      canvas.drawRect(Rect.fromLTWH(tx - 2, 200, 4, 16),
          Paint()..color = const Color(0xFF8B4513));
      canvas.drawOval(
        Rect.fromLTWH(tx - 6, 190 + sin(time * 0.8 + i) * 2, 12, 14),
        Paint()..color = Colors.orange.withAlpha(((0.9) * 255).round()),
      );
      canvas.drawOval(
        Rect.fromLTWH(tx - 3, 192 + sin(time * 0.8 + i) * 2, 6, 8),
        Paint()..color = Colors.yellow,
      );
    }

    const exitX = 720.0;
    canvas.drawRect(const Rect.fromLTWH(exitX, 120, 72, 96),
        Paint()..color = const Color(0xFF2ECC40));
    canvas.drawRect(const Rect.fromLTWH(exitX - 4, 116, 80, 20),
        Paint()..color = const Color(0xFF2ECC40));

    if ((time * 0.3).toInt() % 2 == 0) {
      final ap = Paint()..color = Colors.yellow;
      final path = Path()
        ..moveTo(exitX + 36, 140)
        ..lineTo(exitX + 20, 158)
        ..lineTo(exitX + 28, 158)
        ..lineTo(exitX + 28, 170)
        ..lineTo(exitX + 44, 170)
        ..lineTo(exitX + 44, 158)
        ..lineTo(exitX + 52, 158)
        ..close();
      canvas.drawPath(path, ap);
    }

    final tp2 = TextPainter(
      text: const TextSpan(
          text: 'EXIT↑',
          style: TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    tp2.layout();
    tp2.paint(canvas, Offset(exitX + 36 - tp2.width / 2, 104));

    for (final item in items) {
      if (item.collected) continue;
      if (item.isOneUp) {
        final cap = Paint()..color = const Color(0xFF4CAF50);
        final stem = Paint()..color = const Color(0xFFFAD7A0);
        canvas.drawRect(
            Rect.fromLTWH(item.pos.dx - 8, item.pos.dy + 4, 16, 12), stem);
        final capPath = Path()
          ..moveTo(item.pos.dx - 14, item.pos.dy + 4)
          ..quadraticBezierTo(
              item.pos.dx, item.pos.dy - 10, item.pos.dx + 14, item.pos.dy + 4)
          ..close();
        canvas.drawPath(capPath, cap);
        canvas.drawCircle(Offset(item.pos.dx - 6, item.pos.dy - 2), 3,
            Paint()..color = Colors.white);
        canvas.drawCircle(Offset(item.pos.dx + 6, item.pos.dy - 2), 3,
            Paint()..color = Colors.white);
        canvas.drawCircle(item.pos, 18 + sin(time * 0.4) * 2,
            Paint()..color = Colors.green.withAlpha(((0.2) * 255).round()));
      } else {
        final scaleX = ((time * 0.04) % 2 < 1)
            ? (time * 0.04 % 1).clamp(0.1, 1.0)
            : (1 - time * 0.04 % 1).clamp(0.1, 1.0);
        canvas.save();
        canvas.translate(item.pos.dx, item.pos.dy);
        canvas.scale(scaleX, 1.0);
        canvas.drawCircle(
            Offset.zero, 12, Paint()..color = const Color(0xFFE8A838));
        canvas.drawCircle(
            Offset.zero, 8, Paint()..color = const Color(0xFFF5D76E));
        canvas.restore();
      }
    }

    canvas.save();
    if (!facingRight) {
      canvas.translate(playerPos.dx + 36, playerPos.dy);
      canvas.scale(-1, 1);
      canvas.translate(-playerPos.dx, -playerPos.dy);
    }
    final px = playerPos.dx, py = playerPos.dy;
    canvas.drawRect(Rect.fromLTWH(px + 4, py, 28, 8),
        Paint()..color = const Color(0xFFE52521));
    canvas.drawRect(Rect.fromLTWH(px, py + 6, 36, 5),
        Paint()..color = const Color(0xFFE52521));
    canvas.drawRect(Rect.fromLTWH(px + 4, py + 11, 28, 14),
        Paint()..color = const Color(0xFFFAD7A0));
    canvas.drawRect(
        Rect.fromLTWH(px + 8, py + 13, 5, 5), Paint()..color = Colors.white);
    canvas.drawRect(
        Rect.fromLTWH(px + 22, py + 13, 5, 5), Paint()..color = Colors.white);
    canvas.drawRect(
        Rect.fromLTWH(px + 9, py + 14, 3, 3), Paint()..color = Colors.black);
    canvas.drawRect(
        Rect.fromLTWH(px + 23, py + 14, 3, 3), Paint()..color = Colors.black);
    canvas.drawRect(Rect.fromLTWH(px + 6, py + 19, 24, 3),
        Paint()..color = const Color(0xFF8B4513));
    canvas.drawRect(Rect.fromLTWH(px + 3, py + 25, 30, 16),
        Paint()..color = const Color(0xFF1A5276));
    canvas.drawRect(Rect.fromLTWH(px + 3, py + 38, 11, 6),
        Paint()..color = const Color(0xFF8B4513));
    canvas.drawRect(Rect.fromLTWH(px + 22, py + 38, 11, 6),
        Paint()..color = const Color(0xFF8B4513));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TunnelPainter old) => true;
}
