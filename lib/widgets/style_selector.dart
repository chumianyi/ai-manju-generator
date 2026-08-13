import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StyleSelector extends StatelessWidget {
  final String selectedStyle;
  final String selectedRatio;
  final ValueChanged<String> onStyleChanged;
  final ValueChanged<String> onRatioChanged;

  const StyleSelector({
    super.key,
    required this.selectedStyle,
    required this.selectedRatio,
    required this.onStyleChanged,
    required this.onRatioChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '视频风格',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AppConstants.videoStyles.map((style) {
              final selected = style == selectedStyle;
              return ChoiceChip(
                label: Text(style),
                selected: selected,
                onSelected: (_) => onStyleChanged(style),
                labelStyle: theme.textTheme.labelSmall,
                selectedColor: theme.colorScheme.primaryContainer,
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            '视频比例',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AppConstants.videoRatios.map((ratio) {
              final selected = ratio == selectedRatio;
              return ChoiceChip(
                label: Text(ratio),
                selected: selected,
                onSelected: (_) => onRatioChanged(ratio),
                labelStyle: theme.textTheme.labelSmall,
                selectedColor: theme.colorScheme.secondaryContainer,
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
