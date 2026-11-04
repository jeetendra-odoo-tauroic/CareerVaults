import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart' show AuthSession;
import 'mock_tests_api.dart';

class MockTestsScreen extends StatefulWidget {
  const MockTestsScreen({
    super.key,
    required this.admin,
    MockTestsApi? api,
    DateTime Function()? clock,
    this.onLogin,
    this.onRegister,
  })  : _api = api,
        _clock = clock;

  final bool admin;
  final MockTestsApi? _api;
  final DateTime Function()? _clock;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;

  @override
  State<MockTestsScreen> createState() => _MockTestsScreenState();
}

class _MockTestsScreenState extends State<MockTestsScreen> {
  late final MockTestsApi _api = widget._api ?? MockTestsApi();
  bool _loading = true;
  String? _error;
  List<MockTestSummary> _tests = [];
  List<TestCategory> _categories = [];
  List<TestResult> _history = [];
  MockTestSummary? _dailyQuiz;
  String _categoryFilter = 'All';
  bool _showHistory = false;
  TestAttempt? _attempt;
  TestResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (widget._api == null) _api.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        _api.tests(admin: widget.admin),
        _api.categories(),
        if (!widget.admin) _api.latestDailyQuiz(),
        if (!widget.admin && AuthSession.signedIn) _api.history(),
      ]);
      if (!mounted) return;
      setState(() {
        _tests = values[0] as List<MockTestSummary>;
        _categories = values[1] as List<TestCategory>;
        if (!widget.admin) {
          _dailyQuiz = values[2] as MockTestSummary?;
          _history = AuthSession.signedIn
              ? values[3] as List<TestResult>
              : [];
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

  Future<void> _editTest([MockTestSummary? existing]) async {
    final saved = await showDialog<AdminTest>(
      context: context,
      builder: (context) => TestFormDialog(
        api: _api,
        categories: _categories,
        existing: existing,
      ),
    );
    if (saved != null) {
      await _load();
      if (mounted) _manageQuestions(saved.test.id);
    }
  }

  Future<void> _manageQuestions(int id) async {
    try {
      final test = await _api.adminTest(id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => QuestionManagerDialog(api: _api, test: test),
      );
      await _load();
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _setStatus(MockTestSummary test) async {
    try {
      await _api.setStatus(test.id, test.published ? 'DRAFT' : 'PUBLISHED');
      await _load();
      if (mounted) {
        _notify(test.published ? 'Test unpublished.' : 'Test published.');
      }
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteTest(MockTestSummary test) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete test?'),
        content: Text(
            'Delete "${test.title}" and its questions? Past results are kept.'),
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
      await _api.deleteTest(test.id);
      await _load();
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _start(MockTestSummary test) async {
    if (!AuthSession.signedIn) {
      _notify('Please log in to access this feature.');
      return;
    }
    try {
      final attempt = await _api.start(test.id);
      if (mounted) setState(() => _attempt = attempt);
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openResult(String attemptId) async {
    try {
      final result = await _api.result(attemptId);
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_attempt != null) {
      return ActiveTestView(
        key: ValueKey(_attempt!.id),
        api: _api,
        attempt: _attempt!,
        clock: widget._clock,
        onSubmitted: (result) => setState(() {
          _attempt = null;
          _result = result;
        }),
        onError: _notify,
      );
    }
    if (_result != null) {
      return TestResultView(
        result: _result!,
        onBack: () async {
          setState(() => _result = null);
          await _load();
        },
      );
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorPanel(message: _error!, onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
          vertical: 24,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.admin
                          ? 'Manage mock tests & quizzes'
                          : 'Mock Tests & Daily Quizzes',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(widget.admin
                        ? 'Create tests, add questions and manage publication.'
                        : 'Practice by topic and review your previous attempts.'),
                  ],
                ),
              ),
              if (widget.admin)
                FilledButton.icon(
                  onPressed: () => _editTest(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create test'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (!widget.admin) ...[
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Available tests')),
                ButtonSegment(value: true, label: Text('Result history')),
              ],
              selected: {_showHistory},
              onSelectionChanged: (value) =>
                  setState(() => _showHistory = value.first),
            ),
            const SizedBox(height: 20),
            if (_showHistory) _historyList() else _publicList(),
          ] else
            _adminList(),
        ],
      ),
    );
  }

  Widget _publicList() {
    final visible = _tests.where((test) =>
        test.published &&
        (_categoryFilter == 'All' || test.category == _categoryFilter));
    final quizzes = visible.where((test) => test.dailyQuiz).toList();
    final mockTests = visible.where((test) => !test.dailyQuiz).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_dailyQuiz != null &&
            (_categoryFilter == 'All' ||
                _dailyQuiz!.category == _categoryFilter)) ...[
          Text('Latest Daily Quiz',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _TestCard(test: _dailyQuiz!, onStart: () => _start(_dailyQuiz!)),
          const SizedBox(height: 20),
        ],
        Text('Filter by category',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _categoryFilter == 'All',
              onSelected: (_) => setState(() => _categoryFilter = 'All'),
            ),
            for (final category in _categories)
              ChoiceChip(
                label: Text(category.label),
                selected: _categoryFilter == category.code,
                onSelected: (_) =>
                    setState(() => _categoryFilter = category.code),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Mock Tests', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (mockTests.isEmpty)
          const Text('No published mock tests in this category yet.')
        else
          for (final test in mockTests)
            _TestCard(test: test, onStart: () => _start(test)),
        if (quizzes.where((test) => test.id != _dailyQuiz?.id).isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Daily Quizzes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final test in quizzes.where((test) => test.id != _dailyQuiz?.id))
            _TestCard(test: test, onStart: () => _start(test)),
        ],
      ],
    );
  }

  Widget _historyList() {
    if (!AuthSession.signedIn) return _loginRequiredPanel();
    if (_history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No completed attempts yet.')),
      );
    }

    return Column(
      children: [
        for (final result in _history)
          Card(
            child: ListTile(
              title: Text(result.testTitle),
              subtitle: Text(
                '${result.percentage.toStringAsFixed(1)}% · '
                '${result.correctAnswers} correct · ${_formatDuration(result.timeTakenSeconds)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openResult(result.attemptId),
            ),
          ),
      ],
    );
  }

  Widget _loginRequiredPanel() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Please log in to access this feature.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (widget.onLogin != null)
                  OutlinedButton(
                    onPressed: widget.onLogin,
                    child: const Text('Log in'),
                  ),
                if (widget.onRegister != null)
                  FilledButton(
                    onPressed: widget.onRegister,
                    child: const Text('Register'),
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _adminList() {
    if (_tests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No tests created. Add your first test.')),
      );
    }
    return Column(
      children: [
        for (final test in _tests)
          _TestCard(
            test: test,
            admin: true,
            onEdit: () => _editTest(test),
            onQuestions: () => _manageQuestions(test.id),
            onStatus: () => _setStatus(test),
            onDelete: () => _deleteTest(test),
          ),
      ],
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.test,
    this.admin = false,
    this.onStart,
    this.onEdit,
    this.onQuestions,
    this.onStatus,
    this.onDelete,
  });

  final MockTestSummary test;
  final bool admin;
  final VoidCallback? onStart;
  final VoidCallback? onEdit;
  final VoidCallback? onQuestions;
  final VoidCallback? onStatus;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(test.categoryLabel)),
                  Chip(
                      label: Text(test.dailyQuiz ? 'Daily Quiz' : 'Mock Test')),
                  if (admin)
                    Chip(
                        label: Text(test.status == 'PUBLISHED'
                            ? 'Published'
                            : 'Draft')),
                ],
              ),
              Text(test.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(test.description),
              const SizedBox(height: 8),
              Text(
                  '${test.questionCount} questions · ${test.durationMinutes} min · '
                  '${test.totalMarks.toStringAsFixed(2)} marks'
                  '${test.negativeMarking > 0 ? ' · −${test.negativeMarking} per wrong answer' : ''}'),
              const SizedBox(height: 8),
              if (admin)
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                        onPressed: onEdit, child: const Text('Edit test')),
                    TextButton(
                        onPressed: onQuestions, child: const Text('Questions')),
                    TextButton(
                      onPressed: onStatus,
                      child: Text(test.published ? 'Unpublish' : 'Publish'),
                    ),
                    TextButton(
                        onPressed: onDelete, child: const Text('Delete')),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: onStart,
                    child: const Text('Start Test'),
                  ),
                ),
            ],
          ),
        ),
      );
}

class TestFormDialog extends StatefulWidget {
  const TestFormDialog({
    super.key,
    required this.api,
    required this.categories,
    this.existing,
  });

  final MockTestsApi api;
  final List<TestCategory> categories;
  final MockTestSummary? existing;

  @override
  State<TestFormDialog> createState() => _TestFormDialogState();
}

class _TestFormDialogState extends State<TestFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _description =
      TextEditingController(text: widget.existing?.description);
  late final _duration =
      TextEditingController(text: '${widget.existing?.durationMinutes ?? 30}');
  late final _negative =
      TextEditingController(text: '${widget.existing?.negativeMarking ?? 0}');
  late final _passing = TextEditingController(
      text: widget.existing?.passingPercentage?.toString() ?? '');
  late String _category =
      widget.existing?.category ?? widget.categories.first.code;
  late String _kind = widget.existing?.kind ?? 'MOCK_TEST';
  late String _status = widget.existing?.status ?? 'DRAFT';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _duration.dispose();
    _negative.dispose();
    _passing.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await widget.api.saveTest(
        {
          'title': _title.text.trim(),
          'description': _description.text.trim(),
          'category': _category,
          'kind': _kind,
          'durationMinutes': int.parse(_duration.text),
          'negativeMarking': double.parse(_negative.text),
          'passingPercentage':
              _passing.text.trim().isEmpty ? null : double.parse(_passing.text),
          'status': _status,
        },
        id: widget.existing?.id,
      );
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title:
            Text(widget.existing == null ? 'Create test or quiz' : 'Edit test'),
        content: SizedBox(
          width: (MediaQuery.sizeOf(context).width - 80)
              .clamp(280, 500)
              .toDouble(),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField(_title, 'Test title'),
                  const SizedBox(height: 12),
                  _textField(_description, 'Description', maxLines: 3),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: widget.categories
                        .map((category) => DropdownMenuItem(
                              value: category.code,
                              child:
                                  Text('${category.group} · ${category.label}'),
                            ))
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) =>
                            setState(() => _category = value ?? _category),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _kind,
                    decoration: const InputDecoration(labelText: 'Test type'),
                    items: const [
                      DropdownMenuItem(
                          value: 'MOCK_TEST', child: Text('Mock Test')),
                      DropdownMenuItem(
                          value: 'DAILY_QUIZ', child: Text('Daily Quiz')),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _kind = value ?? _kind),
                  ),
                  const SizedBox(height: 12),
                  _numberField(_duration, 'Duration (minutes)', integer: true),
                  const SizedBox(height: 12),
                  _numberField(_negative, 'Negative marks per wrong answer'),
                  const SizedBox(height: 12),
                  _numberField(_passing, 'Passing percentage (optional)',
                      optional: true),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                      DropdownMenuItem(
                          value: 'PUBLISHED', child: Text('Published')),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _status = value ?? _status),
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
                : const Text('Save'),
          ),
        ],
      );

  Widget _textField(TextEditingController controller, String label,
          {int maxLines = 1}) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required.' : null,
      );

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool integer = false,
    bool optional = false,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty && optional) return null;
          final number = integer ? int.tryParse(text) : double.tryParse(text);
          if (number == null || !number.isFinite) {
            return 'Enter a valid number.';
          }
          if (label.startsWith('Duration') && (number < 1 || number > 600)) {
            return 'Duration must be between 1 and 600 minutes.';
          }
          if (number < 0 || (label.contains('percentage') && number > 100)) {
            return 'Enter a value between 0 and 100.';
          }
          return null;
        },
      );
}

class QuestionManagerDialog extends StatefulWidget {
  const QuestionManagerDialog({
    super.key,
    required this.api,
    required this.test,
  });

  final MockTestsApi api;
  final AdminTest test;

  @override
  State<QuestionManagerDialog> createState() => _QuestionManagerDialogState();
}

class _QuestionManagerDialogState extends State<QuestionManagerDialog> {
  late List<TestQuestion> _questions = List.of(widget.test.questions);
  bool _busy = false;

  Future<void> _editQuestion([TestQuestion? question]) async {
    final result = await showDialog<TestQuestion>(
      context: context,
      builder: (context) => QuestionFormDialog(question: question),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      final saved = await widget.api.saveQuestion(
        widget.test.test.id,
        result,
        questionId: question?.id,
      );
      if (mounted) {
        setState(() {
          if (question == null) {
            _questions = [..._questions, saved];
          } else {
            _questions = _questions
                .map((item) => item.id == saved.id ? saved : item)
                .toList();
          }
        });
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteQuestion(TestQuestion question) async {
    setState(() => _busy = true);
    try {
      await widget.api.deleteQuestion(widget.test.test.id, question.id!);
      if (mounted) {
        setState(
            () => _questions.removeWhere((item) => item.id == question.id));
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Questions · ${widget.test.test.title}'),
        content: SizedBox(
          width: (MediaQuery.sizeOf(context).width - 80)
              .clamp(280, 600)
              .toDouble(),
          height: (MediaQuery.sizeOf(context).height * 0.6)
              .clamp(240, 560)
              .toDouble(),
          child: _questions.isEmpty
              ? const Center(
                  child: Text('Add at least one question before publishing.'))
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (var index = 0; index < _questions.length; index++)
                      Card(
                        child: ListTile(
                          title: Text(
                              '${index + 1}. ${_questions[index].question}'),
                          subtitle: Text(
                              '${_questions[index].marks} marks · correct option '
                              '${String.fromCharCode(65 + (_questions[index].correctOption ?? 0))}'),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                tooltip: 'Edit question',
                                onPressed: _busy
                                    ? null
                                    : () => _editQuestion(_questions[index]),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete question',
                                onPressed: _busy
                                    ? null
                                    : () => _deleteQuestion(_questions[index]),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _busy ? null : () => _editQuestion(),
            icon: const Icon(Icons.add),
            label: const Text('Add question'),
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      );
}

class QuestionFormDialog extends StatefulWidget {
  const QuestionFormDialog({super.key, this.question});

  final TestQuestion? question;

  @override
  State<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _prompt = TextEditingController(text: widget.question?.question);
  late final _options = List.generate(
    4,
    (index) => TextEditingController(
      text: widget.question != null && widget.question!.options.length > index
          ? widget.question!.options[index]
          : '',
    ),
  );
  late final _marks =
      TextEditingController(text: '${widget.question?.marks ?? 1}');
  late final _explanation =
      TextEditingController(text: widget.question?.explanation);
  late int _correctOption = widget.question?.correctOption ?? 0;

  @override
  void dispose() {
    _prompt.dispose();
    for (final option in _options) {
      option.dispose();
    }
    _marks.dispose();
    _explanation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.question == null ? 'Add question' : 'Edit question'),
        content: SizedBox(
          width: (MediaQuery.sizeOf(context).width - 80)
              .clamp(280, 520)
              .toDouble(),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(_prompt, 'Question', maxLines: 3),
                  RadioGroup<int>(
                    groupValue: _correctOption,
                    onChanged: (value) =>
                        setState(() => _correctOption = value ?? 0),
                    child: Column(
                      children: [
                        for (var index = 0; index < 4; index++) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Radio<int>(value: index),
                              Expanded(
                                child: _field(
                                  _options[index],
                                  'Option ${String.fromCharCode(65 + index)}'
                                  '${_correctOption == index ? ' · correct answer' : ''}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _field(_marks, 'Marks per question', decimal: true),
                  const SizedBox(height: 10),
                  _field(_explanation, 'Explanation (optional)',
                      maxLines: 3, optional: true),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                TestQuestion(
                  id: widget.question?.id,
                  question: _prompt.text.trim(),
                  options: _options.map((item) => item.text.trim()).toList(),
                  correctOption: _correctOption,
                  marks: double.parse(_marks.text),
                  explanation: _explanation.text.trim().isEmpty
                      ? null
                      : _explanation.text.trim(),
                ),
              );
            },
            child: const Text('Save question'),
          ),
        ],
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool decimal = false,
    bool optional = false,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty && optional) return null;
          if (text.isEmpty) return 'Required.';
          if (decimal) {
            final number = double.tryParse(text);
            if (number == null || !number.isFinite || number <= 0) {
              return 'Enter a positive marks value.';
            }
          }
          return null;
        },
      );
}

class ActiveTestView extends StatefulWidget {
  const ActiveTestView({
    super.key,
    required this.api,
    required this.attempt,
    required this.onSubmitted,
    required this.onError,
    this.clock,
  });

  final MockTestsApi api;
  final TestAttempt attempt;
  final ValueChanged<TestResult> onSubmitted;
  final ValueChanged<String> onError;
  final DateTime Function()? clock;

  @override
  State<ActiveTestView> createState() => _ActiveTestViewState();
}

class _ActiveTestViewState extends State<ActiveTestView> {
  Timer? _timer;
  late int _remaining = _calculateRemaining();
  final Map<int, int> _answers = {};
  int _current = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _calculateRemaining();
      if (mounted) setState(() => _remaining = remaining);
      if (remaining <= 0) _submit();
    });
    if (_remaining <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _submit());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _calculateRemaining() {
    final end = widget.attempt.startedAt
        .add(Duration(minutes: widget.attempt.durationMinutes));
    return end
        .difference(widget.clock?.call() ?? DateTime.now())
        .inSeconds
        .clamp(0, 3600);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();
    try {
      final result = await widget.api.submit(widget.attempt.id, _answers);
      widget.onSubmitted(result);
    } catch (error) {
      if (mounted) {
        setState(() => _submitting = false);
        widget.onError(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.attempt.questions[_current];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(widget.attempt.testTitle,
                style: Theme.of(context).textTheme.headlineSmall),
            Chip(
              avatar: const Icon(Icons.timer_outlined),
              label: Text(_formatDuration(_remaining)),
              backgroundColor: _remaining < 60 ? Colors.red.shade50 : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < widget.attempt.questions.length; i++)
              ChoiceChip(
                label: Text('${i + 1}'),
                selected: i == _current,
                avatar: _answers.containsKey(widget.attempt.questions[i].id)
                    ? const Icon(Icons.check, size: 16)
                    : null,
                onSelected:
                    _submitting ? null : (_) => setState(() => _current = i),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Question ${_current + 1} of ${widget.attempt.questions.length}',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 12),
                Text(question.question,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                RadioGroup<int>(
                  groupValue: _answers[question.id],
                  onChanged: (value) {
                    if (!_submitting && value != null) {
                      setState(() => _answers[question.id!] = value);
                    }
                  },
                  child: Column(
                    children: [
                      for (var i = 0; i < question.options.length; i++)
                        InkWell(
                          onTap: _submitting
                              ? null
                              : () =>
                                  setState(() => _answers[question.id!] = i),
                          child: Row(
                            children: [
                              Radio<int>(value: i),
                              Expanded(child: Text(question.options[i])),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _submitting || !_answers.containsKey(question.id)
                        ? null
                        : () => setState(() => _answers.remove(question.id)),
                    child: const Text('Clear answer'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: _submitting || _current == 0
                  ? null
                  : () => setState(() => _current--),
              child: const Text('Previous'),
            ),
            const SizedBox(width: 8),
            if (_current < widget.attempt.questions.length - 1)
              FilledButton(
                onPressed:
                    _submitting ? null : () => setState(() => _current++),
                child: const Text('Next'),
              )
            else
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Submitting…' : 'Submit test'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_current < widget.attempt.questions.length - 1)
          Center(
            child: TextButton(
              onPressed: _submitting ? null : _submit,
              child: const Text('Submit test now'),
            ),
          ),
        if (_submitting) const LinearProgressIndicator(),
      ],
    );
  }
}

class TestResultView extends StatelessWidget {
  const TestResultView({super.key, required this.result, required this.onBack});

  final TestResult result;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to tests'),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test Result',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(result.testTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, constraints) {
                    final columns = constraints.maxWidth > 640 ? 3 : 2;
                    final width =
                        (constraints.maxWidth - 12 * (columns - 1)) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _ResultStat(
                            'Marks',
                            '${result.marksObtained.toStringAsFixed(2)} / ${result.totalMarks.toStringAsFixed(2)}',
                            width),
                        _ResultStat('Percentage',
                            '${result.percentage.toStringAsFixed(2)}%', width),
                        _ResultStat(
                            'Correct', '${result.correctAnswers}', width),
                        _ResultStat(
                            'Incorrect', '${result.incorrectAnswers}', width),
                        _ResultStat('Unanswered',
                            '${result.unansweredQuestions}', width),
                        _ResultStat('Time taken',
                            _formatDuration(result.timeTakenSeconds), width),
                      ],
                    );
                  }),
                  if (result.passed != null) ...[
                    const SizedBox(height: 12),
                    Chip(
                      avatar: Icon(
                          result.passed! ? Icons.check_circle : Icons.cancel),
                      label: Text(result.passed! ? 'Passed' : 'Not passed'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('Question-wise review',
                      style: Theme.of(context).textTheme.titleLarge),
                  for (var index = 0; index < result.questions.length; index++)
                    _ReviewCard(
                        index: index, question: result.questions[index]),
                ],
              ),
            ),
          ),
        ],
      );
}

class _ResultStat extends StatelessWidget {
  const _ResultStat(this.label, this.value, this.width);
  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.index, required this.question});
  final int index;
  final TestResultQuestion question;

  @override
  Widget build(BuildContext context) {
    final color = question.correct == null
        ? Colors.orange
        : question.correct!
            ? Colors.green
            : Colors.red;
    final status = question.correct == null
        ? 'Unanswered'
        : question.correct!
            ? 'Correct'
            : 'Incorrect';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('Question ${index + 1}',
                        style: Theme.of(context).textTheme.labelLarge)),
                Text(status,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(question.question),
            const SizedBox(height: 8),
            Text(
                'Your answer: ${question.selectedOption == null ? 'Unanswered' : question.options[question.selectedOption!]}'),
            Text('Correct answer: ${question.options[question.correctOption]}'),
            if (question.explanation?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text('Explanation: ${question.explanation}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
  );
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
}
