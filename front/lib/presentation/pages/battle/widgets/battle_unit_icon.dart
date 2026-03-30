import 'package:flutter/material.dart';

class BattleUnitIconPreset {
  final String key;
  final String label;
  final IconData iconData;
  final double iconScale;

  const BattleUnitIconPreset({
    required this.key,
    required this.label,
    required this.iconData,
    required this.iconScale,
  });
}

class BattleUnitIcon extends StatelessWidget {
  static const List<BattleUnitIconPreset> presets = <BattleUnitIconPreset>[
    BattleUnitIconPreset(
      key: 'soldier',
      label: 'Soldier',
      iconData: Icons.shield_rounded,
      iconScale: 0.62,
    ),
    BattleUnitIconPreset(
      key: 'ranged',
      label: 'Ranged',
      iconData: Icons.gps_fixed_rounded,
      iconScale: 0.58,
    ),
    BattleUnitIconPreset(
      key: 'healer',
      label: 'Healer',
      iconData: Icons.favorite_rounded,
      iconScale: 0.55,
    ),
    BattleUnitIconPreset(
      key: 'banner',
      label: 'Banner',
      iconData: Icons.flag_rounded,
      iconScale: 0.56,
    ),
    BattleUnitIconPreset(
      key: 'mage',
      label: 'Mage',
      iconData: Icons.auto_fix_high_rounded,
      iconScale: 0.56,
    ),
    BattleUnitIconPreset(
      key: 'beast',
      label: 'Beast',
      iconData: Icons.pets_rounded,
      iconScale: 0.56,
    ),
  ];

  final String iconKey;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  const BattleUnitIcon({
    super.key,
    required this.iconKey,
    this.size = 24,
    this.backgroundColor = const Color(0x1AFFFFFF),
    this.foregroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final BattleUnitIconPreset preset = presetFor(iconKey);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: foregroundColor.withValues(alpha: 0.18)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: size * 0.14,
            child: Container(
              width: size * 0.34,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: foregroundColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(size * 0.08),
              ),
            ),
          ),
          Icon(
            preset.iconData,
            size: size * preset.iconScale,
            color: foregroundColor,
          ),
        ],
      ),
    );
  }

  static BattleUnitIconPreset presetFor(String iconKey) {
    for (final BattleUnitIconPreset preset in presets) {
      if (preset.key == iconKey) {
        return preset;
      }
    }

    return presets.first;
  }
}
