import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart' show AuthSession;
import 'course_api.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key, required this.admin, CourseApi? api})
      : _api = api;

  final bool admin;
  final CourseApi? _api;

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  late final CourseApi _api = widget._api ?? CourseApi();
  bool _loading = true;
  String? _error;
  List<Course> _courses = [];
  Course? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    if (widget._api == null) _api.close();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final courses = await _api.courses(admin: widget.admin);
      if (mounted) setState(() => _courses = courses);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
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

  Future<void> _editCourse([Course? course]) async {
    final result = await showDialog<Course>(
      context: context,
      builder: (context) => CourseFormDialog(api: _api, course: course),
    );
    if (result != null) {
      await _loadCourses();
      if (mounted) _notify(course == null ? 'Course added.' : 'Course updated.');
    }
  }

  Future<void> _changeStatus(Course course) async {
    try {
      await _api.setStatus(
        course.id,
        course.published ? 'UNPUBLISHED' : 'PUBLISHED',
      );
      await _loadCourses();
      if (mounted) _notify(course.published ? 'Course unpublished.' : 'Course published.');
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text('Delete "${course.name}"? This cannot be undone.'),
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
      await _api.deleteCourse(course.id);
      await _loadCourses();
      if (mounted) _notify('Course deleted.');
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openCourse(Course course) async {
    try {
      final detail = await _api.course(course.id);
      if (mounted) setState(() => _selectedCourse = detail);
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _contact(Course course) async {
    final uri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': 'Course enquiry: ${course.name}',
        'body': 'Hello, I would like to know more about ${course.name}.',
      },
    );
    if (!await launchUrl(uri) && mounted) {
      _notify('No email app is available on this device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedCourse;
    if (selected != null) return _detailPage(selected);
    return RefreshIndicator(
      onRefresh: _loadCourses,
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
                      widget.admin ? 'Manage courses' : 'Online Classes',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(widget.admin
                        ? 'Add and manage courses on CareerVault.'
                        : 'Explore online courses from CareerVault.'),
                  ],
                ),
              ),
              if (widget.admin)
                FilledButton.icon(
                  onPressed: () => _editCourse(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add course'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _ErrorMessage(message: _error!, onRetry: _loadCourses)
          else if (_courses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('No courses are available yet.')),
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
                    for (final course in _courses)
                      SizedBox(
                        width: width,
                        child: _CourseCard(
                          course: course,
                          admin: widget.admin,
                          onDetails: () => _openCourse(course),
                          onEdit: () => _editCourse(course),
                          onStatus: () => _changeStatus(course),
                          onDelete: () => _delete(course),
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

  Widget _detailPage(Course course) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _selectedCourse = null),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to courses'),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CourseImage(course: course, height: 300),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Chip(label: Text(course.category)),
                          const SizedBox(height: 8),
                          Text(course.name,
                              style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 12),
                          Text(course.description),
                          const SizedBox(height: 20),
                          Text(
                            _price(course.price),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _contact(course),
                            icon: const Icon(Icons.mail_outline),
                            label: const Text('Contact'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.admin,
    required this.onDetails,
    required this.onEdit,
    required this.onStatus,
    required this.onDelete,
  });

  final Course course;
  final bool admin;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CourseImage(course: course, height: 180),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(label: Text(course.category)),
                  Text(course.name,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    course.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(_price(course.price),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (admin)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        TextButton(
                          onPressed: onDetails,
                          child: const Text('View'),
                        ),
                        TextButton(
                          onPressed: onEdit,
                          child: const Text('Edit'),
                        ),
                        TextButton(
                          onPressed: onStatus,
                          child: Text(course.published ? 'Unpublish' : 'Publish'),
                        ),
                        TextButton(
                          onPressed: onDelete,
                          child: const Text('Delete'),
                        ),
                      ],
                    )
                  else
                    FilledButton.tonal(
                      onPressed: onDetails,
                      child: const Text('View Details'),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _CourseImage extends StatelessWidget {
  const _CourseImage({required this.course, required this.height});

  final Course course;
  final double height;

  @override
  Widget build(BuildContext context) {
    final uri = course.imageUri;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: uri == null
          ? const ColoredBox(
              color: Color(0xfff1f3f8),
              child: Icon(Icons.menu_book_outlined, size: 48),
            )
          : Image.network(
              uri.toString(),
              headers: {
                if (AuthSession.authorizationHeader != null)
                  'Authorization': AuthSession.authorizationHeader!,
              },
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: Color(0xfff1f3f8),
                child: Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
    );
  }
}

class CourseFormDialog extends StatefulWidget {
  const CourseFormDialog({super.key, required this.api, this.course});

  final CourseApi api;
  final Course? course;

  @override
  State<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.course?.name);
  late final _category = TextEditingController(text: widget.course?.category);
  late final _description =
      TextEditingController(text: widget.course?.description);
  late final _price =
      TextEditingController(text: widget.course?.price.toStringAsFixed(2));
  late String _status = widget.course?.status ?? 'UNPUBLISHED';
  PlatformFile? _image;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty && mounted) {
      setState(() => _image = result.files.first);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final course = await widget.api.saveCourse(
        {
          'name': _name.text.trim(),
          'category': _category.text.trim(),
          'description': _description.text.trim(),
          'price': double.parse(_price.text.trim()),
          'status': _status,
        },
        id: widget.course?.id,
      );
      final result =
          _image == null ? course : await widget.api.uploadImage(course.id, _image!);
      if (mounted) Navigator.pop(context, result);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.course == null ? 'Add course' : 'Edit course'),
        content: SizedBox(
          width: 460,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(_name, 'Course name'),
                  const SizedBox(height: 12),
                  _field(_category, 'Course category'),
                  const SizedBox(height: 12),
                  _field(_description, 'Course description', maxLines: 5),
                  const SizedBox(height: 12),
                  _field(_price, 'Course price', decimal: true),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Course status'),
                    items: const [
                      DropdownMenuItem(
                          value: 'PUBLISHED', child: Text('Published')),
                      DropdownMenuItem(
                          value: 'UNPUBLISHED', child: Text('Unpublished')),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(
                            () => _status = value ?? 'UNPUBLISHED'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(_image?.name ??
                          (widget.course?.imageUrl == null
                              ? 'Choose course image (optional)'
                              : 'Replace course image (optional)')),
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
                : const Text('Save course'),
          ),
        ],
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool decimal = false,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Required.';
          if (decimal) {
            final price = double.tryParse(value.trim());
            if (price == null || !price.isFinite || price < 0) {
              return 'Enter a valid non-negative price.';
            }
            final fraction = value.trim().split('.');
            if (fraction.length > 1 && fraction.last.length > 2) {
              return 'Use no more than two decimal places.';
            }
          }
          return null;
        },
      );
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
}

String _price(double price) =>
    price == 0 ? 'Free' : price.toStringAsFixed(2);
