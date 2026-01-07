import 'package:flutter/material.dart';
import '../models/template_models.dart';
import '../services/template_service.dart';
import 'form_builder_screen.dart';
import 'quiz_builder_screen.dart';

class TemplateSelectionScreen extends StatefulWidget {
  final bool isQuiz;

  const TemplateSelectionScreen({
    super.key,
    this.isQuiz = false,
  });

  @override
  State<TemplateSelectionScreen> createState() => _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final categories = ['all', ...templateCategories.map((c) => c.id)];
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<FormTemplate> _getFilteredTemplates() {
    List<FormTemplate> templates = TemplateService.getAllTemplates();
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      templates = TemplateService.searchTemplates(_searchQuery);
    }
    
    // Filter by category
    if (_selectedCategory != 'all') {
      templates = templates.where((t) => t.category == _selectedCategory).toList();
    }
    
    return templates;
  }

  void _selectTemplate(FormTemplate template) {
    if (widget.isQuiz) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizBuilderScreen(template: template),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FormBuilderScreen(template: template),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isQuiz ? 'Choose Quiz Template' : 'Choose Form Template',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () => _selectTemplate(TemplateService.getTemplateById('blank')!),
            child: Text(
              widget.isQuiz ? 'Start Blank Quiz' : 'Start Blank Form',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search templates...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              // Category Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorColor: colorScheme.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                onTap: (index) {
                  setState(() {
                    if (index == 0) {
                      _selectedCategory = 'all';
                    } else {
                      _selectedCategory = templateCategories[index - 1].id;
                    }
                  });
                },
                tabs: [
                  const Tab(text: 'All'),
                  ...templateCategories.map((category) => Tab(text: category.name)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: _buildTemplateGrid(isDesktop),
      ),
    );
  }

  Widget _buildTemplateGrid(bool isDesktop) {
    final templates = _getFilteredTemplates();
    
    if (templates.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isDesktop ? 0.75 : 0.85, // Increased aspect ratio for mobile
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template, isDesktop);
      },
    );
  }

  Widget _buildTemplateCard(FormTemplate template, bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBlank = template.id == 'blank';
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isBlank 
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => _selectTemplate(template),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 16 : 12), // Reduced padding on mobile
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Prevent overflow
            children: [
              // Icon and Premium Badge
              Row(
                children: [
                  Container(
                    width: isDesktop ? 48 : 40, // Smaller icon on mobile
                    height: isDesktop ? 48 : 40,
                    decoration: BoxDecoration(
                      color: isBlank 
                          ? colorScheme.primary.withOpacity(0.1)
                          : template.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      template.icon,
                      color: isBlank ? colorScheme.primary : template.color,
                      size: isDesktop ? 24 : 20, // Smaller icon on mobile
                    ),
                  ),
                  const Spacer(),
                  if (template.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: isDesktop ? 12 : 8), // Reduced spacing on mobile
              
              // Template Name
              Text(
                template.name,
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 13, // Slightly smaller on mobile
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: isDesktop ? 2 : 1, // Single line on mobile to save space
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isDesktop ? 6 : 4), // Reduced spacing on mobile
              
              // Template Description
              Flexible(
                child: Text(
                  template.description,
                  style: TextStyle(
                    fontSize: isDesktop ? 13 : 11, // Smaller text on mobile
                    color: colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                  maxLines: isDesktop ? 3 : 2, // Fewer lines on mobile
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(height: isDesktop ? 8 : 6), // Fixed spacing instead of Spacer
              
              // Questions count and category
              Row(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: isDesktop ? 16 : 14, // Smaller icon on mobile
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: isDesktop ? 4 : 3),
                  Flexible(
                    child: Text(
                      '${template.questions.length} questions',
                      style: TextStyle(
                        fontSize: isDesktop ? 12 : 10, // Smaller text on mobile
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 8 : 6, 
                        vertical: isDesktop ? 4 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: template.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        templateCategories
                            .firstWhere((c) => c.id == template.category, 
                                orElse: () => templateCategories.first)
                            .name,
                        style: TextStyle(
                          fontSize: isDesktop ? 10 : 9, // Smaller text on mobile
                          fontWeight: FontWeight.w500,
                          color: template.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No templates found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Try adjusting your search or browse different categories'
                : 'No templates available in this category',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_searchQuery.isNotEmpty) {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              } else {
                _selectTemplate(TemplateService.getTemplateById('blank')!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              _searchQuery.isNotEmpty 
                  ? 'Clear Search' 
                  : (widget.isQuiz ? 'Create Blank Quiz' : 'Create Blank Form'),
            ),
          ),
        ],
      ),
    );
  }
}
