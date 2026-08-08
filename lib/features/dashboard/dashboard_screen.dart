import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/theme_context_ext.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../widgets/pill_progress_widget.dart';
import 'package:gateletics/providers/providers.dart';
import 'widgets/syllabus_category_header.dart';
import 'widgets/syllabus_topic_card.dart';
import 'widgets/syllabus_customization_sheets.dart';
import 'widgets/dashboard_empty_state.dart';
import '../../utils/string_utils.dart';
import '../../utils/ui_scaling.dart';
import '../../utils/demo_keys.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;
  late final TextEditingController _searchController;
  Timer? _autoHideTimer;

  bool searchBarVisible = false;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _resetAutoHideTimer() {
    _autoHideTimer?.cancel();
    if (searchQuery.isEmpty) {
      _autoHideTimer = Timer(const Duration(seconds: 20), () {
        if (mounted && searchQuery.isEmpty) {
          setState(() {
            searchBarVisible = false;
            searchQuery = "";
          });
          _focusNode.unfocus();
        }
      });
    }
  }

  Widget _buildConstrainedBody(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syllabusAsync = ref.watch(syllabusProvider);

    return PopScope(
      canPop: !searchBarVisible,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (searchBarVisible) {
          setState(() {
            searchBarVisible = false;
            searchQuery = "";
            _searchController.clear();
          });
          _focusNode.unfocus();
        }
      },
      child: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Track overall scrolled state for app bar transparency with hysteresis
            final double pixels = notification.metrics.pixels;
            final bool currentlyScrolled = ref.read(completionIsScrolledProvider);

            if (!currentlyScrolled && pixels > 15.0) {
              ref.read(completionIsScrolledProvider.notifier).setScrolled(true);
            } else if (currentlyScrolled && pixels < 2.0) {
              ref.read(completionIsScrolledProvider.notifier).setScrolled(false);
            }
  
            // Track overscroll to show/hide Search Bar
            if (notification is ScrollUpdateNotification) {
              final double pixels = notification.metrics.pixels;
              if (pixels < 0) {
                final double overscroll = -pixels;
                // Require deeper pull (50px) to reveal search bar
                if (overscroll > 50.0) {
                  if (!searchBarVisible) {
                    setState(() {
                      searchBarVisible = true;
                    });
                    _resetAutoHideTimer();
                  }
                }
                // Require intentional deep pull (120px) to automatically focus keyboard
                if (overscroll >= 120.0) {
                  if (!_focusNode.hasFocus) {
                    _focusNode.requestFocus();
                    _resetAutoHideTimer();
                  }
                }
              } else if (pixels > 5.0) {
                // Force hide search bar and dismiss keyboard when user scrolls down
                if (searchBarVisible) {
                  setState(() {
                    searchBarVisible = false;
                    searchQuery = "";
                    _searchController.clear();
                  });
                  _focusNode.unfocus();
                }
              }
            }
            return false;
          },
        child: () {
          if (syllabusAsync.hasError && !syllabusAsync.hasValue) {
            return Center(child: Text('Error: ${syllabusAsync.error}'));
          }
          if (!syllabusAsync.hasValue) {
            return Center(child: AppLoadingIndicator(color: context.appColors.primaryAccent));
          }
          final syllabusData = syllabusAsync.value!;
          final isSyllabusEmpty = syllabusData.isEmpty;

            final stats = ref.watch(completionStatsProvider).value ?? CompletionStats(percentage: 0.0, completed: 0, total: 0);
            final overallProgress = stats.percentage;
            final totalCompleted = stats.completed;
            final totalTasks = stats.total;

            // Unified search processing logic
            final searchResult = filterSyllabusWithScores(syllabusData, searchQuery);
            final filteredSyllabus = searchResult.filteredSyllabus;
            final bestMatchTopic = searchResult.bestMatchTopic;
            final bestMatchCategory = searchResult.bestMatchCategory;
            final query = searchQuery.trim().toLowerCase();

            return _buildConstrainedBody(CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Header spacing
                SliverToBoxAdapter(
                  child: SizedBox(height: context.s(72) + MediaQuery.of(context).padding.top),
                ),

                // Animated Search Bar
                SliverToBoxAdapter(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.fastOutSlowIn,
                    height: searchBarVisible ? context.s(80) : 0.0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: searchBarVisible ? 1.0 : 0.0,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          key: DemoKeys.syllabusSearchBar,
                          padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(16)),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: context.s(14)),
                            decoration: InputDecoration(
                              hintText: 'Search syllabus topics, notes, or tasks...',
                              hintStyle: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: context.s(13)),
                              prefixIcon: Icon(Icons.search_rounded, color: context.appColors.textSecondary, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear_rounded, color: context.appColors.textSecondary, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    searchQuery = "";
                                    searchBarVisible = false;
                                  });
                                  _focusNode.unfocus();
                                },
                              ),
                              filled: true,
                              fillColor: context.appColors.surfaceColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(context.s(12)),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: context.s(10)),
                            ),
                            onChanged: (val) {
                              setState(() {
                                searchQuery = val;
                              });
                              _resetAutoHideTimer();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    key: DemoKeys.completionProgressBar,
                    padding: EdgeInsets.fromLTRB(context.s(20), context.s(12), context.s(20), context.s(20)),
                    child: PillProgressWidget(
                      percentage: overallProgress,
                      totalCompleted: totalCompleted,
                      totalVideos: totalTasks,
                    ),
                  ),
                ),

                if (isSyllabusEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: DashboardEmptyState(),
                  )
                else ...[
                  // 1. BEST MATCH IF APPLICABLE
                  if (query.isNotEmpty && bestMatchTopic != null && bestMatchCategory != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(context.s(16), context.s(12), context.s(16), context.s(4)),
                        child: Row(
                          children: [
                            Icon(Icons.star_rounded, color: Color(bestMatchCategory.color), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'BEST MATCH (FROM ${bestMatchCategory.name.toUpperCase()})',
                              style: GoogleFonts.jersey15(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(bestMatchCategory.color),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SyllabusTopicCard(
                        topicWithTasks: bestMatchTopic,
                        categoryColor: Color(bestMatchCategory.color),
                        forceExpanded: true,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.s(16)),
                        child: Divider(color: context.appColors.dividerColor, height: 16),
                      ),
                    ),
                  ],

                  // 2. NORMAL / FILTERED LIST
                  ...filteredSyllabus.asMap().entries.map((entry) {
                    final index = entry.key;
                    final catWithTopics = entry.value;
                    final category = catWithTopics.category;
                    final topics = catWithTopics.topics;

                    final catStats = catWithTopics.completionStats;
                    final catProgress = catStats.progress;
                    final catTotal = catStats.total;
                    final rawTopics = topics.map((e) => e.topic).toList();

                    final manuallyExpanded = ref.watch(manuallyExpandedCompletedSyllabusCategoriesProvider);
                    final isCompleted = catProgress >= 100.0 && catTotal > 0;
                    final isCollapsed = isCompleted && !manuallyExpanded.contains(category.id);
                    final isPrevCollapsed = () {
                      if (index <= 0) return false;
                      final prevCat = filteredSyllabus[index - 1];
                      final prevStats = prevCat.completionStats;
                      final prevCompletedCheck = prevStats.progress >= 100.0 && prevStats.total > 0;
                      return prevCompletedCheck && !manuallyExpanded.contains(prevCat.category.id);
                    }();

                    final headerPadding = isCollapsed
                        ? EdgeInsets.fromLTRB(context.s(16), context.s(12), context.s(16), 0)
                        : (isPrevCollapsed
                            ? EdgeInsets.fromLTRB(context.s(16), context.s(12), context.s(16), context.s(8))
                            : EdgeInsets.fromLTRB(context.s(16), context.s(24), context.s(16), context.s(8)));

                    return SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: headerPadding,
                            child: SyllabusCategoryHeader(
                              key: index == 0 ? DemoKeys.syllabusCategoryCard : null,
                              category: category,
                              progress: catProgress,
                              topics: rawTopics,
                              isCollapsed: isCollapsed,
                              isFirstCategory: index == 0,
                            ),
                          ),
                        ),
                        if (!isCollapsed)
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, idx) {
                                final topicWithTasks = topics[idx];
                                return SyllabusTopicCard(
                                  key: (index == 0 && idx == 0) ? DemoKeys.completionFirstSubjectCard : null,
                                  topicWithTasks: topicWithTasks,
                                  categoryColor: Color(category.color),
                                  forceExpanded: query.isNotEmpty,
                                );
                              },
                              childCount: topics.length,
                            ),
                          ),
                      ],
                    );
                  }),
                  SliverToBoxAdapter(child: SizedBox(height: context.s(48))),
                ],
              ],
            ));
          }(),
      ),
    ));
  }
}

class WelcomeWidget extends ConsumerWidget {
  const WelcomeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressColor = context.appColors.primaryAccent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.checklist_rtl_rounded,
          size: 64,
          color: progressColor.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 24),
        Text(
          "EMPTY SYLLABUS TRACKER",
          style: GoogleFonts.jersey15(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.appColors.textPrimary,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Create your first syllabus category to start building your custom exam check-list.",
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: context.appColors.textMuted,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 220,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              showCreateSyllabusCategoryDialog(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: progressColor,
              foregroundColor: context.appColors.onAccent,
              elevation: 8,
              shadowColor: progressColor.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Create Category',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
