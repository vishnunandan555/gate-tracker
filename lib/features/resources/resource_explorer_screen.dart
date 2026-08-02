import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/theme_context_ext.dart';
import '../../database/app_database.dart';
import 'package:gateletics/providers/providers.dart';
import '../../utils/ui_scaling.dart';
import '../more/screens/contribute_screen.dart';

class ResourceExplorerScreen extends ConsumerStatefulWidget {
  const ResourceExplorerScreen({super.key});

  @override
  ConsumerState<ResourceExplorerScreen> createState() => _ResourceExplorerScreenState();
}

class _ResourceExplorerScreenState extends ConsumerState<ResourceExplorerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedBranchFilter = 'AUTO'; // AUTO = active user branch
  String _selectedSubjectFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getUserBranch() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getString('selected_branch') ?? 'CS';
  }

  void _showContributeInfoDialog(BuildContext context, Color accentColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.dialogBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_rounded, color: accentColor, size: 22),
            const SizedBox(width: 8),
            Text(
              'Contribute Resources',
              style: GoogleFonts.outfit(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Found a high-quality GATE lecture series, playlist, or study resource to share? You can contribute your favorite resources to GATEletics to help fellow aspirants!',
          style: GoogleFonts.outfit(
            color: context.appColors.textSecondary,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.outfit(color: context.appColors.textMuted),
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ContributeScreen()),
              );
            },
            icon: const Icon(Icons.volunteer_activism_rounded, size: 16),
            label: Text(
              'Contribute',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: context.appColors.onAccent,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = context.appColors.primaryAccent;
    final resourcesAsync = ref.watch(resourcesProvider);
    final userBranch = _getUserBranch();
    final activeBranch = _selectedBranchFilter == 'AUTO' ? userBranch : _selectedBranchFilter;

    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.appColors.scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.appColors.textPrimary),
          onPressed: () {
            ref.read(hapticSettingsProvider.notifier).selectionClick();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'RESOURCE EXPLORER',
          style: GoogleFonts.jersey15(
            fontSize: context.s(22),
            color: context.appColors.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_rounded, color: accentColor),
            tooltip: 'Contribute Resources',
            onPressed: () {
              ref.read(hapticSettingsProvider.notifier).selectionClick();
              _showContributeInfoDialog(context, accentColor);
            },
          ),
        ],
      ),
      body: resourcesAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: accentColor),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to load study resources',
                style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(resourcesProvider.notifier).refresh(),
                style: FilledButton.styleFrom(backgroundColor: accentColor, foregroundColor: context.appColors.onAccent),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (allResources) {
          // Filter resources by branch
          final branchFiltered = allResources.where((r) {
            if (activeBranch == 'ALL') return true;
            return r.branches.contains('ALL') || r.branches.contains(activeBranch.toUpperCase());
          }).toList();

          // Filter by search query
          final searchFiltered = branchFiltered.where((r) {
            if (_searchQuery.isEmpty) return true;
            final inTitle = r.title.toLowerCase().contains(_searchQuery);
            final inSubject = r.subject.toLowerCase().contains(_searchQuery);
            final inSource = r.source.toLowerCase().contains(_searchQuery);
            final inPlatform = r.platform.toLowerCase().contains(_searchQuery);
            return inTitle || inSubject || inSource || inPlatform;
          }).toList();

          // Collect subjects for filter chips
          final subjects = <String>{'ALL'};
          for (final r in branchFiltered) {
            subjects.add(r.subject);
          }

          // Filter by subject
          final finalFiltered = searchFiltered.where((r) {
            if (_selectedSubjectFilter == 'ALL') return true;
            return r.subject.toLowerCase() == _selectedSubjectFilter.toLowerCase();
          }).toList();

          // Group by Subject
          final grouped = <String, List<StudyResource>>{};
          for (final r in finalFiltered) {
            grouped.putIfAbsent(r.subject, () => []).add(r);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Banner & Branch Selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Stats Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.appColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.05),
                              blurRadius: 16,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.video_library_rounded, color: accentColor, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${finalFiltered.length} CURATED RESOURCES',
                                    style: GoogleFonts.orbitron(
                                      color: accentColor,
                                      fontSize: context.s(11),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Curated lecture series & playlists for paper $activeBranch',
                                    style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh_rounded, color: accentColor, size: 20),
                              tooltip: 'Refresh Catalog',
                              onPressed: () {
                                ref.read(hapticSettingsProvider.notifier).selectionClick();
                                ref.read(resourcesProvider.notifier).forceRefresh();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Refreshing study resources from GitHub...'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Branch Switcher Bar & Search Field
                      Row(
                        children: [
                          // Branch Selector Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.appColors.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedBranchFilter,
                                dropdownColor: context.appColors.surfaceColor,
                                icon: Icon(Icons.arrow_drop_down, color: accentColor, size: 20),
                                style: GoogleFonts.orbitron(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                                items: [
                                  DropdownMenuItem(value: 'AUTO', child: Text('AUTO ($userBranch)')),
                                  const DropdownMenuItem(value: 'ALL', child: Text('ALL PAPERS')),
                                  const DropdownMenuItem(value: 'CS', child: Text('CS')),
                                  const DropdownMenuItem(value: 'DA', child: Text('DA')),
                                  const DropdownMenuItem(value: 'EC', child: Text('EC')),
                                  const DropdownMenuItem(value: 'EE', child: Text('EE')),
                                  const DropdownMenuItem(value: 'CE', child: Text('CE')),
                                  const DropdownMenuItem(value: 'ME', child: Text('ME')),
                                  const DropdownMenuItem(value: 'CH', child: Text('CH')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    ref.read(hapticSettingsProvider.notifier).selectionClick();
                                    setState(() {
                                      _selectedBranchFilter = val;
                                      _selectedSubjectFilter = 'ALL';
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Search Bar
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search playlists, sources...',
                                hintStyle: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 12),
                                prefixIcon: Icon(Icons.search_rounded, color: accentColor, size: 18),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear_rounded, color: context.appColors.textMuted, size: 16),
                                        onPressed: () {
                                          _searchController.clear();
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: context.appColors.cardBackground,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: context.appColors.borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: context.appColors.borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: accentColor, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Subject Chips Filter Bar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: subjects.map((sub) {
                            final isSelected = _selectedSubjectFilter.toLowerCase() == sub.toLowerCase();
                            return GestureDetector(
                              onTap: () {
                                ref.read(hapticSettingsProvider.notifier).selectionClick();
                                setState(() => _selectedSubjectFilter = sub);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? accentColor.withValues(alpha: 0.2) : context.appColors.cardBackground,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? accentColor : context.appColors.borderColor,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Text(
                                  sub,
                                  style: GoogleFonts.outfit(
                                    color: isSelected ? context.appColors.onAccent : context.appColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Empty Search Results
              if (grouped.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, color: context.appColors.textMuted, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No study resources matched your filters',
                          style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _selectedSubjectFilter = 'ALL';
                              _selectedBranchFilter = 'AUTO';
                            });
                          },
                          child: Text('Reset Filters', style: TextStyle(color: accentColor)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Grouped Resource Cards
              ...grouped.entries.map((entry) {
                final subjectName = entry.key;
                final resourceList = entry.value;

                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(6)),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                subjectName.toUpperCase(),
                                style: GoogleFonts.jersey15(
                                  color: context.appColors.textPrimary,
                                  fontSize: context.s(16),
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${resourceList.length})',
                                style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, idx) {
                            final resource = resourceList[idx];
                            return _ResourceCardTile(
                              resource: resource,
                              accentColor: accentColor,
                            );
                          },
                          childCount: resourceList.length,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              SliverToBoxAdapter(
                child: SizedBox(height: context.s(32)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResourceCardTile extends ConsumerWidget {
  final StudyResource resource;
  final Color accentColor;

  const _ResourceCardTile({
    required this.resource,
    required this.accentColor,
  });

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'website':
        return Colors.cyanAccent;
      case 'drive':
        return Colors.blueAccent;
      case 'pdf':
        return Colors.amberAccent;
      default:
        return accentColor;
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle_fill_rounded;
      case 'website':
        return Icons.language_rounded;
      case 'drive':
        return Icons.folder_shared_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      default:
        return Icons.open_in_new_rounded;
    }
  }

  Future<void> _launchUrl(BuildContext context) async {
    String urlToLaunch = resource.url;
    if (!RegExp(r'^[a-zA-Z]+:').hasMatch(urlToLaunch)) {
      urlToLaunch = 'https://$urlToLaunch';
    }
    final uri = Uri.parse(urlToLaunch);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open link: ${resource.url}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _addResourceAsCounterCard(BuildContext context, WidgetRef ref) {
    final syllabusVal = ref.read(syllabusProvider).value;
    if (syllabusVal == null || syllabusVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active syllabus categories found.')),
      );
      return;
    }

    SyllabusCategory? targetCat;
    for (final catWithTopics in syllabusVal) {
      final catName = catWithTopics.category.name.toLowerCase().trim();
      final subjectName = resource.subject.toLowerCase().trim();
      if (catName == subjectName || catName.contains(subjectName) || subjectName.contains(catName)) {
        targetCat = catWithTopics.category;
        break;
      }
    }

    final maxCount = resource.lectureCount > 0 ? resource.lectureCount : 10;

    if (targetCat != null) {
      ref.read(syllabusControllerProvider.notifier).addCounterTopic(
            targetCat.id,
            resource.title,
            maxCount,
            resource.url,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${resource.title}" counter card to ${targetCat.name}!'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: context.appColors.dialogBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADD TO CATEGORY',
                style: GoogleFonts.jersey15(color: accentColor, fontSize: 18, letterSpacing: 1.0),
              ),
              const SizedBox(height: 6),
              Text(
                'Select syllabus category for "${resource.title}":',
                style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: syllabusVal.length,
                  itemBuilder: (c, i) {
                    final cat = syllabusVal[i].category;
                    return ListTile(
                      title: Text(cat.name, style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                      trailing: Icon(Icons.add_circle_outline_rounded, color: accentColor, size: 20),
                      onTap: () {
                        ref.read(syllabusControllerProvider.notifier).addCounterTopic(
                              cat.id,
                              resource.title,
                              maxCount,
                              resource.url,
                            );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${resource.title}" counter card to ${cat.name}!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformColor = _getPlatformColor(resource.platform);
    final platformIcon = _getPlatformIcon(resource.platform);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Source badge & Platform tag
          Row(
            children: [
              // Platform badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: platformColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: platformColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(platformIcon, color: platformColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      resource.platform.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: platformColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Source Name
              Text(
                'by ${resource.source}',
                style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const Spacer(),

              // Applicable Branches Tags
              Wrap(
                spacing: 4,
                children: resource.branches.take(3).map((b) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: context.appColors.surfaceColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      b,
                      style: GoogleFonts.orbitron(color: context.appColors.textSecondary, fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Title
          Text(
            resource.title,
            style: GoogleFonts.outfit(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          if (resource.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              resource.description,
              style: GoogleFonts.outfit(
                color: context.appColors.textMuted,
                fontSize: 11.5,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 12),

          // Bottom Bar: Lecture count & Action buttons
          Row(
            children: [
              if (resource.lectureCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.ondemand_video_rounded, color: accentColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${resource.lectureCount} Lectures',
                        style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              const Spacer(),

              // External link (Open) button
              IconButton(
                icon: Icon(Icons.open_in_new_rounded, color: context.appColors.textSecondary, size: 18),
                tooltip: 'Open link in browser',
                onPressed: () {
                  ref.read(hapticSettingsProvider.notifier).selectionClick();
                  _launchUrl(context);
                },
              ),

              // Copy link button
              IconButton(
                icon: Icon(Icons.copy_rounded, color: context.appColors.textMuted, size: 18),
                tooltip: 'Copy URL',
                onPressed: () {
                  ref.read(hapticSettingsProvider.notifier).selectionClick();
                  Clipboard.setData(ClipboardData(text: resource.url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              const SizedBox(width: 4),

              // Main ADD filled button
              FilledButton.icon(
                onPressed: () {
                  ref.read(hapticSettingsProvider.notifier).selectionClick();
                  _addResourceAsCounterCard(context, ref);
                },
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text('ADD'),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: GoogleFonts.orbitron(fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


