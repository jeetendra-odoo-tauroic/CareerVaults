import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart' show apiBaseUrl, AuthenticatedHttpClient;

class MockTestSummary {
  const MockTestSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.categoryLabel,
    required this.kind,
    required this.durationMinutes,
    required this.negativeMarking,
    required this.status,
    required this.questionCount,
    required this.totalMarks,
    this.passingPercentage,
    this.createdAt,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final String categoryLabel;
  final String kind;
  final int durationMinutes;
  final double negativeMarking;
  final double? passingPercentage;
  final String status;
  final int questionCount;
  final double totalMarks;
  final String? createdAt;

  bool get published => status == 'PUBLISHED';
  bool get dailyQuiz => kind == 'DAILY_QUIZ';

  factory MockTestSummary.fromJson(Map<String, dynamic> json) =>
      MockTestSummary(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? '',
        categoryLabel: json['categoryLabel'] as String? ?? '',
        kind: json['kind'] as String? ?? 'MOCK_TEST',
        durationMinutes: json['durationMinutes'] as int? ?? 1,
        negativeMarking: (json['negativeMarking'] as num?)?.toDouble() ?? 0,
        passingPercentage: (json['passingPercentage'] as num?)?.toDouble(),
        status: json['status'] as String? ?? 'DRAFT',
        questionCount: json['questionCount'] as int? ?? 0,
        totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 0,
        createdAt: json['createdAt'] as String?,
      );
}

class TestCategory {
  const TestCategory({
    required this.code,
    required this.label,
    required this.group,
  });

  final String code;
  final String label;
  final String group;

  factory TestCategory.fromJson(Map<String, dynamic> json) => TestCategory(
        code: json['code'] as String? ?? '',
        label: json['label'] as String? ?? '',
        group: json['group'] as String? ?? '',
      );
}

class TestQuestion {
  const TestQuestion({
    this.id,
    required this.question,
    required this.options,
    this.correctOption,
    required this.marks,
    this.explanation,
  });

  final int? id;
  final String question;
  final List<String> options;
  final int? correctOption;
  final double marks;
  final String? explanation;

  factory TestQuestion.fromJson(Map<String, dynamic> json) => TestQuestion(
        id: json['id'] as int?,
        question: json['question'] as String? ?? '',
        options: (json['options'] as List<dynamic>? ?? []).cast<String>(),
        correctOption: json['correctOption'] as int?,
        marks: (json['marks'] as num?)?.toDouble() ?? 1,
        explanation: json['explanation'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctOption': correctOption,
        'marks': marks,
        'explanation': explanation,
      };
}

class AdminTest {
  const AdminTest({required this.test, required this.questions});

  final MockTestSummary test;
  final List<TestQuestion> questions;

  factory AdminTest.fromJson(Map<String, dynamic> json) => AdminTest(
        test: MockTestSummary.fromJson(json['test'] as Map<String, dynamic>),
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((item) => TestQuestion.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class TestAttempt {
  const TestAttempt({
    required this.id,
    required this.testTitle,
    required this.durationMinutes,
    required this.startedAt,
    required this.questions,
  });

  final String id;
  final String testTitle;
  final int durationMinutes;
  final DateTime startedAt;
  final List<TestQuestion> questions;

  factory TestAttempt.fromJson(Map<String, dynamic> json) => TestAttempt(
        id: json['attemptId'] as String,
        testTitle: json['testTitle'] as String? ?? '',
        durationMinutes: json['durationMinutes'] as int? ?? 1,
        startedAt: DateTime.parse(json['startedAt'] as String),
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((item) => TestQuestion.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class TestResultQuestion {
  const TestResultQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.selectedOption,
    required this.correctOption,
    required this.correct,
    required this.marksAwarded,
    this.explanation,
  });

  final int id;
  final String question;
  final List<String> options;
  final int? selectedOption;
  final int correctOption;
  final bool? correct;
  final double marksAwarded;
  final String? explanation;

  factory TestResultQuestion.fromJson(Map<String, dynamic> json) =>
      TestResultQuestion(
        id: json['id'] as int,
        question: json['question'] as String? ?? '',
        options: (json['options'] as List<dynamic>? ?? []).cast<String>(),
        selectedOption: json['selectedOption'] as int?,
        correctOption: json['correctOption'] as int? ?? 0,
        correct: json['correct'] as bool?,
        marksAwarded: (json['marksAwarded'] as num?)?.toDouble() ?? 0,
        explanation: json['explanation'] as String?,
      );
}

class TestResult {
  const TestResult({
    required this.attemptId,
    required this.testId,
    required this.testTitle,
    required this.totalQuestions,
    required this.attemptedQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.unansweredQuestions,
    required this.totalMarks,
    required this.marksObtained,
    required this.percentage,
    required this.timeTakenSeconds,
    required this.questions,
    this.passingPercentage,
    this.passed,
    this.submittedAt,
  });

  final String attemptId;
  final int testId;
  final String testTitle;
  final int totalQuestions;
  final int attemptedQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final int unansweredQuestions;
  final double totalMarks;
  final double marksObtained;
  final double percentage;
  final int timeTakenSeconds;
  final double? passingPercentage;
  final bool? passed;
  final String? submittedAt;
  final List<TestResultQuestion> questions;

  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
        attemptId: json['attemptId'] as String,
        testId: json['testId'] as int,
        testTitle: json['testTitle'] as String? ?? '',
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        attemptedQuestions: json['attemptedQuestions'] as int? ?? 0,
        correctAnswers: json['correctAnswers'] as int? ?? 0,
        incorrectAnswers: json['incorrectAnswers'] as int? ?? 0,
        unansweredQuestions: json['unansweredQuestions'] as int? ?? 0,
        totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 0,
        marksObtained: (json['marksObtained'] as num?)?.toDouble() ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
        timeTakenSeconds: json['timeTakenSeconds'] as int? ?? 0,
        passingPercentage: (json['passingPercentage'] as num?)?.toDouble(),
        passed: json['passed'] as bool?,
        submittedAt: json['submittedAt'] as String?,
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((item) =>
                TestResultQuestion.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class MockTestsApi {
  MockTestsApi({http.Client? client})
      : _client = AuthenticatedHttpClient(client ?? http.Client());

  final http.Client _client;
  Uri get _base => Uri.parse(apiBaseUrl.replaceFirst(RegExp(r'/$'), ''));

  Uri _uri(String path) => _base.replace(path: '${_base.path}$path');

  Future<Map<String, String>> _headers({bool json = false}) async => {
        if (json) 'Content-Type': 'application/json',
      };

  Future<List<MockTestSummary>> tests({required bool admin}) async {
    final response = await _client.get(
      _uri(admin ? '/api/admin/tests' : '/api/tests'),
      headers: await _headers(),
    );
    return _decodeList(response).map(MockTestSummary.fromJson).toList();
  }

  Future<List<TestCategory>> categories() async {
    final response = await _client.get(
      _uri('/api/test-categories'),
      headers: await _headers(),
    );
    return _decodeList(response).map(TestCategory.fromJson).toList();
  }

  Future<MockTestSummary?> latestDailyQuiz() async {
    final response = await _client.get(
      _uri('/api/daily-quiz'),
      headers: await _headers(),
    );
    if (response.statusCode == 204) return null;
    return MockTestSummary.fromJson(_decodeMap(response));
  }

  Future<AdminTest> adminTest(int id) async => AdminTest.fromJson(
        _decodeMap(await _client.get(
          _uri('/api/admin/tests/$id'),
          headers: await _headers(),
        )),
      );

  Future<AdminTest> saveTest(
    Map<String, dynamic> values, {
    int? id,
  }) async {
    final headers = await _headers(json: true);
    final response = id == null
        ? await _client.post(
            _uri('/api/admin/tests'),
            headers: headers,
            body: jsonEncode(values),
          )
        : await _client.put(
            _uri('/api/admin/tests/$id'),
            headers: headers,
            body: jsonEncode(values),
          );
    return AdminTest.fromJson(_decodeMap(response));
  }

  Future<TestQuestion> saveQuestion(
    int testId,
    TestQuestion question, {
    int? questionId,
  }) async {
    final path = questionId == null
        ? '/api/admin/tests/$testId/questions'
        : '/api/admin/tests/$testId/questions/$questionId';
    final response = questionId == null
        ? await _client.post(
            _uri(path),
            headers: await _headers(json: true),
            body: jsonEncode(question.toJson()),
          )
        : await _client.put(
            _uri(path),
            headers: await _headers(json: true),
            body: jsonEncode(question.toJson()),
          );
    return TestQuestion.fromJson(_decodeMap(response));
  }

  Future<void> deleteQuestion(int testId, int questionId) async {
    _check(await _client.delete(
      _uri('/api/admin/tests/$testId/questions/$questionId'),
      headers: await _headers(),
    ));
  }

  Future<void> setStatus(int id, String status) async {
    _check(await _client.put(
      _uri('/api/admin/tests/$id/status'),
      headers: await _headers(json: true),
      body: jsonEncode({'status': status}),
    ));
  }

  Future<void> deleteTest(int id) async {
    _check(await _client.delete(
      _uri('/api/admin/tests/$id'),
      headers: await _headers(),
    ));
  }

  Future<TestAttempt> start(int testId) async => TestAttempt.fromJson(
        _decodeMap(await _client.post(
          _uri('/api/tests/$testId/attempts'),
          headers: await _headers(),
        )),
      );

  Future<TestResult> submit(
    String attemptId,
    Map<int, int> answers,
  ) async {
    final response = await _client.post(
      _uri('/api/test-attempts/$attemptId/submit'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'answers': answers.map((key, value) => MapEntry('$key', value)),
      }),
    );
    return TestResult.fromJson(_decodeMap(response));
  }

  Future<List<TestResult>> history() async => _decodeList(await _client.get(
        _uri('/api/test-attempts/history'),
        headers: await _headers(),
      ))
          .map(TestResult.fromJson)
          .toList();

  Future<TestResult> result(String attemptId) async => TestResult.fromJson(
        _decodeMap(await _client.get(
          _uri('/api/test-attempts/$attemptId'),
          headers: await _headers(),
        )),
      );

  List<Map<String, dynamic>> _decodeList(http.Response response) {
    _check(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    _check(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    var message = 'Request failed (${response.statusCode}).';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] is String) message = body['error'];
    } on FormatException {
      // Keep the HTTP status message when the server does not return JSON.
    }
    throw Exception(message);
  }

  void close() => _client.close();
}
