import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import 'focus/focus_idle_view.dart';
import 'focus/focus_active_view.dart';

class FocusScreen extends ConsumerWidget {
  final Color progressColor;

  const FocusScreen({super.key, required this.progressColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(focusProvider);
    final accentColor = progressColor;

    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
      body: sessionState.status == FocusStatus.idle
          ? SafeArea(child: FocusIdleView(accentColor: accentColor))
          : FocusActiveView(accentColor: accentColor),
    );
  }
}
