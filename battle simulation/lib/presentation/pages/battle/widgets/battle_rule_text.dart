import 'package:flutter/material.dart';
import 'package:todo_list/core/style/app_colors.dart';
import 'package:todo_list/presentation/pages/battle/widgets/battle_unit_text_formatter.dart';

class BattleRuleText extends StatelessWidget {
  final BattleRuleLine line;
  final TextStyle style;
  final ValueChanged<String>? onTapKeyword;

  const BattleRuleText({
    super.key,
    required this.line,
    required this.style,
    this.onTapKeyword,
  });

  @override
  Widget build(BuildContext context) {
    final List<InlineSpan> spans = line.segments
        .map((BattleRuleSegment segment) {
          final String? glossaryKey = segment.glossaryKey;
          if (glossaryKey == null || onTapKeyword == null) {
            return TextSpan(text: segment.text, style: style);
          }

          return WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => onTapKeyword!(glossaryKey),
              child: Text(
                segment.text,
                style: style.copyWith(
                  color: AppColors.primaryColor,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        })
        .toList(growable: false);

    return RichText(text: TextSpan(children: spans));
  }
}
