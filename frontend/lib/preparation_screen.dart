import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';

class PreparationScreen extends StatefulWidget {
  const PreparationScreen({super.key, required this.admin, this.api});

  final bool admin;
  final PreparationApi? api;

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> {
  late final _api = widget.api ?? PreparationApi();
  final _search = TextEditingController();
  List<PreparationCategory> _categories = [];
  List<PreparationTopic> _topics = [];
  String? _categorySlug;
  PreparationTopic? _selected;
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
        search: _search.text,
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
            () => _error = error.toString().replaceFirst('Exception: ', ''));
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
    final title = widget.admin ? 'Manage learning content' : 'IT Preparation';
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(widget.admin
              ? 'Create Java and Python learning material, review drafts, and manage published content.'
              : 'Explore structured learning notes for Java, Python and their ecosystems.'),
          if (widget.admin) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 8,
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
          const SizedBox(height: 22),
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
            if (_categories.isEmpty)
              const _InfoPanel(
                text: 'No learning categories are available yet.',
                icon: Icons.menu_book_outlined,
              )
            else ...[
              Text('Categories', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!widget.admin)
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _categorySlug == null,
                      onSelected: (_) {
                        setState(() {
                          _categorySlug = null;
                          _page = 0;
                        });
                        _load(page: 0);
                      },
                    ),
                  for (final category in _categories)
                    if (widget.admin)
                      Chip(label: Text(category.name))
                    else
                      ChoiceChip(
                        label: Text(category.name),
                        selected: _categorySlug == category.slug,
                        onSelected: (_) {
                          setState(() {
                            _categorySlug = category.slug;
                            _page = 0;
                          });
                          _load(page: 0);
                        },
                      ),
                ],
              ),
              if (widget.admin) ...[
                const SizedBox(height: 10),
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
            ],
            const SizedBox(height: 22),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(page: 0),
              decoration: InputDecoration(
                hintText: 'Search topic titles and introductions',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  onPressed: () => _load(page: 0),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_topics.isEmpty)
              _InfoPanel(
                icon: Icons.search_off,
                text: _search.text.isEmpty
                    ? 'No topics are available in this category yet.'
                    : 'No learning topics match your search.',
              )
            else ...[
              Text(
                widget.admin
                    ? 'Topics and articles ($_totalTopics)'
                    : 'Learning topics ($_totalTopics)',
                style: Theme.of(context).textTheme.titleLarge,
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

  Widget _errorPanel() => _InfoPanel(
        icon: Icons.cloud_off_outlined,
        text: 'Could not load learning content: $_error',
        action: TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );

  Widget _topicCard(PreparationTopic topic) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          title: Text(topic.title),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              '${topic.category.name} · ${topic.introduction}',
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
                      tooltip: 'Edit topic',
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

  Widget _detailPage(PreparationTopic topic) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _selected = null),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to topics'),
            ),
          ),
          Text(topic.category.name,
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(topic.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(topic.introduction,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          _contentSection(context, 'Detailed explanation', topic.explanation),
          if (topic.subtopics.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Subtopics', style: Theme.of(context).textTheme.titleLarge),
            for (final subtopic in topic.subtopics)
              ExpansionTile(
                title: Text(subtopic.title),
                children: [
                  if ((subtopic.content ?? '').isNotEmpty)
                    _formattedText(subtopic.content!),
                ],
              ),
          ],
          if (topic.codeExamples?.isNotEmpty == true) ...[
            const SizedBox(height: 18),
            _contentSection(context, 'Code examples', topic.codeExamples!),
          ],
          if (topic.practicalExamples?.isNotEmpty == true) ...[
            const SizedBox(height: 18),
            _contentSection(
                context, 'Practical examples', topic.practicalExamples!),
          ],
          if (topic.resources.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Learning resources',
                style: Theme.of(context).textTheme.titleLarge),
            for (final resource in topic.resources) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(resource.kind == 'IMAGE'
                    ? Icons.image_outlined
                    : Icons.attach_file),
                title: Text(resource.originalName),
                trailing: widget.admin
                    ? IconButton(
                        tooltip: 'Delete resource',
                        onPressed: () => _deleteResource(topic, resource),
                        icon: const Icon(Icons.delete_outline),
                      )
                    : null,
                onTap: widget.admin
                    ? null
                    : () => launchUrl(
                          resource.uri,
                          mode: LaunchMode.externalApplication,
                        ),
              ),
              if (resource.kind == 'IMAGE')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Image.network(
                    resource.uri.toString(),
                    headers: {
                      if (AuthSession.authorizationHeader != null)
                        'Authorization': AuthSession.authorizationHeader!,
                    },
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      'Could not load this image resource.',
                    ),
                  ),
                ),
            ],
          ],
          if (topic.referenceLinks.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('References', style: Theme.of(context).textTheme.titleLarge),
            for (final link in topic.referenceLinks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.open_in_new),
                title: Text(link),
                onTap: () => launchUrl(Uri.parse(link),
                    mode: LaunchMode.externalApplication),
              ),
          ],
          if (widget.admin)
            Wrap(
              spacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editTopic(topic),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit article'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _uploadResource(topic, 'RESOURCE'),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload resource'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _uploadResource(topic, 'IMAGE'),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Upload image'),
                ),
              ],
            ),
        ],
      );

  Widget _contentSection(BuildContext context, String title, String value) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _formattedText(value),
        ],
      );

  Widget _formattedText(String value) => SelectableText(
        value,
        style: const TextStyle(height: 1.55),
      );

  Future<void> _editCategory([PreparationCategory? category]) async {
    final name = TextEditingController(text: category?.name ?? '');
    final description =
        TextEditingController(text: category?.description ?? '');
    var published = category?.published ?? true;
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Add category' : 'Edit category'),
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
        _notify('Category saved.');
      } catch (error) {
        _notify(error.toString().replaceFirst('Exception: ', ''));
      }
    }
    name.dispose();
    description.dispose();
  }

  Future<void> _editTopic([PreparationTopic? topic]) async {
    if (_categories.isEmpty) return;
    final title = TextEditingController(text: topic?.title ?? '');
    final introduction = TextEditingController(text: topic?.introduction ?? '');
    final explanation = TextEditingController(text: topic?.explanation ?? '');
    final code = TextEditingController(text: topic?.codeExamples ?? '');
    final practical =
        TextEditingController(text: topic?.practicalExamples ?? '');
    final references =
        TextEditingController(text: topic?.referenceLinks.join('\n') ?? '');
    final subtopics = List<PreparationSubtopic>.from(topic?.subtopics ?? []);
    var categoryId = topic?.category.id ?? _categories.first.id;
    var published = topic?.published ?? false;
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
              topic == null ? 'Add topic / article' : 'Edit topic / article'),
          content: SizedBox(
            width: 620,
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
                    _editorField(title, 'Topic / article title',
                        required: true),
                    _editorField(introduction, 'Short introduction',
                        required: true, lines: 2),
                    _editorField(explanation, 'Detailed explanation',
                        required: true, lines: 5),
                    _editorField(code, 'Code examples', lines: 4),
                    _editorField(practical, 'Practical examples', lines: 4),
                    _editorField(references, 'Reference URLs (one per line)',
                        lines: 3),
                    const Divider(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Subtopics',
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final value = await _editSubtopic();
                            if (value != null) {
                              setDialogState(() => subtopics.add(value));
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add subtopic'),
                        ),
                      ],
                    ),
                    for (var index = 0; index < subtopics.length; index++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(subtopics[index].title),
                        subtitle: Text(subtopics[index].content ?? '',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () async {
                          final updated = await _editSubtopic(subtopics[index]);
                          if (updated != null) {
                            setDialogState(() => subtopics[index] = updated);
                          }
                        },
                        trailing: IconButton(
                          tooltip: 'Remove subtopic',
                          onPressed: () =>
                              setDialogState(() => subtopics.removeAt(index)),
                          icon: const Icon(Icons.close),
                        ),
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
        final updated = PreparationTopic(
          id: topic?.id ?? 0,
          category: category,
          title: title.text.trim(),
          slug: topic?.slug ?? '',
          introduction: introduction.text.trim(),
          explanation: explanation.text.trim(),
          codeExamples: code.text.trim(),
          practicalExamples: practical.text.trim(),
          referenceLinks: references.text
              .split('\n')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(),
          published: published,
          subtopics: subtopics,
          resources: topic?.resources ?? const [],
        );
        await _api.saveTopic(updated, id: topic?.id);
        await _load();
        if (topic != null && _selected?.id == topic.id) {
          setState(() {
            _selected =
                _topics.where((item) => item.id == topic.id).firstOrNull;
          });
        }
        _notify('Learning topic saved.');
      } catch (error) {
        _notify(error.toString().replaceFirst('Exception: ', ''));
      }
    }
    for (final controller in [
      title,
      introduction,
      explanation,
      code,
      practical,
      references,
    ]) {
      controller.dispose();
    }
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

  Future<PreparationSubtopic?> _editSubtopic(
      [PreparationSubtopic? existing]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final content = TextEditingController(text: existing?.content ?? '');
    final result = await showDialog<PreparationSubtopic>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add subtopic' : 'Edit subtopic'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _editorField(title, 'Subtopic title', required: true),
              _editorField(content, 'Content', lines: 4),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isNotEmpty) {
                Navigator.pop(
                  context,
                  PreparationSubtopic(
                    id: existing?.id,
                    title: title.text.trim(),
                    content: content.text.trim(),
                    sortOrder: existing?.sortOrder ?? 0,
                  ),
                );
              }
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
    title.dispose();
    content.dispose();
    return result;
  }

  Future<void> _setPublished(PreparationTopic topic) async {
    try {
      await _api.setPublished(topic.id, !topic.published);
      await _load();
      _notify(topic.published ? 'Topic unpublished.' : 'Topic published.');
    } catch (error) {
      _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteTopic(PreparationTopic topic) async {
    final confirmed =
        await _confirm('Delete "${topic.title}" and its resources?');
    if (!confirmed) return;
    try {
      await _api.deleteTopic(topic.id);
      await _load();
      _notify('Topic deleted.');
    } catch (error) {
      _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteCategory(PreparationCategory category) async {
    final confirmed = await _confirm(
        'Delete "${category.name}"? It must not contain topics.');
    if (!confirmed) return;
    try {
      await _api.deleteCategory(category.id);
      await _load();
      _notify('Category deleted.');
    } catch (error) {
      _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteResource(
    PreparationTopic topic,
    PreparationResource resource,
  ) async {
    final confirmed = await _confirm('Delete "${resource.originalName}"?');
    if (!confirmed) return;
    try {
      await _api.deleteResource(topic.id, resource.id);
      await _load();
      if (mounted) {
        setState(() {
          _selected = _topics.where((item) => item.id == topic.id).firstOrNull;
        });
      }
      _notify('Learning resource deleted.');
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

  Future<void> _uploadResource(PreparationTopic topic, String kind) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    try {
      await _api.uploadResource(topic.id, result.files.first, kind: kind);
      await _load();
      final refreshed =
          _topics.where((item) => item.id == topic.id).firstOrNull;
      if (mounted) setState(() => _selected = refreshed ?? topic);
      _notify('Learning resource uploaded.');
    } catch (error) {
      _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.text, required this.icon, this.action});

  final String text;
  final IconData icon;
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
              Text(text, textAlign: TextAlign.center),
              if (action != null) action!,
            ],
          ),
        ),
      );
}
