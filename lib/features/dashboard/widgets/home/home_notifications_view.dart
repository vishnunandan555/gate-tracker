import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../utils/ui_scaling.dart';

class HomeNotificationsView extends ConsumerWidget {
  final Color accentColor;

  const HomeNotificationsView({
    super.key,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityNotificationsProvider);
    final notifications = state.notifications;
    final unreadCount = state.unreadCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  "Announcements",
                  style: GoogleFonts.outfit(
                    color: context.appColors.textPrimary,
                    fontSize: context.s(18),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: context.s(8)),
                Icon(
                  Icons.campaign_rounded,
                  color: accentColor.withAlpha(200),
                  size: context.s(18),
                ),
              ],
            ),
            Row(
              children: [
                if (state.isLoading)
                  SizedBox(
                    width: context.s(18),
                    height: context.s(18),
                    child: AppLoadingIndicator(
                      strokeWidth: 2,
                      color: accentColor.withAlpha(180),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => ref.read(communityNotificationsProvider.notifier).refresh(),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: accentColor.withAlpha(160),
                      size: context.s(18),
                    ),
                  ),
                if (unreadCount > 0) ...[
                  SizedBox(width: context.s(12)),
                  GestureDetector(
                    onTap: () {
                      ref.read(communityNotificationsProvider.notifier).markAllAsRead();
                    },
                    child: Text(
                      "Mark all as read",
                      style: GoogleFonts.outfit(
                        color: accentColor,
                        fontSize: context.s(12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),

        if (state.hasError && !state.isLoading) ...[
          SizedBox(height: context.s(10)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.s(14), vertical: context.s(8)),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(20),
              borderRadius: BorderRadius.circular(context.s(10)),
              border: Border.all(color: Colors.orange.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.orange, size: context.s(14)),
                SizedBox(width: context.s(8)),
                Expanded(
                  child: Text(
                    "Couldn't fetch latest updates.",
                    style: GoogleFonts.outfit(color: Colors.orange, fontSize: context.s(12)),
                  ),
                ),
                GestureDetector(
                  onTap: () => ref.read(communityNotificationsProvider.notifier).refresh(),
                  child: Text(
                    "Retry",
                    style: GoogleFonts.outfit(
                      color: accentColor,
                      fontSize: context.s(12),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: context.s(16)),

        if (notifications.isEmpty)
          Container(
            padding: EdgeInsets.all(context.s(24)),
            decoration: BoxDecoration(
              color: context.appColors.cardBackground,
              borderRadius: BorderRadius.circular(context.s(16)),
              border: Border.all(color: context.appColors.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: context.s(10),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: accentColor.withAlpha(120),
                  size: context.s(40),
                ),
                SizedBox(height: context.s(12)),
                Text(
                  "No Announcements",
                  style: GoogleFonts.outfit(
                    color: context.appColors.textPrimary,
                    fontSize: context.s(14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: context.s(6)),
                Text(
                  "Check back later for updates and community news.",
                  style: GoogleFonts.outfit(
                    color: context.appColors.textMuted,
                    fontSize: context.s(12),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int index = 0; index < notifications.length; index++) ...[
                if (index > 0) SizedBox(height: context.s(12)),
                Builder(
                  builder: (context) {
                    final item = notifications[index];
                    final isUnread = !state.isNotificationRead(item);

                    return InkWell(
                      onTap: () {
                        if (isUnread) {
                          ref.read(communityNotificationsProvider.notifier).markAsRead(item.id);
                        }
                      },
                      borderRadius: BorderRadius.circular(context.s(16)),
                      child: Container(
                        padding: EdgeInsets.all(context.s(16)),
                        decoration: BoxDecoration(
                          color: isUnread
                              ? (context.appColors.isLight ? accentColor.withAlpha(30) : accentColor.withAlpha(16))
                              : context.appColors.cardBackground,
                          borderRadius: BorderRadius.circular(context.s(16)),
                          border: Border.all(
                            color: isUnread ? accentColor.withAlpha(160) : context.appColors.borderColor,
                            width: isUnread ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            if (isUnread)
                              BoxShadow(
                                color: accentColor.withAlpha(25),
                                blurRadius: context.s(12),
                                offset: const Offset(0, 3),
                              )
                            else
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: context.s(4),
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (isUnread) ...[
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: context.s(6),
                                            vertical: context.s(2),
                                          ),
                                          decoration: BoxDecoration(
                                            color: accentColor,
                                            borderRadius: BorderRadius.circular(context.s(4)),
                                          ),
                                          child: Text(
                                            "NEW",
                                            style: GoogleFonts.orbitron(
                                              color: context.appColors.onAccent,
                                              fontSize: context.s(9),
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: context.s(8)),
                                      ],
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: GoogleFonts.outfit(
                                            color: isUnread ? context.appColors.textPrimary : context.appColors.textSecondary,
                                            fontSize: context.s(15),
                                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (item.date.isNotEmpty) ...[
                                  SizedBox(width: context.s(8)),
                                  Text(
                                    item.date,
                                    style: GoogleFonts.outfit(
                                      color: isUnread ? accentColor : context.appColors.textMuted,
                                      fontSize: context.s(11),
                                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: context.s(8)),
                            Text(
                              item.message,
                              style: GoogleFonts.outfit(
                                color: isUnread ? context.appColors.textPrimary : context.appColors.textSecondary,
                                fontSize: context.s(13),
                                height: 1.4,
                              ),
                            ),
                            if (item.actionUrl != null && item.actionUrl!.isNotEmpty) ...[
                              SizedBox(height: context.s(10)),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.s(12),
                                      vertical: context.s(6),
                                    ),
                                    backgroundColor: accentColor.withAlpha(25),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(context.s(10)),
                                    ),
                                  ),
                                  onPressed: () async {
                                    ref.read(communityNotificationsProvider.notifier).markAsRead(item.id);
                                    final uri = Uri.parse(item.actionUrl!);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  icon: Icon(Icons.open_in_new_rounded, size: context.s(14), color: accentColor),
                                  label: Text(
                                    item.actionText ?? 'Open Link',
                                    style: GoogleFonts.outfit(
                                      color: accentColor,
                                      fontSize: context.s(12),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
      ],
    );
  }
}
