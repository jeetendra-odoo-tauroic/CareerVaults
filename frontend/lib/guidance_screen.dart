import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'guidance_api.dart';

class CareerGuidanceScreen extends StatefulWidget {
  const CareerGuidanceScreen({super.key, required this.admin, GuidanceApi? api})
      : _api = api;

  final bool admin;
  final GuidanceApi? _api;

  @override
  State<CareerGuidanceScreen> createState() => _CareerGuidanceScreenState();
}

class _CareerGuidanceScreenState extends State<CareerGuidanceScreen> {
  late final GuidanceApi _api = widget._api ?? GuidanceApi();
  final _search = TextEditingController();
  List<GuidanceArticle> _articles = [];
  List<GuidanceCategory> _categories = [];
  bool _loading = true;
  String? _error;
  String _categoryFilter = '';
  GuidanceArticle? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    if (widget._api == null) _api.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Future.wait([
        _api.articles(
          admin: widget.admin,
          category: _categoryFilter,
          search: _search.text,
        ),
        _api.categories(),
      ]);
      if (mounted) {
        setState(() {
          _articles = data[0] as List<GuidanceArticle>;
          _categories = data[1] as List<GuidanceCategory>;
        });
      }
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

  Future<void> _edit([GuidanceArticle? article]) async {
    final saved = await showDialog<GuidanceArticle>(
      context: context,
      builder: (context) => GuidanceArticleForm(
        api: _api,
        categories: _categories,
        article: article,
      ),
    );
    if (saved != null) {
      await _load();
      if (mounted) {
        _notify(article == null ? 'Article created.' : 'Article updated.');
      }
    }
  }

  Future<void> _setStatus(GuidanceArticle article) async {
    try {
      await _api.setStatus(
        article.id,
        article.published ? 'UNPUBLISHED' : 'PUBLISHED',
      );
      await _load();
      if (mounted) {
        _notify(
            article.published ? 'Article unpublished.' : 'Article published.');
      }
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete(GuidanceArticle article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete article?'),
        content: Text('Delete "${article.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteArticle(article.id);
      await _load();
      if (mounted) _notify('Article deleted.');
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openArticle(GuidanceArticle article) async {
    try {
      final detail = await _api.article(article.id, admin: widget.admin);
      if (mounted) setState(() => _selected = detail);
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selected != null) return _detail(_selected!);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _errorPanel();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.admin
                          ? 'Manage Career Guidance'
                          : 'Career Guidance',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(widget.admin
                        ? 'Write, edit and publish career guidance articles.'
                        : 'Explore practical guidance for your career journey.'),
                  ],
                ),
              ),
              if (widget.admin)
                FilledButton.icon(
                  onPressed: () => _edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add article'),
                ),
            ],
          ),
          if (!widget.admin) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                labelText: 'Search article titles',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _search.clear();
                    _load();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoryFilter,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(
                    value: '', child: Text('All categories')),
                for (final category in _categories)
                  DropdownMenuItem(
                    value: category.code,
                    child: Text(category.label),
                  ),
              ],
              onChanged: (value) {
                setState(() => _categoryFilter = value ?? '');
                _load();
              },
            ),
          ],
          const SizedBox(height: 20),
          if (_articles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(36),
              child: Center(child: Text('No career guidance articles found.')),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1000
                    ? 3
                    : constraints.maxWidth >= 620
                        ? 2
                        : 1;
                final width =
                    (constraints.maxWidth - 16 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final article in _articles)
                      SizedBox(
                        width: width,
                        child: _ArticleCard(
                          article: article,
                          admin: widget.admin,
                          api: _api,
                          onOpen: () => _openArticle(article),
                          onEdit: () => _edit(article),
                          onStatus: () => _setStatus(article),
                          onDelete: () => _delete(article),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _detail(GuidanceArticle article) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _selected = null),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Career Guidance'),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ArticleImage(article: article, api: _api, height: 300),
                  const SizedBox(height: 16),
                  Chip(label: Text(article.categoryLabel)),
                  Text(article.title,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(article.shortDescription,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                      'Created ${_date(article.createdAt)} · Updated ${_date(article.updatedAt)}'),
                  const Divider(height: 32),
                  SelectableText(article.content ?? ''),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _errorPanel() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.article,
    required this.admin,
    required this.api,
    required this.onOpen,
    required this.onEdit,
    required this.onStatus,
    required this.onDelete,
  });

  final GuidanceArticle article;
  final bool admin;
  final GuidanceApi api;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ArticleImage(article: article, api: api, height: 180),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(article.categoryLabel)),
                      if (admin)
                        Chip(
                            label: Text(article.published
                                ? 'Published'
                                : 'Unpublished')),
                    ],
                  ),
                  Text(article.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(article.shortDescription,
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(
                      'Created ${_date(article.createdAt)} · Updated ${_date(article.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (admin)
                    Wrap(
                      spacing: 4,
                      children: [
                        TextButton(
                            onPressed: onOpen, child: const Text('View')),
                        TextButton(
                            onPressed: onEdit, child: const Text('Edit')),
                        TextButton(
                          onPressed: onStatus,
                          child:
                              Text(article.published ? 'Unpublish' : 'Publish'),
                        ),
                        TextButton(
                            onPressed: onDelete, child: const Text('Delete')),
                      ],
                    )
                  else
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Read More'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ArticleImage extends StatelessWidget {
  const _ArticleImage({
    required this.article,
    required this.api,
    required this.height,
  });

  final GuidanceArticle article;
  final GuidanceApi api;
  final double height;

  @override
  Widget build(BuildContext context) {
    final uri = article.imageUri(api.baseUrl);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: uri == null
          ? const ColoredBox(
              color: Color(0xfff1f3f8),
              child: Icon(Icons.lightbulb_outline, size: 48),
            )
          : Image.network(
              uri.toString(),
              headers: api.adminHeaders,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: Color(0xfff1f3f8),
                child: Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
    );
  }
}

class GuidanceArticleForm extends StatefulWidget {
  const GuidanceArticleForm({
    super.key,
    required this.api,
    required this.categories,
    this.article,
  });

  final GuidanceApi api;
  final List<GuidanceCategory> categories;
  final GuidanceArticle? article;

  @override
  State<GuidanceArticleForm> createState() => _GuidanceArticleFormState();
}

class _GuidanceArticleFormState extends State<GuidanceArticleForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.article?.title);
  late final _description =
      TextEditingController(text: widget.article?.shortDescription);
  late final _content = TextEditingController(text: widget.article?.content);
  late String _category = widget.article?.category ??
      (widget.categories.isEmpty ? '' : widget.categories.first.code);
  late String _status = widget.article?.status ?? 'UNPUBLISHED';
  PlatformFile? _image;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.isNotEmpty && mounted) {
      setState(() => _image = result.files.first);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      var article = await widget.api.saveArticle(
        {
          'title': _title.text.trim(),
          'category': _category,
          'shortDescription': _description.text.trim(),
          'content': _content.text.trim(),
          'status': _status,
        },
        id: widget.article?.id,
      );
      String? imageError;
      if (_image != null) {
        try {
          article = await widget.api.uploadImage(article.id, _image!);
        } catch (error) {
          imageError = error.toString().replaceFirst('Exception: ', '');
        }
      }
      if (mounted) {
        Navigator.pop(context, article);
        if (imageError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Article saved; image upload failed: $imageError')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.article == null
            ? 'Add career guidance article'
            : 'Edit article'),
        content: SizedBox(
          width: 560,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(_title, 'Article title'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: widget.categories
                        .map((item) => DropdownMenuItem(
                              value: item.code,
                              child: Text(item.label),
                            ))
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) =>
                            setState(() => _category = value ?? _category),
                  ),
                  const SizedBox(height: 12),
                  _field(_description, 'Short description', maxLines: 2),
                  const SizedBox(height: 12),
                  _field(_content, 'Full article content', maxLines: 10),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(
                          value: 'PUBLISHED', child: Text('Published')),
                      DropdownMenuItem(
                          value: 'UNPUBLISHED', child: Text('Unpublished')),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _status = value ?? _status),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(_image?.name ??
                          (widget.article?.imageUrl == null
                              ? 'Choose image (optional)'
                              : 'Replace image (optional)')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save article'),
          ),
        ],
      );

  Widget _field(TextEditingController controller, String label,
          {int maxLines = 1}) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required.' : null,
      );
}

String _date(String? value) {
  if (value == null || value.length < 10) return '—';
  return value.substring(0, 10);
}
