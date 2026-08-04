import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../database/app_database.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/widgets/app_bar_title.dart';
import '../dashboard/widgets/countdown_widget.dart';
import '../../widgets/pill_progress_widget.dart';
import 'package:gateletics/providers/providers.dart';
import '../dashboard/widgets/syllabus_category_header.dart';
import '../dashboard/widgets/syllabus_topic_card.dart';
import '../../core/theme/theme_context_ext.dart';

class DeskDashboardScreen extends ConsumerStatefulWidget {
  const DeskDashboardScreen({super.key});

  @override
  ConsumerState<DeskDashboardScreen> createState() => _DeskDashboardScreenState();
}

class _DeskDashboardScreenState extends ConsumerState<DeskDashboardScreen> {
  late final FocusNode _focusNode;
  late final TextEditingController _searchController;
  Timer? _autoHideTimer;

  bool searchBarVisible = false;
  String searchQuery = "";

  static const double _maxContentWidth = 1920;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _resetAutoHideTimer() {
    _autoHideTimer?.cancel();
    if (searchQuery.isEmpty) {
      _autoHideTimer = Timer(const Duration(seconds: 8), () {
        if (mounted && searchQuery.isEmpty) {
          setState(() {
            searchBarVisible = false;
          });
          _focusNode.unfocus();
        }
      });
    }
  }

  double _calculateScore(SyllabusTopicWithTasks topicWithTasks, String query, String categoryName) {
    final topic = topicWithTasks.topic;
    final name = topic.name.toLowerCase();
    final catName = categoryName.toLowerCase();
    
    // Extract note
    final rawUrl = topic.resourceUrl ?? '';
    String note = '';
    if (rawUrl.trim().isNotEmpty) {
      final parts = rawUrl.trim().split('|');
      if (parts.length > 2) {
        note = parts[2].trim().toLowerCase();
      }
    }

    double score = 0;
    
    // Category Name Match (highest weight)
    if (catName == query) {
      score += 150;
    } else if (catName.contains(query)) {
      score += 80 + (1.0 / (catName.indexOf(query) + 1));
    }
    
    // Topic Name Match
    if (name == query) {
      score += 100;
    } else if (name.contains(query)) {
      score += 50 + (1.0 / (name.indexOf(query) + 1));
    }
    
    if (note.isNotEmpty) {
      if (note == query) {
        score += 40;
      } else if (note.contains(query)) {
        score += 20;
      }
    }
    
    for (final task in topicWithTasks.tasks) {
      final taskName = task.name.toLowerCase();
      if (taskName == query) {
        score += 30;
      } else if (taskName.contains(query)) {
        score += 15;
      }
    }
    return score;
  }

  Widget _buildConstrainedBody(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syllabusAsync = ref.watch(syllabusProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;

    final double sidebarWidth = screenWidth < 768 ? 76.0 : 220.0;
    final double availableWidth = (screenWidth - sidebarWidth).clamp(0.0, 1920.0);

    if (syllabusAsync.hasError && !syllabusAsync.hasValue) {
      return Center(child: Text('Error: ${syllabusAsync.error}'));
    }
    if (!syllabusAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    final syllabusData = syllabusAsync.value!;
    final isSyllabusEmpty = syllabusData.isEmpty;
    final stats = ref.watch(completionStatsProvider).value ?? CompletionStats(percentage: 0.0, completed: 0, total: 0);
    final overallProgress = stats.percentage;
    final totalCompleted = stats.completed;
    final totalTasks = stats.total;

    // Search processing logic
    final query = searchQuery.trim().toLowerCase();
    List<SyllabusCategoryWithTopics> filteredSyllabus = [];
    SyllabusTopicWithTasks? bestMatchTopic;
    SyllabusCategory? bestMatchCategory;
    double maxScore = 0;

    if (query.isNotEmpty) {
      for (final catWithTopics in syllabusData) {
        List<SyllabusTopicWithTasks> matchedTopics = [];
        for (final topicWithTasks in catWithTopics.topics) {
          double score = _calculateScore(topicWithTasks, query, catWithTopics.category.name);
          if (score > 0) {
            matchedTopics.add(topicWithTasks);
            if (score > maxScore) {
              maxScore = score;
              bestMatchTopic = topicWithTasks;
              bestMatchCategory = catWithTopics.category;
            }
          }
        }
        
        if (matchedTopics.isNotEmpty) {
          filteredSyllabus.add(SyllabusCategoryWithTopics(
            category: catWithTopics.category,
            topics: matchedTopics,
          ));
        }
      }
      
      if (bestMatchTopic != null && bestMatchCategory != null) {
        filteredSyllabus = filteredSyllabus.map((catWithTopics) {
          if (catWithTopics.category.id == bestMatchCategory!.id) {
            return SyllabusCategoryWithTopics(
              category: catWithTopics.category,
              topics: catWithTopics.topics.where((t) => t.topic.id != bestMatchTopic!.topic.id).toList(),
            );
          }
          return catWithTopics;
        }).where((catWithTopics) => catWithTopics.topics.isNotEmpty).toList();
      }
    } else {
      filteredSyllabus = syllabusData;
    }

    return Scaffold(
      body: _buildConstrainedBody(CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            toolbarHeight: 72,
            floating: true,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 2,
            centerTitle: false,
            automaticallyImplyLeading: false,
            title: const AppBarTitle(),
            actions: [
              IconButton(
                icon: Icon(
                  searchBarVisible ? Icons.search_off_rounded : Icons.search_rounded,
                  color: context.appColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    searchBarVisible = !searchBarVisible;
                    if (!searchBarVisible) {
                      searchQuery = "";
                      _searchController.clear();
                      _focusNode.unfocus();
                    } else {
                      _focusNode.requestFocus();
                    }
                  });
                },
              ),
              const CountdownWidget(),
              const SizedBox(width: 16),
            ],
          ),
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              height: searchBarVisible ? 80.0 : 0.0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: searchBarVisible ? 1.0 : 0.0,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search syllabus topics, notes, or tasks...',
                        hintStyle: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 13),
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
                        fillColor: const Color(0xFF27272A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
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
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: WelcomeWidget(),
              ),
            )
          else ...[
            if (query.isNotEmpty && bestMatchTopic != null && bestMatchCategory != null) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(color: context.appColors.dividerColor, height: 16),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
                child: _SyllabusMultiColumnLayout(
                  syllabusData: filteredSyllabus,
                  availableWidth: availableWidth,
                  forceExpanded: query.isNotEmpty,
                ),
              ),
            ),
          ],
        ],
      )),
    );
  }
}

class _SyllabusMultiColumnLayout extends StatelessWidget {
  final List<SyllabusCategoryWithTopics> syllabusData;
  final double availableWidth;
  final bool forceExpanded;

  const _SyllabusMultiColumnLayout({
    required this.syllabusData,
    required this.availableWidth,
    this.forceExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 768;

    if (isCompact) {
      return Column(
        children: syllabusData.asMap().entries.map((entry) {
          return _SyllabusCategoryBlock(
            index: entry.key,
            catWithTopics: entry.value,
            syllabusData: syllabusData,
            forceExpanded: forceExpanded,
          );
        }).toList(),
      );
    }

    int columnCount = 2;
    if (availableWidth >= 1050) {
      columnCount = 3;
    }
    if (availableWidth >= 1750) {
      columnCount = 4;
    }

    // Build lists for each column
    final columns = List.generate(columnCount, (_) => <Widget>[]);

    for (final entry in syllabusData.asMap().entries) {
      final index = entry.key;
      final catWithTopics = entry.value;
      final widget = _SyllabusCategoryBlock(
        index: index,
        catWithTopics: catWithTopics,
        syllabusData: syllabusData,
        forceExpanded: forceExpanded,
      );
      columns[index % columnCount].add(widget);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(columnCount, (colIndex) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: colIndex == 0 ? 0 : 8,
              right: colIndex == columnCount - 1 ? 0 : 8,
            ),
            child: Column(children: columns[colIndex]),
          ),
        );
      }),
    );
  }
}

class _SyllabusCategoryBlock extends ConsumerWidget {
  final int index;
  final SyllabusCategoryWithTopics catWithTopics;
  final List<SyllabusCategoryWithTopics> syllabusData;
  final bool forceExpanded;

  const _SyllabusCategoryBlock({
    required this.index,
    required this.catWithTopics,
    required this.syllabusData,
    this.forceExpanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = catWithTopics.category;
    final topics = catWithTopics.topics;

    int catCompleted = 0, catTotal = 0;
    for (final topicWithTasks in topics) {
      final topic = topicWithTasks.topic;
      if (topic.isCounter) {
        catCompleted += topic.currentCount;
        catTotal += topic.maxCount;
      } else {
        catCompleted += topicWithTasks.tasks.where((t) => t.isCompleted).length;
        catTotal += topicWithTasks.tasks.length;
      }
    }
    final catProgress = catTotal == 0 ? 0.0 : (catCompleted / catTotal) * 100;
    final rawTopics = topics.map((e) => e.topic).toList();

    final manuallyExpanded = ref.watch(manuallyExpandedCompletedSyllabusCategoriesProvider);
    final isCompleted = catProgress >= 100.0 && catTotal > 0;
    final isCollapsed = isCompleted && !manuallyExpanded.contains(category.id);

    bool isPrevCollapsed = false;
    if (index > 0) {
      final prevCat = syllabusData[index - 1];
      int prevCompleted = 0, prevTotal = 0;
      for (final topicWithTasks in prevCat.topics) {
        final topic = topicWithTasks.topic;
        if (topic.isCounter) {
          prevCompleted += topic.currentCount;
          prevTotal += topic.maxCount;
        } else {
          prevCompleted += topicWithTasks.tasks.where((t) => t.isCompleted).length;
          prevTotal += topicWithTasks.tasks.length;
        }
      }
      final prevProgress = prevTotal == 0 ? 0.0 : (prevCompleted / prevTotal) * 100;
      final prevCompletedCheck = prevProgress >= 100.0 && prevTotal > 0;
      isPrevCollapsed = prevCompletedCheck && !manuallyExpanded.contains(prevCat.category.id);
    }

    final headerPadding = isCollapsed
        ? const EdgeInsets.fromLTRB(8, 12, 8, 0)
        : (isPrevCollapsed
            ? const EdgeInsets.fromLTRB(8, 12, 8, 8)
            : const EdgeInsets.fromLTRB(8, 24, 8, 8));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: headerPadding,
          child: SyllabusCategoryHeader(
            category: category,
            progress: catProgress,
            topics: rawTopics,
            isCollapsed: isCollapsed,
          ),
        ),
        if (!isCollapsed)
          ...topics.map(
            (topicWithTasks) => SyllabusTopicCard(
              topicWithTasks: topicWithTasks,
              categoryColor: Color(category.color),
              forceExpanded: forceExpanded,
            ),
          ),
      ],
    );
  }
}
