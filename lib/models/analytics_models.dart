class FormAnalytics {
  final String formId;
  final String title;
  final int responseCount;
  final Map<String, double> numericAverages;
  final List<QuestionAnalytics> questionAnalytics;

  FormAnalytics({
    required this.formId,
    required this.title,
    required this.responseCount,
    required this.numericAverages,
    required this.questionAnalytics,
  });
}

class QuestionAnalytics {
  final String questionId;
  final String questionTitle;
  final String questionType;
  final Map<String, int> responseCounts; // For rating: "1" -> 5, "2" -> 10, etc.
  final double? average;
  final int totalResponses;

  QuestionAnalytics({
    required this.questionId,
    required this.questionTitle,
    required this.questionType,
    required this.responseCounts,
    this.average,
    required this.totalResponses,
  });

  // Get rating distribution for pie/bar charts (for rating type questions)
  List<RatingData> getRatingDistribution() {
    if (questionType != 'rating') return [];
    
    List<RatingData> distribution = [];
    
    // For ratings, typically 1-5 scale
    for (int rating = 1; rating <= 5; rating++) {
      final count = responseCounts[rating.toString()] ?? 0;
      final percentage = totalResponses > 0 ? (count / totalResponses) * 100 : 0.0;
      
      distribution.add(RatingData(
        rating: rating,
        count: count,
        percentage: percentage,
        label: '$rating Star${rating == 1 ? '' : 's'}',
      ));
    }
    
    return distribution;
  }

  // Check if this question type can be visualized as a chart
  bool canBeVisualized() {
    return ['rating', 'multiple_choice', 'dropdown', 'checkboxes', 'true_false', 'yes_no'].contains(questionType);
  }

  // Get top responses for multiple choice questions
  List<ResponseData> getTopResponses({int limit = 5}) {
    var sortedEntries = responseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(limit).map((entry) {
      final percentage = totalResponses > 0 ? (entry.value / totalResponses) * 100 : 0.0;
      return ResponseData(
        response: entry.key,
        count: entry.value,
        percentage: percentage,
      );
    }).toList();
  }
}

class RatingData {
  final int rating;
  final int count;
  final double percentage;
  final String label;

  RatingData({
    required this.rating,
    required this.count,
    required this.percentage,
    required this.label,
  });
}

class ResponseData {
  final String response;
  final int count;
  final double percentage;

  ResponseData({
    required this.response,
    required this.count,
    required this.percentage,
  });
}

// Helper class for chart colors
class ChartColors {
  static const List<int> ratingColors = [
    0xFFFF6B6B, // Red for 1 star
    0xFFFF9F43, // Orange for 2 stars  
    0xFFFFD93D, // Yellow for 3 stars
    0xFF6BCF7F, // Light green for 4 stars
    0xFF4ECDC4, // Teal for 5 stars
  ];

  static const List<int> categoryColors = [
    0xFF1A73E8,
    0xFF6B73FF,
    0xFF9C27B0,
    0xFFE91E63,
    0xFFF44336,
    0xFFFF9800,
    0xFFFFEB3B,
    0xFF8BC34A,
    0xFF4CAF50,
    0xFF009688,
    0xFF00BCD4,
    0xFF03A9F4,
    0xFF2196F3,
    0xFF3F51B5,
    0xFF673AB7,
  ];

  static int getRatingColor(int rating) {
    if (rating >= 1 && rating <= 5) {
      return ratingColors[rating - 1];
    }
    return 0xFF9E9E9E; // Grey for unknown ratings
  }

  static int getCategoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }
}
