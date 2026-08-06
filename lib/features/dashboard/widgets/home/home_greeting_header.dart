import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../utils/ui_scaling.dart';
import '../../../../utils/demo_keys.dart';

class GreetingData {
  final String line1;
  final String line2;
  final bool isLine1Accent;

  const GreetingData({
    required this.line1,
    required this.line2,
    required this.isLine1Accent,
  });
}

GreetingData getDynamicGreeting(String? name) {
  final now = DateTime.now();
  final hour = now.hour;
  final cleanName = (name != null && name.trim().isNotEmpty) ? name.trim() : null;

  if (cleanName == null) {
    if (hour >= 5 && hour < 9) {
      final options = ["Good Morning!", "Rise & Grind!", "Early Bird!", "Dawn of a New Day!", "Fresh Start!"];
      return GreetingData(line1: options[now.minute % options.length], line2: "", isLine1Accent: false);
    } else if (hour >= 9 && hour < 12) {
      final options = ["Good Morning!", "Stay Sharp!", "Keep the Momentum!", "Ready to Focus!", "Welcome Back!"];
      return GreetingData(line1: options[now.minute % options.length], line2: "", isLine1Accent: false);
    } else if (hour >= 12 && hour < 17) {
      final options = ["Good Afternoon!", "Lock In!", "Keep Pushing!", "Back to the Grind!", "Stay on Track!"];
      return GreetingData(line1: options[now.minute % options.length], line2: "", isLine1Accent: false);
    } else if (hour >= 17 && hour < 21) {
      final options = ["Good Evening!", "Finish Strong!", "Golden Hour Focus!", "Back at the Desk!", "Evening Session!"];
      return GreetingData(line1: options[now.minute % options.length], line2: "", isLine1Accent: false);
    } else {
      final options = ["The Night is Young!", "Burning the Midnight Oil!", "Midnight Scholar!", "Late Night Grind!", "Night Owl Focus!"];
      return GreetingData(line1: options[now.minute % options.length], line2: "", isLine1Accent: false);
    }
  }

  final indexSeed = (now.minute + now.day) % 5;

  if (hour >= 5 && hour < 9) {
    final templates = [
      GreetingData(line1: "Good Morning,", line2: "$cleanName!", isLine1Accent: false),
      GreetingData(line1: "$cleanName,", line2: "time to shine!", isLine1Accent: true),
      GreetingData(line1: "Rise and grind,", line2: "$cleanName!", isLine1Accent: false),
      GreetingData(line1: "$cleanName,", line2: "dawn of a new day!", isLine1Accent: true),
      GreetingData(line1: "Fresh start,", line2: "$cleanName!", isLine1Accent: false),
    ];
    return templates[indexSeed % templates.length];
  } else if (hour >= 9 && hour < 12) {
    final templates = [
      GreetingData(line1: "$cleanName,", line2: "stay sharp!", isLine1Accent: true),
      GreetingData(line1: "Keep the momentum,", line2: "$cleanName!", isLine1Accent: false),
      GreetingData(line1: "$cleanName,", line2: "ready to focus?", isLine1Accent: true),
      GreetingData(line1: "Good Morning,", line2: "$cleanName!", isLine1Accent: false),
      GreetingData(line1: "$cleanName,", line2: "welcome back!", isLine1Accent: true),
    ];
    return templates[indexSeed % templates.length];
  } else if (hour >= 12 && hour < 17) {
    final templates = [
      GreetingData(line1: "Good Afternoon,", line2: "$cleanName!", isLine1Accent: false),
      GreetingData(line1: "$cleanName,", line2: "lock in!", isLine1Accent: true),
      GreetingData(line1: "Keep pushing,", line2: "$cleanName!", isLine1Accent: false),
      GreetingData(line1: "$cleanName,", line2: "back to the grind!", isLine1Accent: true),
      GreetingData(line1: "Stay on track,", line2: "$cleanName!", isLine1Accent: false),
    ];
    return templates[indexSeed % templates.length];
  } else if (hour >= 17 && hour < 21) {
    final templates = [
      GreetingData(line1: "Good Evening,", line2: "$cleanName!", isLine1Accent: false),
      GreetingData(line1: "$cleanName,", line2: "finish strong!", isLine1Accent: true),
      GreetingData(line1: "Golden hour focus,", line2: "$cleanName!", isLine1Accent: false),
      GreetingData(line1: "$cleanName,", line2: "back at the desk!", isLine1Accent: true),
      GreetingData(line1: "Evening session,", line2: "$cleanName!", isLine1Accent: false),
    ];
    return templates[indexSeed % templates.length];
  } else {
    final templates = [
      GreetingData(line1: "$cleanName,", line2: "the night is young!", isLine1Accent: true),
      GreetingData(line1: "Burning the midnight oil,", line2: "$cleanName!", isLine1Accent: false),
      GreetingData(line1: "$cleanName,", line2: "midnight scholar mode!", isLine1Accent: true),
      GreetingData(line1: "Late night grind,", line2: "$cleanName!", isLine1Accent: false),
      GreetingData(line1: "$cleanName,", line2: "night owl focus!", isLine1Accent: true),
    ];
    return templates[indexSeed % templates.length];
  }
}

class HomeGreetingHeader extends ConsumerWidget {
  final bool isDesktop;
  final Color accentColor;

  const HomeGreetingHeader({
    super.key,
    required this.isDesktop,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(displayNameProvider);
    final profileImage = ref.watch(displayProfileImageProvider);
    final profileState = ref.watch(profileProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (profileState.profilePhotoMode != 'none') ...[
          Center(
            child: GestureDetector(
              key: isDesktop ? null : DemoKeys.homeProfileAvatar,
              onTap: () {
                ref.read(overallProgressColorProvider.notifier).next();
              },
              behavior: HitTestBehavior.translucent,
              child: Container(
                padding: EdgeInsets.all(context.s(3)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: context.s(1.5)),
                ),
                child: CircleAvatar(
                  radius: context.s(profileState.profilePhotoSize),
                  backgroundImage: profileImage,
                  onBackgroundImageError: profileImage != null ? (e, s) {} : null,
                  backgroundColor: accentColor.withAlpha(30),
                  child: profileImage == null
                      ? Icon(Icons.person_rounded, color: accentColor, size: context.s(profileState.profilePhotoSize))
                      : null,
                ),
              ),
            ),
          ),
          SizedBox(height: context.s(16)),
        ],

        Center(
          child: Builder(
            builder: (context) {
              final greeting = getDynamicGreeting(displayName);
              final accentFontSize = context.s(22);
              final normalFontSize = context.s(16);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    greeting.line1,
                    style: GoogleFonts.outfit(
                      color: greeting.isLine1Accent ? accentColor : context.appColors.textPrimary,
                      fontSize: greeting.isLine1Accent ? accentFontSize : normalFontSize,
                      fontWeight: greeting.isLine1Accent ? FontWeight.bold : FontWeight.w500,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (greeting.line2.isNotEmpty) ...[
                    SizedBox(height: context.s(2)),
                    Text(
                      greeting.line2,
                      style: GoogleFonts.outfit(
                        color: !greeting.isLine1Accent ? accentColor : context.appColors.textSecondary,
                        fontSize: !greeting.isLine1Accent ? accentFontSize : normalFontSize,
                        fontWeight: !greeting.isLine1Accent ? FontWeight.bold : FontWeight.w500,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
