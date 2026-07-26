import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/community_notifications_provider.dart';
import '../../../providers/notice_board_provider.dart';

void showCommunityNotificationsSheet(BuildContext context, WidgetRef ref) {
  ref.read(communityNotificationsProvider.notifier).markAllAsRead();
  ref.read(homeHeaderViewModeProvider.notifier).state = HomeHeaderViewMode.notifications;
  ref.read(noticeBoardModeProvider.notifier).state = false;
}
