import 'package:flutter/material.dart';
import 'package:todo_list/domain/entities/battle_unit_definition.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_unit_icon.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_rule_text.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_unit_text_formatter.dart';

class BattleUnitCard extends StatelessWidget {
  final BattleUnitDefinitionEntity definition;
  final bool compact;
  final int? attackValue;
  final int? healthValue;
  final int? maxHealthValue;
  final bool highlightTaunt;
  final ValueChanged<String>? onKeywordTap;

  const BattleUnitCard({
    super.key,
    required this.definition,
    this.compact = false,
    this.attackValue,
    this.healthValue,
    this.maxHealthValue,
    this.highlightTaunt = false,
    this.onKeywordTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<BattleRuleLine> rulesText =
        BattleUnitTextFormatter.buildRuleLines(definition);
    final int displayedAttack = attackValue ?? definition.attack;
    final int displayedHealth = healthValue ?? definition.health;
    final int displayedMaxHealth = maxHealthValue ?? definition.health;
    final double outerBorderWidth = highlightTaunt ? 5 : 3;
    final double innerBorderWidth = highlightTaunt ? 3 : 2;
    final Color outerBorderColor = highlightTaunt
        ? const Color(0xFFF8F0B5)
        : const Color(0xFFEED89B);

    return AspectRatio(
      aspectRatio: compact ? 0.72 : 0.68,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFF1D6A3),
              Color(0xFFE1B96B),
              Color(0xFFB67A33),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x553B2214),
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
          border: Border.all(color: outerBorderColor, width: outerBorderWidth),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6E4A1E),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            definition.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            _cardAccent(
                              definition.iconKey,
                            ).withValues(alpha: 0.92),
                            const Color(0xFF2F1F1A),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: innerBorderWidth,
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          BattleUnitIcon(
                            iconKey: definition.iconKey,
                            size: compact ? 54 : 72,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEDCB0),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: rulesText
                                    .take(compact ? 3 : rulesText.length)
                                    .map(
                                      (BattleRuleLine line) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: BattleRuleText(
                                          line: line,
                                          onTapKeyword: onKeywordTap,
                                          style: TextStyle(
                                            color: const Color(0xFF4A3116),
                                            fontSize: compact ? 10 : 11,
                                            fontWeight: FontWeight.w700,
                                            height: 1.15,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: _buildStatOrb(
                  color: const Color(0xFFE1B53A),
                  value: '$displayedAttack',
                  valueColor: _statValueColor(
                    currentValue: displayedAttack,
                    baseValue: definition.attack,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: _buildStatOrb(
                  color: const Color(0xFFD34B43),
                  value: displayedMaxHealth == displayedHealth
                      ? '$displayedHealth'
                      : '$displayedHealth/$displayedMaxHealth',
                  valueColor: _statValueColor(
                    currentValue: displayedHealth,
                    baseValue: definition.health,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatOrb({
    required Color color,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: valueColor,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _statValueColor({required int currentValue, required int baseValue}) {
    if (currentValue > baseValue) {
      return const Color(0xFF43B95C);
    }
    if (currentValue < baseValue) {
      return const Color(0xFF7A1616);
    }
    return Colors.white;
  }

  Color _cardAccent(String iconKey) {
    return switch (iconKey) {
      'soldier' => const Color(0xFF7A92C7),
      'ranged' => const Color(0xFF5A8F68),
      'healer' => const Color(0xFFB55F6A),
      'banner' => const Color(0xFFAB6E2B),
      'mage' => const Color(0xFF6F5BAF),
      'beast' => const Color(0xFF8C5B33),
      _ => const Color(0xFF7A92C7),
    };
  }
}
