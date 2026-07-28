import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../utils/ui_scaling.dart';

class FocusAccomplishmentsWidget extends StatefulWidget {
  final String? accomplishments;
  final Color accentColor;
  final double maxWidgetHeight;

  const FocusAccomplishmentsWidget({
    super.key,
    required this.accomplishments,
    required this.accentColor,
    this.maxWidgetHeight = 220.0,
  });

  @override
  State<FocusAccomplishmentsWidget> createState() => _FocusAccomplishmentsWidgetState();
}

class _FocusAccomplishmentsWidgetState extends State<FocusAccomplishmentsWidget> {
  late final ScrollController _scrollController1;
  late final ScrollController _scrollController2;

  @override
  void initState() {
    super.initState();
    _scrollController1 = ScrollController();
    _scrollController2 = ScrollController();
  }

  @override
  void dispose() {
    _scrollController1.dispose();
    _scrollController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accomplishments == null || widget.accomplishments!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final accomplishmentsText = widget.accomplishments!.trim();

    // Check if it is a JSON array
    if (accomplishmentsText.startsWith('[')) {
      try {
        final decoded = jsonDecode(accomplishmentsText) as List<dynamic>;
        return Container(
          constraints: BoxConstraints(maxHeight: context.s(widget.maxWidgetHeight)),
          padding: EdgeInsets.symmetric(horizontal: context.s(10), vertical: context.s(8)),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(5),
            borderRadius: BorderRadius.circular(context.s(12)),
          ),
          child: RawScrollbar(
            controller: _scrollController1,
            thumbColor: widget.accentColor.withAlpha(120),
            radius: Radius.circular(context.s(4)),
            thickness: context.s(3.5),
            fadeDuration: const Duration(milliseconds: 300),
            timeToFade: const Duration(milliseconds: 800),
            thumbVisibility: false,
            child: SingleChildScrollView(
              controller: _scrollController1,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(right: context.s(6)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: decoded.map((catJson) {
                    final catName = catJson['categoryName'] as String? ?? 'Category';
                    final catDelta = (catJson['categoryDelta'] ?? 0.0) as double;
                    final topicsList = catJson['topics'] as List<dynamic>? ?? [];

                    return Padding(
                      padding: EdgeInsets.only(bottom: context.s(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Header: Bold, slightly larger, +A% in accentColor
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  catName,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.s(14),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (catDelta > 0.0)
                                Text(
                                  "+${catDelta.toStringAsFixed(catDelta == catDelta.toInt() ? 0 : 1)}%",
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.s(14),
                                    color: widget.accentColor,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: context.s(2)),
                          // Topics list
                          ...topicsList.map((topicJson) {
                            final topicName = topicJson['topicName'] as String? ?? 'Topic';
                            final topicDelta = (topicJson['topicDelta'] ?? 0.0) as double;
                            final isCounter = topicJson['isCounter'] as bool? ?? false;

                            return Padding(
                              padding: EdgeInsets.only(left: context.s(6), top: context.s(2), bottom: context.s(2)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Topic Header: Bold, slightly smaller, +b% in accentColor
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          topicName,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontSize: context.s(13),
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                      if (!isCounter && topicDelta > 0.0)
                                        Text(
                                          "+${topicDelta.toStringAsFixed(topicDelta == topicDelta.toInt() ? 0 : 1)}%",
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontSize: context.s(12),
                                            color: widget.accentColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                  // Subtasks or Counter details
                                  if (isCounter) ...[
                                    Builder(
                                      builder: (context) {
                                        final current = topicJson['currentCount'] as int? ?? 0;
                                        final initial = topicJson['initialCount'] as int? ?? 0;
                                        final countDelta = current - initial;

                                        return Padding(
                                          padding: EdgeInsets.only(left: context.s(8), top: context.s(2)),
                                          child: Row(
                                            children: [
                                              Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: context.s(12)),
                                              SizedBox(width: context.s(6)),
                                              Text(
                                                "count: ",
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white38,
                                                  fontSize: context.s(12),
                                                ),
                                              ),
                                              Text(
                                                "+${topicDelta.toStringAsFixed(topicDelta == topicDelta.toInt() ? 0 : 1)}% ",
                                                style: GoogleFonts.outfit(
                                                  color: widget.accentColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: context.s(12),
                                                ),
                                              ),
                                              Text(
                                                "(+$countDelta)",
                                                style: GoogleFonts.outfit(
                                                  color: widget.accentColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: context.s(12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ] else ...[
                                    // Checklist tasks
                                    ...(topicJson['tasks'] as List<dynamic>? ?? []).map((taskName) {
                                      return Padding(
                                        padding: EdgeInsets.only(left: context.s(12), top: context.s(2)),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(top: context.s(2)),
                                              child: Icon(
                                                Icons.check_circle_outline_rounded,
                                                color: widget.accentColor.withAlpha(180),
                                                size: context.s(12),
                                              ),
                                            ),
                                            SizedBox(width: context.s(6)),
                                            Expanded(
                                              child: Text(
                                                taskName as String? ?? '',
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white54,
                                                  fontSize: context.s(12),
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      } catch (e) {
        // Fallback below if JSON decode fails
        debugPrint("Error parsing achievements JSON: $e");
      }
    }

    // Fallback: Legacy plain text presentation
    return Container(
      constraints: BoxConstraints(maxHeight: context.s(widget.maxWidgetHeight)),
      padding: EdgeInsets.all(context.s(12)),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(context.s(12)),
      ),
      child: RawScrollbar(
        controller: _scrollController2,
        thumbColor: widget.accentColor.withAlpha(120),
        radius: Radius.circular(context.s(4)),
        thickness: context.s(3.5),
        fadeDuration: const Duration(milliseconds: 300),
        timeToFade: const Duration(milliseconds: 800),
        thumbVisibility: false,
        child: SingleChildScrollView(
          controller: _scrollController2,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(right: context.s(8)),
            child: Text(
              accomplishmentsText,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: context.s(12),
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
