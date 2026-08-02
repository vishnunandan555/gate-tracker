import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';

void showCommunityNotificationsSheet(BuildContext context, WidgetRef ref) {
  final notifState = ref.read(communityNotificationsProvider);
  final notifications = notifState.notifications;
  final accentColor = ref.read(overallProgressColorProvider);

  // Mark all as read when opening the sheet
  ref.read(communityNotificationsProvider.notifier).markAllAsRead();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Header Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active_rounded, color: accentColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'COMMUNITY ALERTS',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.appColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  if (notifications.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        ref.read(communityNotificationsProvider.notifier).markAllAsRead();
                      },
                      child: Text(
                        'Clear All',
                        style: GoogleFonts.outfit(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none_rounded, color: context.appColors.textMuted, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'No Community Notifications',
                              style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You are all caught up on syllabus updates & announcements.',
                              style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.appColors.surfaceColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: context.appColors.borderColor),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: accentColor.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.campaign_rounded, color: accentColor, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: GoogleFonts.outfit(
                                          color: context.appColors.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.message,
                                        style: GoogleFonts.outfit(
                                          color: context.appColors.textSecondary,
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
