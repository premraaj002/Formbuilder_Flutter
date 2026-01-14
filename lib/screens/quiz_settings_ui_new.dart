// Updated Quiz Settings UI Implementation
// This file contains the refactored _showQuizSettings method
// To be integrated into quiz_builder_screen.dart

  void _showQuizSettings() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer<QuizSettingsNotifier>(
        builder: (context, settingsNotifier, child) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 20, offset: Offset(0,-4)),
            ],
          ),
          child: Column(
            children: [
              Container(margin: EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
              Container(
                padding: EdgeInsets.all(20),
                child: Row(children: [
                  Icon(Icons.settings_outlined, color: Color(0xFF34A853)),
                  SizedBox(width: 12),
                  Text('Quiz Settings', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  Spacer(),
                  if (_isPublished)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 16, color: Colors.orange[700]),
                          SizedBox(width: 4),
                          Text('Published', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close), style: IconButton.styleFrom(foregroundColor: colorScheme.onSurface.withOpacity(0.6))),
                ]),
              ),
              Expanded(
                child: ListView(padding: EdgeInsets.symmetric(horizontal: 20), children: [
                  // Display Settings Section
                  Text('Display Settings', style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  _buildSettingsItem(context, icon: Icons.emoji_events_outlined, title: 'Show score at end', subtitle: 'Display final score to students', value: settingsNotifier.settings.showScoreAtEnd, on Changed: _isPublished ? null : settingsNotifier.setShowScoreAtEnd),
                  _buildSettingsItem(context, icon: Icons.autorenew, title: 'Allow retake', subtitle: 'Students can retake the quiz', value: settingsNotifier.settings.allowRetake, onChanged: _isPublished ? null : settingsNotifier.setAllowRetake),
                  
                  // Quiz Behavior Section
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: colorScheme.outline.withOpacity(0.2)),
                  ),
                  Text('Quiz Behavior', style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  _buildSettingsItem(context, icon: Icons.shuffle, title: 'Shuffle questions', subtitle: 'Randomize question order for each student', value: settingsNotifier.settings.shuffleQuestions, onChanged: _isPublished ? null : settingsNotifier.setShuffleQuestions),
                  _buildSettingsItem(context, icon: Icons.shuffle_on_outlined, title: 'Shuffle options', subtitle: 'Randomize option order within questions', value: settingsNotifier.settings.shuffleOptions, onChanged: _isPublished ? null : settingsNotifier.setShuffleOptions),
                  _buildSettingsItem(context, icon: Icons.arrow_back, title: 'Allow back navigation', subtitle: 'Students can go back to previous questions', value: settingsNotifier.settings.allowBackNavigation, onChanged: _isPublished ? null : settingsNotifier.setAllowBackNavigation),
                  
                  // Timer Settings Section
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: colorScheme.outline.withOpacity(0.2)),
                  ),
                  Text('Timer Settings', style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  if (settingsNotifier.settings.timeLimitMinutes != null)
                    Container(
                      margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: TextField(
                        enabled: !_isPublished,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quiz Duration (minutes)',
                          hintText: 'e.g., 20',
                          helperText: 'Quiz will auto-submit when time expires',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.schedule, color: Color(0xFF34A853)),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear, size: 20),
                            onPressed: _isPublished ? null : () => settingsNotifier.setTimeLimitMinutes(null),
                          ),
                        ),
                        controller: TextEditingController(text: settingsNotifier.settings.timeLimitMinutes.toString())
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: settingsNotifier.settings.timeLimitMinutes.toString().length),
                          ),
                        onChanged: (value) {
                          final minutes = int.tryParse(value);
                          if (minutes != null && minutes > 0) {
                            settingsNotifier.setTimeLimitMinutes(minutes);
                          }
                        },
                      ),
                    )
                  else
                    Container(
                      margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: OutlinedButton.icon(
                        onPressed: _isPublished ? null : () => settingsNotifier.setTimeLimitMinutes(20),
                        icon: Icon(Icons.timer),
                        label: Text('Add Time Limit'),
                      ),
                    ),
                  
                  // Tab Switch Restriction Section
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: colorScheme.outline.withOpacity(0.2)),
                  ),
                  Text('Tab Switch Restriction (Web Only)', style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  _buildSettingsItem(
                    context, 
                    icon: Icons.tab_outlined, 
                    title: 'Enable Tab Switch Restriction', 
                    subtitle: 'Auto-submit if student switches tabs too many times', 
                    value: settingsNotifier.settings.enableTabRestriction, 
                    onChanged: _isPublished ? null : (v) {
                      settingsNotifier.setEnableTabRestriction(v);
                      if (v && settingsNotifier.settings.maxTabSwitchCount == null) {
                        settingsNotifier.setMaxTabSwitchCount(5);
                      }
                    }
                  ),
                  if (settingsNotifier.settings.enableTabRestriction && settingsNotifier.settings.maxTabSwitchCount != null)
                    Container(
                      margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: TextField(
                        enabled: !_isPublished,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Maximum Allowed Tab Switches',
                          hintText: 'e.g., 5',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.warning_amber_outlined, color: Colors.orange),
                        ),
                        controller: TextEditingController(text: settingsNotifier.settings.maxTabSwitchCount.toString())
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: settingsNotifier.settings.maxTabSwitchCount.toString().length),
                          ),
                        onChanged: (value) {
                          final count = int.tryParse(value);
                          if (count != null && count > 0) {
                            settingsNotifier.setMaxTabSwitchCount(count);
                          }
                        },
                      ),
                    ),
                  
                  // Scoring Settings Section
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: colorScheme.outline.withOpacity(0.2)),
                  ),
                  Text('Scoring Settings', style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  _buildSettingsItem(
                    context, 
                    icon: Icons.remove_circle_outline, 
                    title: 'Negative marking', 
                    subtitle: 'Deduct points for wrong answers', 
                    value: settingsNotifier.settings.negativeMarking, 
                    onChanged: _isPublished ? null : settingsNotifier.setNegativeMarking
                  ),
                  if (settingsNotifier.settings.negativeMarking)
                    Container(
                      margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: TextField(
                        enabled: !_isPublished,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Points to deduct for wrong answer',
                          hintText: 'e.g., 1',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.exposure_neg_1, color: Colors.red),
                        ),
                        controller: TextEditingController(text: settingsNotifier.settings.negativeMarkingPoints.toString())
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: settingsNotifier.settings.negativeMarkingPoints.toString().length),
                          ),
                        onChanged: (value) {
                          final points = int.tryParse(value);
                          if (points != null && points >= 0) {
                            settingsNotifier.setNegativeMarkingPoints(points);
                          }
                        },
                      ),
                    ),
                  
                  SizedBox(height: 20),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
