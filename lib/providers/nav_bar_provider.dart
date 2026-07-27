import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'syllabus_provider.dart';

class NavItemOption {
  final String id;
  final String label;
  final IconData icon;

  const NavItemOption({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class NavBarNotifier extends Notifier<List<String>> {
  static const String _storageKey = 'custom_nav_bar_slots_ids';
  static const List<String> defaultSlots = ['stats', 'completion', 'home', 'focus'];

  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getStringList(_storageKey);
    if (saved != null && saved.length == 4) {
      return saved;
    }
    return defaultSlots;
  }

  void updateSlots(List<String> newSlots) {
    if (newSlots.length == 4) {
      state = newSlots;
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setStringList(_storageKey, newSlots);
    }
  }

  void resetToDefault() {
    state = defaultSlots;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.remove(_storageKey);
  }
}

final navBarSlotsProvider = NotifierProvider<NavBarNotifier, List<String>>(() {
  return NavBarNotifier();
});

// All available features matching CustomizeNavBarScreen options
const List<NavItemOption> navBarAllOptions = [
  NavItemOption(id: 'stats', label: 'Stats', icon: Icons.analytics_rounded),
  NavItemOption(id: 'completion', label: 'Completion', icon: Icons.percent_rounded),
  NavItemOption(id: 'home', label: 'Home', icon: Icons.home_rounded),
  NavItemOption(id: 'focus', label: 'Focus', icon: Icons.hourglass_empty_rounded),
  NavItemOption(id: 'accounts', label: 'Accounts', icon: Icons.manage_accounts_rounded),
  NavItemOption(id: 'settings', label: 'Settings', icon: Icons.settings_rounded),
  NavItemOption(id: 'contribute', label: 'Contribute', icon: Icons.volunteer_activism_rounded),
  NavItemOption(id: 'about', label: 'About', icon: Icons.info_outline_rounded),
  NavItemOption(id: 'customizer', label: 'Customizer', icon: Icons.tune_rounded),
  NavItemOption(id: 'socials', label: 'Socials', icon: Icons.group_rounded),
  NavItemOption(id: 'resources', label: 'Resources', icon: Icons.library_books_rounded),
  NavItemOption(id: 'planner', label: 'Planner', icon: Icons.edit_calendar_rounded),
  NavItemOption(id: 'notifications', label: 'Alerts', icon: Icons.notifications_active_rounded),
];
