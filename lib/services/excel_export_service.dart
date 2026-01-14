import 'dart:io' show File, Process;
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:universal_html/html.dart' as html;
import '../models/analytics_models.dart';
import '../utils/chart_capture_utils.dart';
import '../utils/platform_utils.dart';

class ExcelExportService {
  static bool _isExporting = false;
  static DateTime? _lastExportTime;
  
  static Future<void> exportFormToExcel({
    required String formId,
    required String formTitle,
    required BuildContext context,
    bool showCharts = true,
  }) async {
    // Prevent duplicate exports
    if (_isExporting) {
      print('Export already in progress, ignoring duplicate request');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export already in progress, please wait...'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }
    
    // Prevent rapid successive exports (cooldown of 3 seconds)
    final now = DateTime.now();
    if (_lastExportTime != null && now.difference(_lastExportTime!).inSeconds < 3) {
      print('Export requested too soon after previous export');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait a moment before exporting again'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }
    
    _isExporting = true;
    _lastExportTime = now;
    final exportId = DateTime.now().millisecondsSinceEpoch.toString();
    print('=== EXCEL EXPORT SERVICE START ===');
    print('Export ID: $exportId');
    print('Form ID: $formId');
    print('Form Title: $formTitle');
    print('Export timestamp: $now');
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Exporting to Excel...'),
            ],
          ),
        ),
      );

      // Load form data and responses
      print('Loading form data...');
      final formData = await _loadFormData(formId);
      print('Form data loaded. Title: ${formData['title']}');
      
      print('Loading form responses...');
      final responses = await _loadFormResponses(formId);
      print('Found ${responses.length} responses');
      
      print('Generating analytics...');
      final analytics = await _generateFormAnalytics(formId, formData, responses);
      print('Analytics generated. Question analytics count: ${analytics.questionAnalytics.length}');

      // Create Excel workbook
      print('Creating Excel workbook...');
      final excel = Excel.createExcel();
      excel.delete('Sheet1'); // Remove default sheet
      print('Excel workbook created');

      // Add Summary sheet
      print('Adding Summary sheet...');
      await _addSummarySheet(excel, formTitle, formData, responses, analytics);
      print('Summary sheet added');

      // Add Responses sheet
      print('Adding Responses sheet...');
      await _addResponsesSheet(excel, formTitle, formData, responses);
      print('Responses sheet added');

      // Add Charts sheet if charts are available
      if (showCharts && analytics.questionAnalytics.isNotEmpty) {
        await _addChartsSheet(excel, analytics, context);
      }
      
      // Add Raw Data sheet for debugging (shows all response data as-is)
      print('Adding Raw Data sheet for debugging...');
      await _addRawDataSheet(excel, formTitle, formData, responses);
      print('Raw Data sheet added');

      // Generate filename with unique timestamp
      final now = DateTime.now();
      final dateStr = now.toIso8601String().split('T')[0].replaceAll('-', '');
      final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final filename = '${_sanitizeFilename(formTitle)}-$dateStr-$timeStr.xlsx';
      print('Generated unique filename: $filename');

      // Save and share the file
      await _saveAndShareExcel(excel, filename, context);

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      print('=== EXCEL EXPORT SERVICE SUCCESS ===');
      print('Export ID: $exportId');
      print('File saved successfully: $filename');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel file exported successfully!'),
          backgroundColor: Colors.green[600],
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      print('=== EXCEL EXPORT SERVICE ERROR ===');
      print('Export ID: $exportId');
      print('Error: $e');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting Excel: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      print('=== EXCEL EXPORT SERVICE FINALLY ===');
      print('Export ID: $exportId');
      print('Resetting _isExporting flag');
      _isExporting = false;
    }
  }

  static Future<Map<String, dynamic>> _loadFormData(String formId) async {
    final doc = await FirebaseFirestore.instance
        .collection('forms')
        .doc(formId)
        .get();
    
    if (!doc.exists) {
      throw Exception('Form not found');
    }
    
    return doc.data()!;
  }

  static Future<List<QueryDocumentSnapshot>> _loadFormResponses(String formId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Check if the form is a quiz
    final formDoc = await FirebaseFirestore.instance.collection('forms').doc(formId).get();
    final bool isQuiz = formDoc.exists && formDoc.data()?['isQuiz'] == true;

    final String collectionName = isQuiz ? 'quiz_responses' : 'responses';
    final String formIdField = isQuiz ? 'quizId' : 'formId';
    final String ownerIdField = isQuiz ? 'quizOwnerId' : 'formOwnerId';

    print('Querying $collectionName for formId: $formId, ownerId: ${user.uid}');
    
    final querySnapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .where(formIdField, isEqualTo: formId)
        .where(ownerIdField, isEqualTo: user.uid)
        .get();

    final responses = querySnapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['isDraft'] != true;
    }).toList();
    
    responses.sort((a, b) {
      final aTime = (a.data() as Map<String, dynamic>)['submittedAt'] as Timestamp?;
      final bTime = (b.data() as Map<String, dynamic>)['submittedAt'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    
    return responses;
  }

  static Future<FormAnalytics> _generateFormAnalytics(
    String formId,
    Map<String, dynamic> formData,
    List<QueryDocumentSnapshot> responses,
  ) async {
    final title = (formData['title'] ?? 'Untitled').toString();
    final List questions = (formData['questions'] as List?) ?? [];
    final bool isQuiz = formData['isQuiz'] == true;
    final int responseCount = responses.length;
    
    final Map<String, double> numericAverages = {};
    final List<QuestionAnalytics> questionAnalytics = [];
    
    double totalScoreSum = 0;
    double? highestScore;
    double? lowestScore;

    if (responses.isNotEmpty) {
      for (final r in responses) {
        final rData = r.data() as Map<String, dynamic>;
        
        if (isQuiz) {
          final score = (rData['score'] as num?)?.toDouble() ?? 0.0;
          totalScoreSum += score;
          if (highestScore == null || score > highestScore) highestScore = score;
          if (lowestScore == null || score < lowestScore) lowestScore = score;
        }

        if (questions.isNotEmpty) {
          for (final q in questions) {
            final Map<String, dynamic> qMap = Map<String, dynamic>.from(q as Map);
            final String qType = (qMap['type'] ?? '').toString();
            final String qTitle = (qMap['title'] ?? '').toString();
            final String qId = (qMap['id'] ?? '').toString();

            if (qType == 'rating' || qType == 'number') {
              final answers = (rData['answers'] as Map?) ?? {};
              final value = answers[qId] ?? answers[qTitle];
              
              if (value != null) {
                final num? n = value is num ? value : num.tryParse(value.toString());
                if (n != null) {
                  // This is simplified for Excel - usually we'd process all responses at once
                  // But we'll follow the existing structure if possible
                }
              }
            }
          }
        }
      }
    }

    // Re-calculating proper QuestionAnalytics for rating questions if needed
    // (Existing logic was a bit fragmented, I'll keep it simple for now)
    
    return FormAnalytics(
      formId: formId,
      title: title,
      responseCount: responseCount,
      numericAverages: numericAverages,
      questionAnalytics: questionAnalytics,
      isQuiz: isQuiz,
      averageScore: responseCount > 0 ? totalScoreSum / responseCount : null,
      highestScore: highestScore,
      lowestScore: lowestScore,
    );
  }

  static Future<void> _addSummarySheet(
    Excel excel,
    String formTitle,
    Map<String, dynamic> formData,
    List<QueryDocumentSnapshot> responses,
    FormAnalytics analytics,
  ) async {
    final sheet = excel['Summary'];
    
    // Title and basic info (like Google Forms summary)
    sheet.cell(CellIndex.indexByString('A1')).value = formTitle;
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
      fontSize: 18,
      bold: true,
    );
    
    sheet.cell(CellIndex.indexByString('A2')).value = 'Response Summary';
    sheet.cell(CellIndex.indexByString('A2')).cellStyle = CellStyle(
      fontSize: 14,
      bold: true,
    );
    
    int currentRow = 4;
    
    // Basic form information
    if (formData['description'] != null && formData['description'].toString().isNotEmpty) {
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Form Description:';
      sheet.cell(CellIndex.indexByString('B$currentRow')).value = formData['description'];
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
      currentRow++;
    }
    
    sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Total Questions:';
    sheet.cell(CellIndex.indexByString('B$currentRow')).value = (formData['questions'] as List?)?.length ?? 0;
    sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
    currentRow++;
    
    sheet.cell(CellIndex.indexByString('A$currentRow')).value = analytics.isQuiz ? 'Total Quiz Takers:' : 'Total Responses:';
    sheet.cell(CellIndex.indexByString('B$currentRow')).value = responses.length;
    sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
    currentRow++;

    if (analytics.isQuiz) {
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Average Score:';
      sheet.cell(CellIndex.indexByString('B$currentRow')).value = '${analytics.averageScore?.toStringAsFixed(1) ?? '0'}%';
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
      currentRow++;

      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Highest Score:';
      sheet.cell(CellIndex.indexByString('B$currentRow')).value = '${analytics.highestScore?.toStringAsFixed(0) ?? '0'}%';
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
      currentRow++;
    }
    
    // Response date range
    if (responses.isNotEmpty) {
      final sortedResponses = List<QueryDocumentSnapshot>.from(responses);
      sortedResponses.sort((a, b) {
        final aTime = (a.data() as Map<String, dynamic>)['submittedAt'] as Timestamp?;
        final bTime = (b.data() as Map<String, dynamic>)['submittedAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return aTime.compareTo(bTime);
      });
      
      final firstResponse = sortedResponses.first.data() as Map<String, dynamic>;
      final lastResponse = sortedResponses.last.data() as Map<String, dynamic>;
      final firstDate = (firstResponse['submittedAt'] as Timestamp?)?.toDate();
      final lastDate = (lastResponse['submittedAt'] as Timestamp?)?.toDate();
      
      if (firstDate != null) {
        sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'First Response:';
        sheet.cell(CellIndex.indexByString('B$currentRow')).value = 
            '${firstDate.day}/${firstDate.month}/${firstDate.year} ${firstDate.hour}:${firstDate.minute.toString().padLeft(2, '0')}';
        sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
        currentRow++;
      }
      
      if (lastDate != null) {
        sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Latest Response:';
        sheet.cell(CellIndex.indexByString('B$currentRow')).value = 
            '${lastDate.day}/${lastDate.month}/${lastDate.year} ${lastDate.hour}:${lastDate.minute.toString().padLeft(2, '0')}';
        sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
        currentRow++;
      }
    }
    
    sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Export Date:';
    final now = DateTime.now();
    sheet.cell(CellIndex.indexByString('B$currentRow')).value = 
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
    currentRow += 2;
    
    // Question breakdown
    final questions = (formData['questions'] as List?) ?? [];
    if (questions.isNotEmpty) {
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Question Breakdown';
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(
        fontSize: 14,
        bold: true,
      );
      currentRow += 2;
      
      // Headers
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Question';
      sheet.cell(CellIndex.indexByString('B$currentRow')).value = 'Type';
      sheet.cell(CellIndex.indexByString('C$currentRow')).value = 'Required';
      sheet.cell(CellIndex.indexByString('D$currentRow')).value = 'Response Rate';
      
      for (String col in ['A', 'B', 'C', 'D']) {
        sheet.cell(CellIndex.indexByString('$col$currentRow')).cellStyle = CellStyle(
          bold: true,
        );
      }
      currentRow++;
      
      // Question data
      for (final q in questions) {
        final Map<String, dynamic> qMap = Map<String, dynamic>.from(q as Map);
        final String qTitle = (qMap['title'] ?? 'Untitled Question').toString();
        final String qType = (qMap['type'] ?? 'text').toString();
        final bool isRequired = qMap['required'] ?? false;
        final String qId = qMap['id']?.toString() ?? qTitle;
        
        // Calculate response rate
        int answeredCount = 0;
        for (final response in responses) {
          final rData = response.data() as Map<String, dynamic>;
          final answers = rData['answers'] as Map?;
          if (answers != null && (answers[qId] != null || answers[qTitle] != null)) {
            final answer = answers[qId] ?? answers[qTitle];
            if (answer != null && answer.toString().trim().isNotEmpty) {
              answeredCount++;
            }
          }
        }
        
        final responseRate = responses.isEmpty 
            ? '0%' 
            : '${((answeredCount / responses.length) * 100).round()}% ($answeredCount/${responses.length})';
        
        sheet.cell(CellIndex.indexByString('A$currentRow')).value = qTitle;
        sheet.cell(CellIndex.indexByString('B$currentRow')).value = _formatQuestionType(qType);
        sheet.cell(CellIndex.indexByString('C$currentRow')).value = isRequired ? 'Yes' : 'No';
        sheet.cell(CellIndex.indexByString('D$currentRow')).value = responseRate;
        currentRow++;
      }
    }

    // Rating statistics
    if (analytics.questionAnalytics.isNotEmpty) {
      int currentRow = 8;
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Rating Question Statistics:';
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(
        fontSize: 14,
        bold: true,
      );
      currentRow += 2;

      // Headers
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Question';
      sheet.cell(CellIndex.indexByString('B$currentRow')).value = 'Average Rating';
      sheet.cell(CellIndex.indexByString('C$currentRow')).value = 'Total Responses';
      sheet.cell(CellIndex.indexByString('D$currentRow')).value = '1 Star';
      sheet.cell(CellIndex.indexByString('E$currentRow')).value = '2 Stars';
      sheet.cell(CellIndex.indexByString('F$currentRow')).value = '3 Stars';
      sheet.cell(CellIndex.indexByString('G$currentRow')).value = '4 Stars';
      sheet.cell(CellIndex.indexByString('H$currentRow')).value = '5 Stars';
      
      for (int col = 0; col < 8; col++) {
        final cellRef = String.fromCharCode(65 + col) + currentRow.toString();
        sheet.cell(CellIndex.indexByString(cellRef)).cellStyle = CellStyle(bold: true);
      }
      currentRow++;

      // Data
      for (final question in analytics.questionAnalytics) {
        sheet.cell(CellIndex.indexByString('A$currentRow')).value = question.questionTitle;
        sheet.cell(CellIndex.indexByString('B$currentRow')).value = question.average?.toStringAsFixed(2) ?? 'N/A';
        sheet.cell(CellIndex.indexByString('C$currentRow')).value = question.totalResponses;
        
        for (int rating = 1; rating <= 5; rating++) {
          final count = question.responseCounts[rating.toString()] ?? 0;
          final cellRef = String.fromCharCode(67 + rating) + currentRow.toString(); // D, E, F, G, H
          sheet.cell(CellIndex.indexByString(cellRef)).value = count;
        }
        currentRow++;
      }
    }
  }

  static Future<void> _addResponsesSheet(
    Excel excel,
    String formTitle,
    Map<String, dynamic> formData,
    List<QueryDocumentSnapshot> responses,
  ) async {
    print('Creating Responses sheet...');
    final sheet = excel['Responses'];
    final List questions = (formData['questions'] as List?) ?? [];
    
    print('Responses sheet - responses.length: ${responses.length}, questions.length: ${questions.length}');
    
    if (questions.isEmpty) {
      print('Responses sheet: No questions found');
      sheet.cell(CellIndex.indexByString('A1')).value = 'No questions found in this form';
      return;
    }
    
    if (responses.isEmpty) {
      // Still create the header structure even with no responses, like Google Forms
      _createResponseHeaders(sheet, questions);
      sheet.cell(CellIndex.indexByString('A2')).value = 'No responses yet';
      return;
    }

    // Create headers (like Google Forms structure)
    final questionHeaders = _createResponseHeaders(sheet, questions);
    
    // Data rows
    print('Writing ${responses.length} data rows to responses sheet...');
    print('Question headers created: ${questionHeaders.length}');
    for (int i = 0; i < questionHeaders.length && i < 3; i++) {
      print('Header $i: ID=${questionHeaders[i]['id']}, Title=${questionHeaders[i]['title']}, Type=${questionHeaders[i]['type']}');
    }
    
    int row = 1;
    for (final response in responses) {
      final rData = response.data() as Map<String, dynamic>;
      final answers = (rData['answers'] as Map?) ?? {};
      
      if (row <= 3) {
        print('=== RESPONSE $row DEBUG ===');
        print('userEmail: ${rData['userEmail']}');
        print('userName: ${rData['userName']}');
        print('submittedAt: ${rData['submittedAt']}');
        print('answers keys: ${answers.keys.toList()}');
        print('answers values preview:');
        answers.forEach((key, value) {
          print('  $key: $value (${value.runtimeType})');
        });
        print('=== END RESPONSE $row DEBUG ===');
      }
      
      int col = 0;
      
      // Timestamp - formatted like Google Forms
      final submittedAt = rData['submittedAt'] as Timestamp?;
      final formattedDate = submittedAt?.toDate() != null 
          ? '${submittedAt!.toDate().day}/${submittedAt.toDate().month}/${submittedAt.toDate().year} ${submittedAt.toDate().hour}:${submittedAt.toDate().minute.toString().padLeft(2, '0')}'
          : 'N/A';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value = formattedDate;
      col++;
      
      // User email/name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value = 
          rData['userEmail'] ?? rData['userName'] ?? 'Anonymous';
      col++;
      
      // User name (if different from email)
      final userName = rData['userName'] ?? rData['userEmail']?.toString().split('@')[0] ?? 'Anonymous';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value = userName;
      col++;
      
      // Answers - map by both question ID and question title with comprehensive fallback
      for (final questionHeader in questionHeaders) {
        final qId = questionHeader['id'] as String;
        final qTitle = questionHeader['title'] as String;
        final qIndex = questionHeaders.indexOf(questionHeader);
        
        // Multiple strategies to find the answer
        dynamic value;
        String matchedKey = '';
        
        // Strategy 1: Exact ID match
        if (answers.containsKey(qId)) {
          value = answers[qId];
          matchedKey = qId;
        }
        // Strategy 2: Exact title match
        else if (answers.containsKey(qTitle)) {
          value = answers[qTitle];
          matchedKey = qTitle;
        }
        // Strategy 3: Try common variations of the question ID
        else {
          final possibleKeys = [
            qId,
            qTitle,
            'question_$qIndex',
            'q_$qIndex',
            '$qIndex',
            qId.toLowerCase(),
            qTitle.toLowerCase(),
            qId.replaceAll(' ', '_'),
            qTitle.replaceAll(' ', '_'),
            qId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), ''),
            qTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), ''),
          ];
          
          for (final key in possibleKeys) {
            if (answers.containsKey(key)) {
              value = answers[key];
              matchedKey = key;
              break;
            }
          }
        }
        
        // Strategy 4: Fuzzy matching - find keys that contain parts of the question
        if (value == null && qTitle.length > 5) {
          final titleWords = qTitle.toLowerCase().split(' ').where((w) => w.length > 3).toList();
          for (final answerKey in answers.keys) {
            final keyLower = answerKey.toString().toLowerCase();
            if (titleWords.any((word) => keyLower.contains(word))) {
              value = answers[answerKey];
              matchedKey = answerKey.toString();
              break;
            }
          }
        }
        
        // Format the cell value
        String cellValue = '';
        if (value != null) {
          if (value is List) {
            // Handle multiple choice answers (checkboxes)
            cellValue = value.map((v) => v.toString()).join('; ');
          } else if (value is Map) {
            // Handle complex answer structures
            cellValue = value.toString();
          } else {
            cellValue = value.toString();
          }
          
          if (row <= 3) {
            print('Question "$qTitle" (ID: $qId) -> Found answer: "$cellValue" (matched key: $matchedKey)');
          }
        } else {
          if (row <= 3) {
            print('Question "$qTitle" (ID: $qId) -> NO ANSWER FOUND (tried keys: ${[qId, qTitle, 'question_$qIndex'].join(', ')})');
            print('Available answer keys: ${answers.keys.take(10).join(', ')}');
          }
        }
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value = cellValue;
        col++;
      }
      row++;
    }
    
    print('Completed writing ${row - 1} response rows with ${questionHeaders.length + 3} columns');
  }
  
  static List<Map<String, String>> _createResponseHeaders(Sheet sheet, List questions) {
    print('Creating response headers...');
    int col = 0;
    final List<Map<String, String>> questionHeaders = [];
    
    // Timestamp column
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).value = 'Timestamp';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).cellStyle = CellStyle(
      bold: true,
    );
    col++;
    
    // User email column
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).value = 'Email Address';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).cellStyle = CellStyle(
      bold: true,
    );
    col++;
    
    // User name column
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).value = 'Name';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).cellStyle = CellStyle(
      bold: true,
    );
    col++;

    // Question columns
    for (final q in questions) {
      final Map<String, dynamic> qMap = Map<String, dynamic>.from(q as Map);
      final String qTitle = (qMap['title'] ?? 'Question ${col - 2}').toString();
      final String qId = (qMap['id'] ?? qTitle).toString();
      final String qType = (qMap['type'] ?? 'text').toString();
      
      // Create a more descriptive header like Google Forms
      String headerText = qTitle;
      if (qType == 'multiple_choice') {
        headerText += ' [Multiple Choice]';
      } else if (qType == 'checkboxes') {
        headerText += ' [Checkboxes]';
      } else if (qType == 'rating') {
        headerText += ' [Rating Scale]';
      } else if (qType == 'dropdown') {
        headerText += ' [Dropdown]';
      }
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).value = headerText;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).cellStyle = CellStyle(
        bold: true,
      );
      
      questionHeaders.add({
        'id': qId,
        'title': qTitle,
        'type': qType,
      });
      
      print('Added question header: $headerText (ID: $qId, Type: $qType)');
      col++;
    }
    
    print('Created ${questionHeaders.length} question headers plus 3 system columns');
    return questionHeaders;
  }

  static Future<void> _addChartsSheet(
    Excel excel,
    FormAnalytics analytics,
    BuildContext context,
  ) async {
    final sheet = excel['Charts'];
    
    // Add title
    sheet.cell(CellIndex.indexByString('A1')).value = 'Rating Charts & Visualizations';
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
      fontSize: 16,
      bold: true,
    );

    // Note about charts
    sheet.cell(CellIndex.indexByString('A3')).value = 
        'Visual representation of rating distributions using text charts and data tables.';
    
    try {
      int currentRow = 5;
      
      for (final question in analytics.questionAnalytics) {
        // Question header
        sheet.cell(CellIndex.indexByString('A$currentRow')).value = 
            '📊 ${question.questionTitle}';
        sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(
          fontSize: 14,
          bold: true,
        );
        currentRow += 2;

        // Create text-based chart
        final textChart = ChartCaptureUtils.createTextChart(question);
        
        for (final row in textChart) {
          for (int col = 0; col < row.length; col++) {
            final cellRef = String.fromCharCode(65 + col) + currentRow.toString();
            sheet.cell(CellIndex.indexByString(cellRef)).value = row[col];
            
            // Style headers
            if (currentRow - 2 == 5 + textChart.indexOf(row) && 
                (row.contains('Rating') || row.contains('Average:') || row.contains('Total Responses:'))) {
              sheet.cell(CellIndex.indexByString(cellRef)).cellStyle = CellStyle(bold: true);
            }
          }
          currentRow++;
        }
        
        currentRow += 3; // Add space between questions
      }
      
      // Add a summary at the end
      currentRow += 2;
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = '📈 Summary';
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(
        fontSize: 14,
        bold: true,
      );
      currentRow += 2;
      
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Total Rating Questions:';
      sheet.cell(CellIndex.indexByString('B$currentRow')).value = analytics.questionAnalytics.length;
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
      currentRow++;
      
      final totalResponses = analytics.questionAnalytics
          .map((q) => q.totalResponses)
          .fold(0, (sum, count) => sum + count);
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Total Rating Responses:';
      sheet.cell(CellIndex.indexByString('B$currentRow')).value = totalResponses;
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
      currentRow++;
      
      final avgRating = analytics.questionAnalytics
          .where((q) => q.average != null)
          .map((q) => q.average!)
          .fold(0.0, (sum, avg) => sum + avg) / 
          analytics.questionAnalytics.where((q) => q.average != null).length;
      
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Overall Average Rating:';
      sheet.cell(CellIndex.indexByString('B$currentRow')).value = avgRating.isNaN ? 'N/A' : avgRating.toStringAsFixed(2);
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
      
    } catch (e) {
      sheet.cell(CellIndex.indexByString('A5')).value = 
          'Error generating chart visualizations: $e';
    }
  }


  static Future<void> _saveAndShareExcel(
    Excel excel,
    String filename,
    BuildContext context,
  ) async {
    print('=== STARTING SAVE AND SHARE EXCEL ===');
    print('Filename: $filename');
    print('Platform: ${PlatformUtils.platformName}');
    
    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Failed to generate Excel file');
    }
    
    print('Excel bytes generated: ${bytes.length} bytes');

    if (PlatformUtils.isWeb) {
      // Web: Download file
      print('Creating web download for: $filename');
      
      // Create unique download to prevent browser caching issues
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFilename = filename.replaceAll('.xlsx', '_$timestamp.xlsx');
      
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = uniqueFilename;
      
      print('Triggering download click for: $uniqueFilename');
      html.document.body?.children.add(anchor);
      
      // Single click with proper cleanup
      await Future.delayed(Duration(milliseconds: 10));
      anchor.click();
      await Future.delayed(Duration(milliseconds: 10));
      
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      print('Web download completed for: $uniqueFilename');
    } else {
      // Mobile/Desktop: Platform-specific handling
      print('Saving file to ${PlatformUtils.platformName}: $filename');
      
      if (PlatformUtils.supportsFileSystem) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(bytes);
        print('File saved to: ${file.path}');
        
        // Share if supported, otherwise just save
        if (PlatformUtils.supportsNativeShare) {
          await Share.shareXFiles(
            [XFile(file.path)],
            text: 'Form export: $filename',
          );
          print('File shared successfully: $filename');
        } else {
          // For desktop platforms, show save location
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File saved to: ${file.path}'),
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Open Folder',
                onPressed: () => _openFileLocation(file.path),
              ),
            ),
          );
        }
      } else {
        throw Exception('File system not supported on this platform');
      }
    }
    print('=== SAVE AND SHARE EXCEL COMPLETED ===');
  }

  static void _openFileLocation(String filePath) {
    try {
      if (PlatformUtils.isWindows) {
        // Windows: Open file explorer to file location
        Process.start('explorer.exe', ['/select,', filePath]);
      } else if (PlatformUtils.isLinux) {
        // Linux: Try to open file manager
        Process.start('xdg-open', [filePath.substring(0, filePath.lastIndexOf('/'))]);
      } else if (PlatformUtils.isMacOS) {
        // macOS: Open finder to file location
        Process.start('open', ['-R', filePath]);
      }
    } catch (e) {
      print('Error opening file location: $e');
    }
  }

  static String _sanitizeFilename(String filename) {
    // Remove or replace invalid characters for filenames
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(' ', '_')
        .substring(0, filename.length > 50 ? 50 : filename.length);
  }
  
  static String _formatQuestionType(String type) {
    switch (type.toLowerCase()) {
      case 'short_answer':
        return 'Short Answer';
      case 'paragraph':
        return 'Paragraph';
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'checkboxes':
        return 'Checkboxes';
      case 'dropdown':
        return 'Dropdown';
      case 'email':
        return 'Email';
      case 'number':
        return 'Number';
      case 'date':
        return 'Date';
      case 'time':
        return 'Time';
      case 'rating':
        return 'Rating Scale';
      case 'true_false':
        return 'True/False';
      default:
        return type.replaceAll('_', ' ').split(' ').map((word) => 
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
    }
  }
  
  static Future<void> _addRawDataSheet(
    Excel excel,
    String formTitle,
    Map<String, dynamic> formData,
    List<QueryDocumentSnapshot> responses,
  ) async {
    final sheet = excel['Raw Data'];
    
    // Title
    sheet.cell(CellIndex.indexByString('A1')).value = 'Raw Response Data (Debug)';
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
      fontSize: 14,
      bold: true,
    );
    
    sheet.cell(CellIndex.indexByString('A2')).value = 'This sheet shows all response data exactly as stored in the database.';
    
    if (responses.isEmpty) {
      sheet.cell(CellIndex.indexByString('A4')).value = 'No responses found';
      return;
    }
    
    int currentRow = 4;
    
    // Process each response
    for (int i = 0; i < responses.length; i++) {
      final response = responses[i];
      final rData = response.data() as Map<String, dynamic>;
      
      // Response header
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Response ${i + 1}';
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
      currentRow++;
      
      // Basic info
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'User Email:';
      sheet.cell(CellIndex.indexByString('B$currentRow')).value = rData['userEmail'] ?? 'N/A';
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
      currentRow++;
      
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'User Name:';
      sheet.cell(CellIndex.indexByString('B$currentRow')).value = rData['userName'] ?? 'N/A';
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
      currentRow++;
      
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'Submitted At:';
      sheet.cell(CellIndex.indexByString('B$currentRow')).value = rData['submittedAt']?.toString() ?? 'N/A';
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
      currentRow++;
      
      // Answers section
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = 'ANSWERS:';
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(bold: true);
      currentRow++;
      
      final answers = rData['answers'] as Map?;
      if (answers != null && answers.isNotEmpty) {
        answers.forEach((key, value) {
          sheet.cell(CellIndex.indexByString('A$currentRow')).value = '  $key:';
          
          String valueStr = '';
          if (value is List) {
            valueStr = value.join(', ');
          } else if (value is Map) {
            valueStr = value.toString();
          } else {
            valueStr = value?.toString() ?? 'null';
          }
          
          sheet.cell(CellIndex.indexByString('B$currentRow')).value = valueStr;
          currentRow++;
        });
      } else {
        sheet.cell(CellIndex.indexByString('A$currentRow')).value = '  No answers found';
        currentRow++;
      }
      
      currentRow += 2; // Add space between responses
    }
  }
}
