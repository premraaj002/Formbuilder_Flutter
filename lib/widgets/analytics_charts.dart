import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analytics_models.dart';
import '../utils/responsive.dart';

class RatingPieChart extends StatefulWidget {
  final QuestionAnalytics questionAnalytics;
  final double? size;

  const RatingPieChart({
    Key? key,
    required this.questionAnalytics,
    this.size,
  }) : super(key: key);

  @override
  State<RatingPieChart> createState() => _RatingPieChartState();
}

class _RatingPieChartState extends State<RatingPieChart> {
  int touchedIndex = -1;

  // Convert non-rating responses to chart data format
  List<RatingData> _convertToChartData() {
    final responseCounts = widget.questionAnalytics.responseCounts;
    final totalResponses = widget.questionAnalytics.totalResponses;
    
    if (totalResponses == 0) return [];
    
    final List<RatingData> chartData = [];
    int index = 1;
    
    for (final entry in responseCounts.entries) {
      final count = entry.value;
      final percentage = (count / totalResponses) * 100;
      
      chartData.add(RatingData(
        rating: index, // Use index as rating for visualization
        count: count,
        percentage: percentage,
        label: entry.key, // Use the actual response text as label
      ));
      index++;
    }
    
    return chartData;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Check if this is a rating question or other visualizable question
    List<RatingData> chartData;
    if (widget.questionAnalytics.questionType == 'rating') {
      chartData = widget.questionAnalytics.getRatingDistribution();
    } else {
      // Convert response data to rating-like format for other question types
      chartData = _convertToChartData();
    }
    
    if (chartData.isEmpty || widget.questionAnalytics.totalResponses == 0) {
      return _buildEmptyState(context);
    }

    final chartSize = widget.size ?? Responsive.valueWhen(
      context,
      mobile: 200.0,
      desktop: 250.0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Chart Title
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            widget.questionAnalytics.questionTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Pie Chart
        Flexible(
          child: Center(
            child: Container(
              width: (chartSize ?? 200.0) * 0.75,
              height: (chartSize ?? 200.0) * 0.75,
              padding: const EdgeInsets.all(8),
              child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: (chartSize ?? 200.0) * 0.1,
                sections: _generatePieSections(chartData),
              ),
            ),
          ),
        ),
        ),

        const SizedBox(height: 12),

        // Legend
        Center(child: _buildLegend(context, chartData)),

        const SizedBox(height: 6),

        // Stats
        Center(child: _buildStats(context)),
      ],
    );
  }

  List<PieChartSectionData> _generatePieSections(List<RatingData> ratingData) {
    return ratingData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 70.0 : 60.0; // Reduced radius to fit in smaller container
      final fontSize = isTouched ? 14.0 : 12.0; // Adjusted font size

      return PieChartSectionData(
        color: Color(ChartColors.getRatingColor(data.rating)),
        value: data.count.toDouble(),
        title: data.count > 0 ? '${data.percentage.toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
        badgeWidget: isTouched ? _buildBadge(data) : null,
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

  Widget _buildBadge(RatingData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${data.count} responses',
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, List<RatingData> ratingData) {
    final theme = Theme.of(context);
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: ratingData.where((data) => data.count > 0).map((data) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Color(ChartColors.getRatingColor(data.rating)),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.questionAnalytics.questionType == 'rating' 
                  ? '${data.rating}★ (${data.count})'
                  : '${data.label} (${data.count})',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final average = widget.questionAnalytics.average;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Avg: ${average?.toStringAsFixed(1) ?? 'N/A'}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.questionAnalytics.totalResponses} responses',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No responses yet',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.questionAnalytics.questionTitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class RatingBarChart extends StatelessWidget {
  final QuestionAnalytics questionAnalytics;
  final double? height;

  const RatingBarChart({
    Key? key,
    required this.questionAnalytics,
    this.height,
  }) : super(key: key);

  // Convert non-rating responses to chart data format
  List<RatingData> _convertToChartData() {
    final responseCounts = questionAnalytics.responseCounts;
    final totalResponses = questionAnalytics.totalResponses;
    
    if (totalResponses == 0) return [];
    
    final List<RatingData> chartData = [];
    int index = 1;
    
    for (final entry in responseCounts.entries) {
      final count = entry.value;
      final percentage = (count / totalResponses) * 100;
      
      chartData.add(RatingData(
        rating: index, // Use index as rating for visualization
        count: count,
        percentage: percentage,
        label: entry.key, // Use the actual response text as label
      ));
      index++;
    }
    
    return chartData;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Check if this is a rating question or other visualizable question
    List<RatingData> chartData;
    if (questionAnalytics.questionType == 'rating') {
      chartData = questionAnalytics.getRatingDistribution();
    } else {
      // Convert response data to rating-like format for other question types
      chartData = _convertToChartData();
    }
    
    if (chartData.isEmpty || questionAnalytics.totalResponses == 0) {
      return _buildEmptyState(context);
    }

    final chartHeight = height ?? Responsive.valueWhen(
      context,
      mobile: 200.0,
      desktop: 250.0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart Title
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            questionAnalytics.questionTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Bar Chart
        Flexible(
          child: SizedBox(
            height: (chartHeight ?? 200.0) * 0.8, // Reduce chart height
            child: BarChart(
              BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: chartData.map((e) => e.count.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final data = chartData[groupIndex];
                    final title = questionAnalytics.questionType == 'rating'
                        ? '${data.rating} Star${data.rating == 1 ? '' : 's'}'
                        : data.label;
                    return BarTooltipItem(
                      '$title\n',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '${data.count} responses (${data.percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < chartData.length) {
                        final data = chartData[index];
                        final label = questionAnalytics.questionType == 'rating'
                            ? '${data.rating}★'
                            : data.label.length > 8 
                                ? '${data.label.substring(0, 8)}...'
                                : data.label;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: chartData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data.count.toDouble(),
                      color: Color(ChartColors.getRatingColor(data.rating)),
                      width: Responsive.valueWhen(context, mobile: 20, desktop: 24),
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(ChartColors.getRatingColor(data.rating)),
                          Color(ChartColors.getRatingColor(data.rating)).withOpacity(0.8),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Stats
        _buildStats(context),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final average = questionAnalytics.average;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            context,
            'Average Rating',
            '${average?.toStringAsFixed(1) ?? 'N/A'}',
            Icons.star_rounded,
            colorScheme.primary,
          ),
          Container(
            width: 1,
            height: 30,
            color: colorScheme.outline.withOpacity(0.2),
          ),
          _buildStatItem(
            context,
            'Total Responses',
            '${questionAnalytics.totalResponses}',
            Icons.people_outlined,
            colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No responses yet',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            questionAnalytics.questionTitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class AnalyticsCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AnalyticsCard({
    Key? key,
    required this.child,
    this.padding,
    this.onTap,
  }) : super(key: key);

  @override
  State<AnalyticsCard> createState() => _AnalyticsCardState();
}

class _AnalyticsCardState extends State<AnalyticsCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Widget cardWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: widget.padding ?? const EdgeInsets.all(20),
      transform: isHovered ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHovered 
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.1),
          width: isHovered ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(isHovered ? 0.15 : 0.08),
            blurRadius: isHovered ? 24 : 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: () {
          print('AnalyticsCard tapped!');
          widget.onTap!();
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}
