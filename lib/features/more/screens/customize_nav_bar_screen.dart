import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../utils/ui_scaling.dart';

class _NavItemOption {
  final String id;
  final String label;
  final IconData icon;

  const _NavItemOption({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class CustomizeNavBarScreen extends ConsumerStatefulWidget {
  const CustomizeNavBarScreen({super.key});

  @override
  ConsumerState<CustomizeNavBarScreen> createState() => _CustomizeNavBarScreenState();
}

class _CustomizeNavBarScreenState extends ConsumerState<CustomizeNavBarScreen> {
  // All available feature options
  static const List<_NavItemOption> _allOptions = [
    _NavItemOption(id: 'stats', label: 'Stats', icon: Icons.analytics_rounded),
    _NavItemOption(id: 'completion', label: 'Completion', icon: Icons.percent_rounded),
    _NavItemOption(id: 'home', label: 'Home', icon: Icons.home_rounded),
    _NavItemOption(id: 'focus', label: 'Focus', icon: Icons.hourglass_empty_rounded),
    _NavItemOption(id: 'accounts', label: 'Accounts', icon: Icons.manage_accounts_rounded),
    _NavItemOption(id: 'settings', label: 'Settings', icon: Icons.settings_rounded),
    _NavItemOption(id: 'contribute', label: 'Contribute', icon: Icons.volunteer_activism_rounded),
    _NavItemOption(id: 'about', label: 'About', icon: Icons.info_outline_rounded),
    _NavItemOption(id: 'customizer', label: 'Customizer', icon: Icons.tune_rounded),
    _NavItemOption(id: 'socials', label: 'Socials', icon: Icons.group_rounded),
    _NavItemOption(id: 'resources', label: 'Resources', icon: Icons.library_books_rounded),
    _NavItemOption(id: 'planner', label: 'Planner', icon: Icons.edit_calendar_rounded),
    _NavItemOption(id: 'notifications', label: 'Alerts', icon: Icons.notifications_active_rounded),
  ];

  // Active 4 slots in the nav bar
  late List<_NavItemOption> _slots;
  int? _hoveredSlotIndex;

  @override
  void initState() {
    super.initState();
    final activeIds = ref.read(navBarSlotsProvider);
    _slots = activeIds.map((id) {
      return _allOptions.firstWhere((opt) => opt.id == id, orElse: () => _allOptions[2]);
    }).toList();
  }

  void _swapOrReplaceSlot(int targetIndex, _NavItemOption incomingOption) {
    HapticFeedback.selectionClick();
    setState(() {
      final existingIndexInSlots = _slots.indexWhere((s) => s.id == incomingOption.id);

      if (existingIndexInSlots != -1) {
        final temp = _slots[targetIndex];
        _slots[targetIndex] = incomingOption;
        _slots[existingIndexInSlots] = temp;
      } else {
        _slots[targetIndex] = incomingOption;
      }
    });
  }

  void _resetToDefault() {
    HapticFeedback.mediumImpact();
    ref.read(navBarSlotsProvider.notifier).resetToDefault();
    final activeIds = ref.read(navBarSlotsProvider);
    setState(() {
      _slots = activeIds.map((id) {
        return _allOptions.firstWhere((opt) => opt.id == id, orElse: () => _allOptions[2]);
      }).toList();
    });
  }

  void _saveChanges() {
    HapticFeedback.selectionClick();
    ref.read(navBarSlotsProvider.notifier).updateSlots(_slots.map((s) => s.id).toList());
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Nav Bar layout saved!',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF1E1E24),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(overallProgressColorProvider);

    // Available catalog: ONLY items NOT currently assigned to the nav bar
    final availableCatalog = _allOptions
        .where((option) => !_slots.any((slot) => slot.id == option.id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Customize Nav Bar',
          style: GoogleFonts.outfit(
            color: context.appColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: context.s(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              Center(
                child: Text(
                  'NAV BAR PREVIEW',
                  style: GoogleFonts.outfit(
                    color: context.appColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: context.appColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.appColors.borderColor),
                ),
                child: Row(
                  children: [
                    // 4 Customizable Slots
                    ...List.generate(4, (index) {
                      final slotOption = _slots[index];
                      final isHovered = _hoveredSlotIndex == index;

                      return Expanded(
                        child: DragTarget<_NavItemOption>(
                          onWillAcceptWithDetails: (details) {
                            setState(() => _hoveredSlotIndex = index);
                            return true;
                          },
                          onLeave: (data) {
                            setState(() => _hoveredSlotIndex = null);
                          },
                          onAcceptWithDetails: (details) {
                            setState(() => _hoveredSlotIndex = null);
                            _swapOrReplaceSlot(index, details.data);
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              decoration: BoxDecoration(
                                color: isHovered
                                    ? accentColor.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => _showSlotSelector(index, accentColor, availableCatalog),
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      slotOption.icon,
                                      color: accentColor,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      slotOption.label,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),

                    // 5th Fixed Slot: More (indicated as locked)
                    Container(
                      width: 1.0,
                      height: 32.0,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),

                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/more_app.svg',
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(
                                Colors.white24,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'More',
                              style: GoogleFonts.outfit(
                                color: Colors.white24,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  'AVAILABLE',
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Transparent, square available features matching exact nav bar slot sizes (no background box)
              availableCatalog.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'All features added to Nav Bar',
                          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5, // 5 columns (exact match to nav bar previews!)
                        childAspectRatio: 1.0, // Perfect square aspect ratio
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: availableCatalog.length,
                      itemBuilder: (context, index) {
                        final option = availableCatalog[index];

                        Widget tileContent = Container(
                          color: Colors.transparent, // No grey box container background
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                option.icon,
                                color: Colors.white70,
                                size: 22,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                option.label,
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );

                        // Square drag feedback widget (64x64) matching exact navbar slot sizes
                        Widget dragFeedback = Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C24),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(option.icon, color: accentColor, size: 22),
                                const SizedBox(height: 3),
                                Text(
                                  option.label,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );

                        return Draggable<_NavItemOption>(
                          data: option,
                          dragAnchorStrategy: pointerDragAnchorStrategy,
                          feedback: dragFeedback,
                          childWhenDragging: Opacity(
                            opacity: 0.2,
                            child: tileContent,
                          ),
                          child: InkWell(
                            onTap: () => _showPlaceInSlotSheet(option, accentColor),
                            borderRadius: BorderRadius.circular(12),
                            child: tileContent,
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Drag to Replace',
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Inline Actions: Reset and Save (placed immediately below catalog) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _resetToDefault,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Reset',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save Layout',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showSlotSelector(int slotIndex, Color accentColor, List<_NavItemOption> availableCatalog) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131318),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Replace Slot ${slotIndex + 1} (${_slots[slotIndex].label})',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (availableCatalog.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No available features to replace with.',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableCatalog.length,
                  itemBuilder: (ctx, idx) {
                    final option = availableCatalog[idx];

                    return ListTile(
                      dense: true,
                      leading: Icon(option.icon, color: Colors.white70, size: 20),
                      title: Text(
                        option.label,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                      ),
                      onTap: () {
                        _swapOrReplaceSlot(slotIndex, option);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPlaceInSlotSheet(_NavItemOption feature, Color accentColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131318),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Place "${feature.label}" in Nav Bar:',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(4, (index) {
              final currentSlot = _slots[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: accentColor.withValues(alpha: 0.15),
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.outfit(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  'Slot ${index + 1} (${currentSlot.label})',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                ),
                onTap: () {
                  _swapOrReplaceSlot(index, feature);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
