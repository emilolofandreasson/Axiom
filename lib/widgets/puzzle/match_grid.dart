import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../../core/theme/app_theme.dart';
import '../../models/puzzle_level.dart';
import 'particle_burst.dart';

// ---------------------------------------------------------------------------
// Internal tile model
// ---------------------------------------------------------------------------

enum _TileState { idle, selected, matched, wrong }

class _GridTile {
  _GridTile({
    required this.pairId,
    required this.text,
    required this.isTarget,
  });

  final String pairId;
  final String text;
  final bool isTarget; // true = target language (e.g. Spanish)
  _TileState state = _TileState.idle;
  int stateVersion = 0; // incremented to re-trigger flutter_animate keys
}

// ---------------------------------------------------------------------------
// MatchGrid
// ---------------------------------------------------------------------------

class MatchGrid extends StatefulWidget {
  const MatchGrid({
    super.key,
    required this.level,
    required this.onLevelComplete,
    required this.onRetry,
    required this.revealCount,
    required this.onUseReveal,
  });

  final PuzzleLevel level;
  final void Function(int timeSeconds) onLevelComplete;
  final VoidCallback onRetry;
  final int revealCount;
  final VoidCallback onUseReveal;

  @override
  State<MatchGrid> createState() => _MatchGridState();
}

class _MatchGridState extends State<MatchGrid> {
  late List<_GridTile> _tiles;
  _GridTile? _selected;
  int _matchedPairs = 0;

  DateTime? _levelStart;
  DateTime? _firstTapAt;

  // Active particle burst positions (one per matched pair)
  final List<_BurstEntry> _bursts = [];

  bool _isRevealed = false;
  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    _buildTiles();
    _levelStart = DateTime.now();
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  void _buildTiles() {
    final src = widget.level.pairs;
    _tiles = [
      for (final p in src) ...[
        _GridTile(pairId: p.id, text: p.sourceWord, isTarget: false),
        _GridTile(pairId: p.id, text: p.targetWord,  isTarget: true),
      ],
    ]..shuffle(Random());
  }

  void _handleTap(_GridTile tile) {
    if (tile.state == _TileState.matched || tile.state == _TileState.wrong) {
      return;
    }

    if (_selected == tile) {
      setState(() {
        tile.state = _TileState.idle;
        tile.stateVersion++;
        _selected = null;
      });
      return;
    }

    if (_selected == null) {
      _firstTapAt = DateTime.now();
      setState(() {
        tile.state = _TileState.selected;
        tile.stateVersion++;
        _selected = tile;
      });
      return;
    }

    // — Second tap: evaluate —
    final first    = _selected!;
    final timeMs   = DateTime.now().difference(_firstTapAt!).inMilliseconds;
    final isMatch  = first.pairId == tile.pairId && first.isTarget != tile.isTarget;

    EventSensor.instance.emit('match_attempted', {
      'lesson_id':        widget.level.id,
      'pair_id':          tile.pairId,
      'is_correct':       isMatch,
      'time_to_match_ms': timeMs,
    });

    if (isMatch) {
      HapticFeedback.mediumImpact();
      setState(() {
        first.state = _TileState.matched;
        first.stateVersion++;
        tile.state  = _TileState.matched;
        tile.stateVersion++;
        _selected   = null;
        _matchedPairs++;
        _bursts.add(_BurstEntry(id: '${tile.pairId}-${DateTime.now().microsecondsSinceEpoch}'));
      });

      if (_matchedPairs == widget.level.pairs.length) {
        final elapsed = DateTime.now().difference(_levelStart!).inSeconds;
        Future.delayed(const Duration(milliseconds: 700),
            () => widget.onLevelComplete(elapsed));
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        first.state = _TileState.wrong;
        first.stateVersion++;
        tile.state  = _TileState.wrong;
        tile.stateVersion++;
        _selected   = null;
      });

      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        setState(() {
          if (first.state == _TileState.wrong) {
            first.state = _TileState.idle;
            first.stateVersion++;
          }
          if (tile.state == _TileState.wrong) {
            tile.state = _TileState.idle;
            tile.stateVersion++;
          }
        });
      });
    }
  }

  void _activateReveal() {
    if (_isRevealed || widget.revealCount <= 0) return;
    widget.onUseReveal();
    EventSensor.instance.emit('powerup_used', {
      'lesson_id':    widget.level.id,
      'powerup_type': 'reveal',
    });
    setState(() => _isRevealed = true);
    _revealTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _isRevealed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Powerup row
        Align(
          alignment: Alignment.centerRight,
          child: _RevealButton(
            count:    widget.revealCount,
            active:   _isRevealed,
            onTap:    _activateReveal,
          ),
        ),

        const SizedBox(height: 12),

        // Grid
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:   3,
                  mainAxisSpacing:  8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.4,
                ),
                itemCount: _tiles.length,
                itemBuilder: (_, i) {
                  final tile = _tiles[i];
                  return _MatchTile(
                    key:        ValueKey('${tile.pairId}-${tile.isTarget}-${tile.stateVersion}'),
                    tile:       tile,
                    isRevealed: _isRevealed,
                    onTap:      () => _handleTap(tile),
                  );
                },
              ),

              // Particle bursts
              for (final burst in _bursts)
                ParticleBurst(
                  key:        ValueKey(burst.id),
                  color:      FlickColors.primary,
                  onComplete: () {
                    if (mounted) setState(() => _bursts.remove(burst));
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BurstEntry {
  const _BurstEntry({required this.id});
  final String id;
}

// ---------------------------------------------------------------------------
// Individual tile
// ---------------------------------------------------------------------------

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    super.key,
    required this.tile,
    required this.isRevealed,
    required this.onTap,
  });

  final _GridTile tile;
  final bool isRevealed;
  final VoidCallback onTap;

  static const _revealPalette = [
    Color(0xFFFFE0B2), // orange tint
    Color(0xFFE1BEE7), // purple tint
    Color(0xFFB2EBF2), // teal tint
    Color(0xFFF8BBD9), // pink tint
    Color(0xFFFFF9C4), // amber tint
    Color(0xFFC5CAE9), // indigo tint
  ];

  Color _bg() => switch (tile.state) {
    _TileState.selected => FlickColors.primary,
    _TileState.matched  => FlickColors.success,
    _TileState.wrong    => FlickColors.error,
    _TileState.idle     => isRevealed
        ? _revealPalette[tile.pairId.hashCode.abs() % _revealPalette.length]
        : FlickColors.surface,
  };

  Color _fg() => switch (tile.state) {
    _TileState.idle     => FlickColors.textPrimary,
    _               => Colors.white,
  };

  @override
  Widget build(BuildContext context) {
    final isWrong   = tile.state == _TileState.wrong;
    final isMatched = tile.state == _TileState.matched;

    Widget body = GestureDetector(
      onTap: tile.state == _TileState.matched ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity:  isMatched ? 0.0 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve:    Curves.easeOut,
          decoration: BoxDecoration(
            color:        _bg(),
            borderRadius: const BorderRadius.all(FlickRadius.md),
            border: Border.all(
              color: tile.state == _TileState.selected
                  ? FlickColors.primary
                  : tile.state == _TileState.wrong
                      ? FlickColors.error
                      : FlickColors.border,
              width: tile.state == _TileState.selected ? 2 : 1,
            ),
            boxShadow: tile.state == _TileState.selected
                ? [BoxShadow(
                    color:       FlickColors.primary.withValues(alpha: 0.28),
                    blurRadius:  12,
                    spreadRadius: 1,
                  )]
                : null,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                tile.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color:      _fg(),
                      fontWeight: FontWeight.w600,
                      fontSize:   13,
                    ),
              ),
            ),
          ),
        ),
      ),
    );

    if (isWrong) {
      body = body
          .animate()
          .custom(
            duration: 400.ms,
            builder:  (_, v, child) => Transform.translate(
              offset: Offset(sin(v * pi * 5) * 5, 0),
              child:  child,
            ),
          );
    } else if (tile.state == _TileState.selected) {
      body = body
          .animate()
          .scale(
            begin:    const Offset(0.93, 0.93),
            end:      const Offset(1.0, 1.0),
            duration: 150.ms,
            curve:    Curves.easeOut,
          );
    }

    return body;
  }
}

// ---------------------------------------------------------------------------
// Reveal powerup button
// ---------------------------------------------------------------------------

class _RevealButton extends StatelessWidget {
  const _RevealButton({
    required this.count,
    required this.active,
    required this.onTap,
  });

  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = count > 0 && !active;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? FlickColors.primary
              : enabled
                  ? FlickColors.primaryDim
                  : FlickColors.surfaceDim,
          borderRadius: const BorderRadius.all(FlickRadius.full),
          border: Border.all(
            color: enabled || active ? FlickColors.primary : FlickColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_rounded,
              size:  14,
              color: active || enabled
                  ? FlickColors.primary
                  : FlickColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              active ? 'Revealing…' : 'Reveal  ×$count',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: active || enabled
                        ? FlickColors.primary
                        : FlickColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
