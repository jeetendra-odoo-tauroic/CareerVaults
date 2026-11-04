import 'package:flutter/material.dart';

import 'interview_api.dart';
import 'career_page_banner.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key, required this.admin, this.api});

  final bool admin;
  final InterviewApi? api;

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  late final _api = widget.api ?? InterviewApi();
  final _search = TextEditingController();
  List<InterviewCategory> _categories = [];
  List<InterviewTopic> _topics = [];
  String? _categorySlug;
  String? _experienceLevel;
  InterviewTopic? _selected;
  int _page = 0;
  int _totalPages = 0;
  int _totalTopics = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (page != null) _page = page;
    });
    try {
      final categories = await _api.categories(admin: widget.admin);
      final result = await _api.topics(
        admin: widget.admin,
        categorySlug: widget.admin ? null : _categorySlug,
        categoryId: widget.admin
            ? categories
                .where((category) => category.slug == _categorySlug)
                .firstOrNull
                ?.id
            : null,
        search: _search.text,
        experienceLevel: _experienceLevel,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _topics = result.topics;
        _page = result.page;
        _totalPages = result.totalPages;
        _totalTopics = result.totalElements;
        if (_categorySlug != null &&
            !categories.any((category) => category.slug == _categorySlug)) {
          _categorySlug = null;
        }
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_selected != null) return _detailPage(_selected!);
    final title = widget.admin
        ? 'Manage interview preparation'
        : 'Private IT Interview Preparation';
    final width = MediaQuery.sizeOf(context).width;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CareerPageBanner(
            title: title,
            subtitle: widget.admin
                ? 'Organise categories and editorial articles by experience level.'
                : 'Prepare for your next technical interview with curated topics organised by technology and experience level.',
            icon: Icons.record_voice_over_rounded,
          ),
          if (widget.admin) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _editCategory,
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: const Text('Add category'),
                ),
                OutlinedButton.icon(
                  onPressed: _categories.isEmpty ? null : _editTopic,
                  icon: const Icon(Icons.post_add),
                  label: const Text('Add topic / article'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _errorPanel()
          else ...[
            Text(
              widget.admin
                  ? 'Interview categories'
                  : 'Popular interview categories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_categories.isEmpty)
              const _InterviewMessage(
                icon: Icons.menu_book_outlined,
                message: 'No interview preparation categories are available.',
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final category in _categories)
                    SizedBox(
                      width: width < 600 ? width - 48 : 260,
                      child: _categoryCard(category),
                    ),
                ],
              ),
            if (widget.admin) ...[
              const SizedBox(height: 12),
              for (final category in _categories)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(category.name),
                  subtitle: Text(
                    '${category.published ? 'Published' : 'Unpublished'}${category.description == null ? '' : ' · ${category.description}'}',
                  ),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Edit category',
                        onPressed: () => _editCategory(category),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete category',
                        onPressed: () => _deleteCategory(category),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 24),
            Text(
              widget.admin ? 'Topics and articles' : 'Explore topics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final searchWidth = constraints.maxWidth > 680
                    ? constraints.maxWidth * 0.62
                    : constraints.maxWidth;
                final levelWidth =
                    constraints.maxWidth > 680 ? 260.0 : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: searchWidth,
                      child: TextField(
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _load(page: 0),
                        decoration: InputDecoration(
                          hintText: 'Search interview topics',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            tooltip: 'Search',
                            onPressed: () => _load(page: 0),
                            icon: const Icon(Icons.arrow_forward),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: levelWidth,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _experienceLevel,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Experience level',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All levels'),
                          ),
                          for (final level in interviewExperienceLevels)
                            DropdownMenuItem<String?>(
                              value: level,
                              child: Text(level),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() => _experienceLevel = value);
                          _load(page: 0);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All categories'),
                  selected: _categorySlug == null,
                  onSelected: (_) {
                    setState(() => _categorySlug = null);
                    _load(page: 0);
                  },
                ),
                for (final category in _categories)
                  ChoiceChip(
                    label: Text(category.name),
                    selected: _categorySlug == category.slug,
                    onSelected: (_) {
                      setState(() => _categorySlug = category.slug);
                      _load(page: 0);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_topics.isEmpty)
              _InterviewMessage(
                icon: Icons.search_off,
                message: _search.text.isEmpty &&
                        _experienceLevel == null &&
                        _categorySlug == null
                    ? 'No published interview articles are available yet.'
                    : 'No interview topics match these filters.',
              )
            else ...[
              Text(
                '$_totalTopics ${_totalTopics == 1 ? 'topic' : 'topics'}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              for (final topic in _topics) _topicCard(topic),
              if (_totalPages > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Previous page',
                      onPressed:
                          _page == 0 ? null : () => _load(page: _page - 1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('Page ${_page + 1} of $_totalPages'),
                    IconButton(
                      tooltip: 'Next page',
                      onPressed: _page + 1 >= _totalPages
                          ? null
                          : () => _load(page: _page + 1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _errorPanel() => _InterviewMessage(
        icon: Icons.cloud_off_outlined,
        message: 'Could not load interview preparation: $_error',
        action: TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );

  Widget _categoryCard(InterviewCategory category) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            setState(() => _categorySlug = category.slug);
            _load(page: 0);
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_categoryIcon(category.name),
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 10),
                Text(category.name,
                    style: Theme.of(context).textTheme.titleMedium),
                if (category.description != null) ...[
                  const SizedBox(height: 6),
                  Text(category.description!,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (widget.admin) ...[
                  const SizedBox(height: 6),
                  Text(category.published ? 'Published' : 'Unpublished'),
                ],
                if (!widget.admin) ...[
                  const SizedBox(height: 8),
                  const Text('Explore topics  →'),
                ],
              ],
            ),
          ),
        ),
      );

  IconData _categoryIcon(String name) {
    if (name.startsWith('Java')) return Icons.coffee_outlined;
    if (name.startsWith('Spring')) return Icons.spa_outlined;
    if (name.startsWith('Python')) return Icons.terminal_outlined;
    if (name.startsWith('Database')) return Icons.storage_outlined;
    if (name.startsWith('DevOps')) return Icons.cloud_outlined;
    if (name.startsWith('Frontend')) return Icons.web_outlined;
    return Icons.architecture_outlined;
  }

  Widget _topicCard(InterviewTopic topic) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          title: Text(topic.title),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              '${topic.category.name} · ${topic.introduction}'
              '${topic.experienceLevels.isEmpty ? '' : ' · ${topic.experienceLevels.join(', ')}'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: widget.admin
              ? Wrap(
                  children: [
                    IconButton(
                      tooltip: topic.published ? 'Unpublish' : 'Publish',
                      onPressed: () => _setPublished(topic),
                      icon: Icon(topic.published
                          ? Icons.visibility
                          : Icons.visibility_off_outlined),
                    ),
                    IconButton(
                      tooltip: 'Edit article',
                      onPressed: () => _editTopic(topic),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete topic',
                      onPressed: () => _deleteTopic(topic),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                )
              : const Icon(Icons.chevron_right),
          onTap: () => setState(() => _selected = topic),
        ),
      );

  Widget _detailPage(InterviewTopic topic) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _selected = null),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to interview topics'),
            ),
          ),
          Text(topic.category.name,
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(topic.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(topic.introduction,
              style: Theme.of(context).textTheme.titleMedium),
          if (topic.experienceLevels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final level in topic.experienceLevels)
                  Chip(label: Text(level)),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text('Interview preparation article',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SelectableText(topic.article, style: const TextStyle(height: 1.55)),
          if (widget.admin)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: OutlinedButton.icon(
                onPressed: () => _editTopic(topic),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit article'),
              ),
            ),
        ],
      );

  Future<void> _editCategory([InterviewCategory? category]) async {
    final name = TextEditingController(text: category?.name ?? '');
    final description =
        TextEditingController(text: category?.description ?? '');
    var published = category?.published ?? true;
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
              category == null ? 'Add interview category' : 'Edit category'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration:
                        const InputDecoration(labelText: 'Category name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: description,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Published'),
                    value: published,
                    onChanged: (value) =>
                        setDialogState(() => published = value ?? false),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      try {
        await _api.saveCategory(
          id: category?.id,
          name: name.text.trim(),
          description: description.text.trim(),
          published: published,
        );
        await _load();
        _notify('Interview category saved.');
      } catch (error) {
        _notify(error.toString().replaceFirst('Exception: ', ''));
      }
    }
    name.dispose();
    description.dispose();
  }

  Future<void> _editTopic([InterviewTopic? topic]) async {
    if (_categories.isEmpty) return;
    final title = TextEditingController(text: topic?.title ?? '');
    final introduction = TextEditingController(text: topic?.introduction ?? '');
    final article = TextEditingController(text: topic?.article ?? '');
    var categoryId = topic?.category.id ?? _categories.first.id;
    var published = topic?.published ?? false;
    var selectedLevels = List<String>.from(topic?.experienceLevels ?? []);
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
              topic == null ? 'Add interview topic / article' : 'Edit article'),
          content: SizedBox(
            width: 600,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final category in _categories)
                          DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => categoryId = value!),
                    ),
                    const SizedBox(height: 12),
                    _editorField(title, 'Topic title', required: true),
                    _editorField(introduction, 'Short introduction',
                        required: true, lines: 2),
                    _editorField(article, 'Preparation article',
                        required: true, lines: 6),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Experience levels'),
                      ),
                    ),
                    for (final level in interviewExperienceLevels)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(level),
                        value: selectedLevels.contains(level),
                        onChanged: (selected) {
                          setDialogState(() {
                            if (selected == true) {
                              selectedLevels.add(level);
                            } else {
                              selectedLevels.remove(level);
                            }
                          });
                        },
                      ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Published'),
                      value: published,
                      onChanged: (value) =>
                          setDialogState(() => published = value ?? false),
                    ),
                    const Text(
                      'This editor manages articles only; interview questions and answers are not included.',
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      try {
        final category =
            _categories.firstWhere((item) => item.id == categoryId);
        final input = InterviewTopic(
          id: topic?.id ?? 0,
          category: category,
          title: title.text.trim(),
          slug: topic?.slug ?? '',
          introduction: introduction.text.trim(),
          article: article.text.trim(),
          experienceLevels: selectedLevels,
          published: published,
        );
        final savedTopic = await _api.saveTopic(input, id: topic?.id);
        await _load();
        if (topic != null && _selected?.id == topic.id) {
          setState(() => _selected = savedTopic);
        }
        _notify('Interview article saved.');
      } catch (error) {
        _notify(error.toString().replaceFirst('Exception: ', ''));
      }
    }
    title.dispose();
    introduction.dispose();
    article.dispose();
  }

  Widget _editorField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int lines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          minLines: lines,
          maxLines: lines,
          decoration:
              InputDecoration(labelText: label, alignLabelWithHint: true),
          validator: required
              ? (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null
              : null,
        ),
      );

  Future<void> _setPublished(InterviewTopic topic) async {
    try {
      await _api.setPublished(topic.id, !topic.published);
      await _load();
      _notify(topic.published ? 'Article unpublished.' : 'Article published.');
    } catch (error) {
      _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteTopic(InterviewTopic topic) async {
    if (!await _confirm('Delete "${topic.title}"?')) return;
    try {
      await _api.deleteTopic(topic.id);
      await _load();
      _notify('Interview topic deleted.');
    } catch (error) {
      _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteCategory(InterviewCategory category) async {
    if (!await _confirm(
        'Delete "${category.name}"? It must not contain interview topics.')) {
      return;
    }
    try {
      await _api.deleteCategory(category.id);
      await _load();
      _notify('Interview category deleted.');
    } catch (error) {
      _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<bool> _confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;
}

class _InterviewMessage extends StatelessWidget {
  const _InterviewMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon,
                  size: 36, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              if (action != null) action!,
            ],
          ),
        ),
      );
}
