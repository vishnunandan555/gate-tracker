import '../../../core/theme/theme_context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gateletics/providers/providers.dart';

class AppBarTitle extends ConsumerWidget {
  final VoidCallback? onTap;

  const AppBarTitle({
    super.key,
    this.onTap,
  });

  void _showRandomQuote(BuildContext context, WidgetRef ref, Color accentColor) {
    final quote = ref.read(quotesProvider.notifier).randomQuote();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Quote',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return MotivationalQuoteDialog(quote: quote, accentColor: accentColor);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(scale: curve, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressColor = context.appColors.primaryAccent;
    final packageInfo = ref.watch(packageInfoProvider);
    // Watch to ensure the provider is initialized and fetching in background.
    ref.watch(quotesProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap ?? () => _showRandomQuote(context, ref, progressColor),
            behavior: HitTestBehavior.translucent,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'GATE',
                    style: GoogleFonts.boldonse(
                      fontSize: 20,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'LETICS',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'v${packageInfo.version} ',
                  style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 10),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: progressColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Beta',
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MotivationalQuoteDialog extends StatefulWidget {
  final String quote;
  final Color accentColor;

  const MotivationalQuoteDialog({
    super.key,
    required this.quote,
    required this.accentColor,
  });

  @override
  State<MotivationalQuoteDialog> createState() => _MotivationalQuoteDialogState();
}

class _MotivationalQuoteDialogState extends State<MotivationalQuoteDialog> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 3.5 seconds.
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: context.appColors.cardBackground,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: widget.accentColor.withAlpha(50),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withAlpha(25),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: widget.accentColor,
                  size: 40,
                ),
                const SizedBox(height: 18),
                Text(
                  widget.quote,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: context.appColors.textPrimary,
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tap to dismiss',
                  style: GoogleFonts.outfit(
                    color: context.appColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
