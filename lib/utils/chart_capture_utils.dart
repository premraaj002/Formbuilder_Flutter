import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/analytics_models.dart';
import '../widgets/analytics_charts.dart';

class ChartCaptureUtils {
  /// Captures a chart widget as PNG image bytes
  static Future<Uint8List?> captureChartAsImage(
    QuestionAnalytics questionAnalytics, {
    String chartType = 'pie',
    double width = 400,
    double height = 400,
  }) async {
    try {
      // Create a widget tree for the chart
      final chartWidget = chartType == 'pie'
          ? RatingPieChart(
              questionAnalytics: questionAnalytics,
              size: width < height ? width : height,
            )
          : RatingBarChart(
              questionAnalytics: questionAnalytics,
              height: height,
            );

      // Create a container with white background for the chart
      final container = Container(
        width: width,
        height: height,
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: chartWidget,
      );

      // Use a custom approach to render the widget
      final imageBytes = await _renderWidgetToImage(
        container,
        Size(width, height),
      );

      return imageBytes;
    } catch (e) {
      print('Error capturing chart as image: $e');
      return null;
    }
  }

  /// Captures multiple charts as a single combined image
  static Future<Uint8List?> captureMultipleCharts(
    List<QuestionAnalytics> questionAnalytics, {
    String chartType = 'pie',
    double chartWidth = 300,
    double chartHeight = 300,
    int chartsPerRow = 2,
  }) async {
    if (questionAnalytics.isEmpty) return null;

    try {
      final rows = (questionAnalytics.length / chartsPerRow).ceil();
      final totalWidth = (chartWidth * chartsPerRow) + (16 * (chartsPerRow + 1));
      final totalHeight = (chartHeight * rows) + (16 * (rows + 1));

      final charts = <Widget>[];
      
      for (final analytics in questionAnalytics) {
        final chartWidget = chartType == 'pie'
            ? RatingPieChart(
                questionAnalytics: analytics,
                size: chartWidth < chartHeight ? chartWidth : chartHeight,
              )
            : RatingBarChart(
                questionAnalytics: analytics,
                height: chartHeight,
              );

        charts.add(
          Container(
            width: chartWidth,
            height: chartHeight,
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: chartWidget,
          ),
        );
      }

      final combinedWidget = Container(
        width: totalWidth,
        height: totalHeight,
        color: Colors.grey[50],
        padding: const EdgeInsets.all(8),
        child: Wrap(
          children: charts,
        ),
      );

      final imageBytes = await _renderWidgetToImage(
        combinedWidget,
        Size(totalWidth, totalHeight),
      );

      return imageBytes;
    } catch (e) {
      print('Error capturing multiple charts: $e');
      return null;
    }
  }

  /// Renders a widget to image bytes using Flutter's rendering system
  /// Note: This is a placeholder for future image capture implementation
  static Future<Uint8List?> _renderWidgetToImage(
    Widget widget,
    Size size,
  ) async {
    try {
      // Image capture is complex in Flutter and requires proper context
      // For now, return null to indicate no image capture
      // This can be implemented in the future with proper widget rendering
      return null;
    } catch (e) {
      print('Error rendering widget to image: $e');
      return null;
    }
  }

  /// Creates a simple text-based chart representation for Excel
  static List<List<String>> createTextChart(QuestionAnalytics questionAnalytics) {
    final ratingData = questionAnalytics.getRatingDistribution();
    
    final rows = <List<String>>[];
    
    // Header
    rows.add(['Rating', 'Count', 'Percentage', 'Visual']);
    
    // Data rows with simple text visualization
    for (final data in ratingData) {
      if (data.count > 0) {
        final barLength = (data.percentage / 10).round(); // Scale to 0-10
        final visualBar = '█' * barLength;
        
        rows.add([
          '${data.rating} Star${data.rating == 1 ? '' : 's'}',
          data.count.toString(),
          '${data.percentage.toStringAsFixed(1)}%',
          visualBar,
        ]);
      }
    }
    
    // Add summary
    rows.add(['', '', '', '']);
    rows.add(['Average:', questionAnalytics.average?.toStringAsFixed(2) ?? 'N/A', '', '']);
    rows.add(['Total Responses:', questionAnalytics.totalResponses.toString(), '', '']);
    
    return rows;
  }

  /// Creates a data table for Excel export
  static List<List<String>> createDataTable(QuestionAnalytics questionAnalytics) {
    final ratingData = questionAnalytics.getRatingDistribution();
    
    final rows = <List<String>>[];
    
    // Question info
    rows.add(['Question:', questionAnalytics.questionTitle]);
    rows.add(['Type:', questionAnalytics.questionType]);
    rows.add(['Total Responses:', questionAnalytics.totalResponses.toString()]);
    rows.add(['Average Rating:', questionAnalytics.average?.toStringAsFixed(2) ?? 'N/A']);
    rows.add(['']); // Empty row
    
    // Rating distribution
    rows.add(['Rating Distribution:']);
    rows.add(['Rating', 'Count', 'Percentage']);
    
    for (final data in ratingData) {
      rows.add([
        '${data.rating} Star${data.rating == 1 ? '' : 's'}',
        data.count.toString(),
        '${data.percentage.toStringAsFixed(1)}%',
      ]);
    }
    
    return rows;
  }
}
