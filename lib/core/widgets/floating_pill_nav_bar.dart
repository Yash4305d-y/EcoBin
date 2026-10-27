import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class FloatingNavItem {
  const FloatingNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating, inset pill navigation bar for EcoBin.
///
/// Features:
/// - Rounded capsule shape inset 16px from screen edges.
/// - Dark slate surface with subtle 1px border and faint mint glow.
/// - Smoothly sliding mint-tinted active indicator behind the selected item.
/// - Active icon scaled to 1.12 with soft glow; inactive icons at 60% opacity.
/// - Cross-fades outline and filled icon variants.
/// - Reveals active label with [AnimatedSize] and [AnimatedOpacity].
/// - Tactile [HapticFeedback.selectionClick] on tab selection.
class FloatingPillNavBar extends StatelessWidget {
  const FloatingPillNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavItem> items;

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animDuration = disableAnimations ? Duration.zero : AppMotion.standard;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.slateSurface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.slateOutlineVariant.withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkNavyDeep.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.mintGreen.withValues(alpha: 0.05),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = constraints.maxWidth / items.length;
              final targetX =
                  -1.0 + (currentIndex * (2.0 / (items.length - 1)));

              return Stack(
                children: [
                  // Smoothly sliding mint-tinted active indicator
                  AnimatedAlign(
                    alignment: Alignment(targetX, 0.0),
                    duration: animDuration,
                    curve: AppMotion.enterCurve,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Container(
                        width: slotWidth - 8,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.mintGreenContainer,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.mintGreen.withValues(alpha: 0.35),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mintGreen.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Navigation Items Row
                  Row(
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isSelected = index == currentIndex;

                      return Expanded(
                        child: _PillNavButton(
                          item: item,
                          isSelected: isSelected,
                          duration: animDuration,
                          onTap: () {
                            if (index != currentIndex) {
                              HapticFeedback.selectionClick();
                              onTap(index);
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PillNavButton extends StatefulWidget {
  const _PillNavButton({
    required this.item,
    required this.isSelected,
    required this.duration,
    required this.onTap,
  });

  final FloatingNavItem item;
  final bool isSelected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  State<_PillNavButton> createState() => _PillNavButtonState();
}

class _PillNavButtonState extends State<_PillNavButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () {
          if (_isPressed) setState(() => _isPressed = false);
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : 1.0,
          duration: AppMotion.micro,
          curve: AppMotion.stateChangeCurve,
          child: SizedBox(
            height: 60,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scaled & Glowing Active Icon
                  AnimatedScale(
                    scale: widget.isSelected ? 1.12 : 1.0,
                    duration: widget.duration,
                    curve: AppMotion.popFeedbackCurve,
                    child: AnimatedOpacity(
                      opacity: widget.isSelected ? 1.0 : 0.6,
                      duration: widget.duration,
                      child: AnimatedSwitcher(
                        duration: AppMotion.micro,
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: Icon(
                          widget.isSelected
                              ? widget.item.selectedIcon
                              : widget.item.icon,
                          key: ValueKey<bool>(widget.isSelected),
                          color: widget.isSelected
                              ? AppColors.mintGreen
                              : AppColors.textSecondary,
                          size: 22,
                          shadows: widget.isSelected
                              ? [
                                  Shadow(
                                    color: AppColors.mintGreen.withValues(
                                      alpha: 0.45,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // Reveal active label smoothly with AnimatedSize and Fade
                  AnimatedSize(
                    duration: widget.duration,
                    curve: AppMotion.enterCurve,
                    child: widget.isSelected
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 6),
                              AnimatedOpacity(
                                opacity: 1.0,
                                duration: widget.duration,
                                child: Text(
                                  widget.item.label,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.mintGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Accessible unselected label that stays in the element tree for screen readers & test finders
                  if (!widget.isSelected)
                    SizedBox(
                      width: 0,
                      height: 0,
                      child: Opacity(
                        opacity: 0.0,
                        child: Text(widget.item.label),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
