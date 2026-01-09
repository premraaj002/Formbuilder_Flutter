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
  State<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen>
    with TickerProviderStateMixin {
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

    if (_searchQuery.isNotEmpty) {
      templates = TemplateService.searchTemplates(_searchQuery);
    }

    if (_selectedCategory != 'all') {
      templates =
          templates.where((t) => t.category == _selectedCategory).toList();
    }

    return templates;
  }

  void _selectTemplate(FormTemplate template) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => widget.isQuiz
            ? QuizBuilderScreen(template: template)
            : FormBuilderScreen(template: template),
      ),
    );
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
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () =>
                _selectTemplate(TemplateService.getTemplateById('blank')!),
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                onTap: (index) {
                  setState(() {
                    _selectedCategory =
                        index == 0 ? 'all' : templateCategories[index - 1].id;
                  });
                },
                tabs: [
                  Tab(text: 'All'),
                ]..addAll(
                    templateCategories.map((c) => Tab(text: c.name)),
                  ),
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

    if (templates.isEmpty) return _buildEmptyState();

    return GridView.builder(
      itemCount: templates.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: isDesktop ? 280 : 240, // 🔥 FIXED
      ),
      itemBuilder: (context, index) {
        return _buildTemplateCard(templates[index], isDesktop);
      },
    );
  }

  Widget _buildTemplateCard(FormTemplate template, bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBlank = template.id == 'blank';

    return _HoverTemplateCard(
      onTap: () => _selectTemplate(template),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 16 : 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isBlank
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.2),
            width: isBlank ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: template.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(template.icon, color: template.color),
                ),
                const Spacer(),
                if (template.isPremium)
                  _buildProBadge(),
              ],
            ),
            const SizedBox(height: 12),

            // Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    template.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Row(
              children: [
                Icon(Icons.quiz_outlined,
                    size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${template.questions.length} questions',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 6),
                _buildCategoryChip(template),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(FormTemplate template) {
    final category = templateCategories.firstWhere(
      (c) => c.id == template.category,
      orElse: () => templateCategories.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: template.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category.name,
        style: TextStyle(
          fontSize: 10,
          color: template.color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildProBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No templates found'));
  }
}

class _HoverTemplateCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverTemplateCard({required this.child, required this.onTap});

  @override
  State<_HoverTemplateCard> createState() => _HoverTemplateCardState();
}

class _HoverTemplateCardState extends State<_HoverTemplateCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return MouseRegion(
      cursor: isDesktop ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: isDesktop ? (_) => setState(() => _hover = true) : null,
      onExit: isDesktop ? (_) => setState(() => _hover = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..translate(0.0, _hover ? -6.0 : 0.0)
            ..scale(_hover ? 1.02 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color:
                          Theme.of(context).primaryColor.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
