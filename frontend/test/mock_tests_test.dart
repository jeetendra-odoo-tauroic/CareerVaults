import 'dart:convert';

import 'package:careervault_app/mock_tests_api.dart';
import 'package:careervault_app/mock_tests_screen.dart';
import 'package:careervault_app/api.dart' show AuthSession;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('maps test metadata and result evaluation fields', () {
    final test = MockTestSummary.fromJson(_testSummary());
    expect(test.categoryLabel, 'Core Java');
    expect(test.questionCount, 2);

    final result = TestResult.fromJson(_result());
    expect(result.correctAnswers, 1);
    expect(result.incorrectAnswers, 1);
    expect(result.percentage, 50);
  });

  testWidgets('public visitor sees tests but login is required for history',
      (tester) async {
    final requests = <http.Request>[];
    var loginTapped = false;
    var registerTapped = false;
    final api = MockTestsApi(client: MockClient((request) async {
      requests.add(request);
      switch (request.url.path) {
        case '/api/tests':
          return http.Response(jsonEncode([_testSummary()]), 200);
        case '/api/test-categories':
          return http.Response('[]', 200);
        case '/api/daily-quiz':
          return http.Response('', 204);
        default:
          return http.Response('Unexpected endpoint', 500);
      }
    }));
    addTearDown(api.close);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MockTestsScreen(
          admin: false,
          api: api,
          onLogin: () => loginTapped = true,
          onRegister: () => registerTapped = true,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Java Basics'), findsOneWidget);
    expect(requests.any((request) => request.url.path.endsWith('/history')),
        isFalse);

    await tester.tap(find.text('Result history'));
    await tester.pumpAndSettle();
    expect(find.text('Please log in to access this feature.'), findsOneWidget);
    await tester.tap(find.text('Log in'));
    await tester.tap(find.text('Register'));
    expect(loginTapped, isTrue);
    expect(registerTapped, isTrue);
  });

  testWidgets('candidate navigates questions and sees server-evaluated result',
      (tester) async {
    AuthSession.set('student-token', {'role': 'STUDENT'});
    addTearDown(AuthSession.clear);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      switch (request.url.path) {
        case '/api/tests':
          return http.Response(jsonEncode([_testSummary()]), 200);
        case '/api/test-categories':
          return http.Response('[]', 200);
        case '/api/daily-quiz':
          return http.Response('', 204);
        case '/api/test-attempts/history':
          return http.Response('[]', 200);
        case '/api/tests/8/attempts':
          return http.Response(
              jsonEncode({
                'attemptId': 'attempt-8',
                'testTitle': 'Java Basics',
                'durationMinutes': 20,
                'startedAt': DateTime.now().toIso8601String(),
                'questions': [
                  {
                    'id': 51,
                    'question': 'Which keyword creates a class?',
                    'options': ['class', 'object', 'new', 'extends'],
                  },
                  {
                    'id': 52,
                    'question': 'Which type stores true or false?',
                    'options': ['String', 'boolean', 'int', 'char'],
                  },
                ],
              }),
              200);
        case '/api/test-attempts/attempt-8/submit':
          expect(request.headers['authorization'], 'Bearer student-token');
          expect(request.body, contains('"51":0'));
          expect(request.body, contains('"52":0'));
          return http.Response(jsonEncode(_result()), 200);
        default:
          return http.Response('Unexpected endpoint: ${request.url.path}', 500);
      }
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MockTestsScreen(
          admin: false,
          api: MockTestsApi(client: client),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'listing should fit');

    expect(find.text('Latest Daily Quiz'), findsNothing);
    expect(find.text('Java Basics'), findsOneWidget);
    await tester.tap(find.text('Start Test'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'active test should fit');
    expect(find.text('Which keyword creates a class?'), findsOneWidget);
    expect(requests.last.headers['authorization'], 'Bearer student-token');

    await tester.tap(find.text('class'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
        reason: 'question navigation should fit');
    expect(find.text('Which type stores true or false?'), findsOneWidget);
    await tester.tap(find.text('String').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit test'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'result should fit');
    expect(requests.last.url.path, '/api/test-attempts/attempt-8/submit');

    expect(find.text('Test Result'), findsOneWidget);
    expect(find.text('50.00%'), findsOneWidget);
    expect(find.text('Correct answer: class'), findsOneWidget);
    expect(find.text('Correct answer: boolean'), findsOneWidget);
  });

  testWidgets('automatically submits when the test timer expires',
      (tester) async {
    AuthSession.set('student-token', {'role': 'STUDENT'});
    addTearDown(AuthSession.clear);
    final requests = <http.Request>[];
    var now = DateTime.now();
    final client = MockClient((request) async {
      requests.add(request);
      switch (request.url.path) {
        case '/api/tests':
          return http.Response(
              jsonEncode([
                _testSummary()..['durationMinutes'] = 1,
              ]),
              200);
        case '/api/test-categories':
          return http.Response('[]', 200);
        case '/api/daily-quiz':
          return http.Response('', 204);
        case '/api/test-attempts/history':
          return http.Response('[]', 200);
        case '/api/tests/8/attempts':
          return http.Response(
              jsonEncode({
                'attemptId': 'timeout-attempt',
                'testTitle': 'Java Basics',
                'durationMinutes': 1,
                'startedAt': now.toIso8601String(),
                'questions': [
                  {
                    'id': 71,
                    'question': 'Timed question',
                    'options': ['A', 'B', 'C', 'D'],
                  },
                ],
              }),
              200);
        case '/api/test-attempts/timeout-attempt/submit':
          expect(jsonDecode(request.body), {'answers': <String, int>{}});
          return http.Response(
              jsonEncode({
                'attemptId': 'timeout-attempt',
                'testId': 8,
                'testTitle': 'Java Basics',
                'totalQuestions': 1,
                'attemptedQuestions': 0,
                'correctAnswers': 0,
                'incorrectAnswers': 0,
                'unansweredQuestions': 1,
                'totalMarks': 1,
                'marksObtained': 0,
                'percentage': 0,
                'timeTakenSeconds': 60,
                'passed': null,
                'questions': [
                  {
                    'id': 71,
                    'question': 'Timed question',
                    'options': ['A', 'B', 'C', 'D'],
                    'selectedOption': null,
                    'correctOption': 0,
                    'correct': null,
                    'marksAwarded': 0,
                  },
                ],
              }),
              200);
        default:
          return http.Response('Unexpected endpoint: ${request.url.path}', 500);
      }
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MockTestsScreen(
          admin: false,
          api: MockTestsApi(client: client),
          clock: () => now,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Test'));
    await tester.pumpAndSettle();

    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(requests.last.url.path, '/api/test-attempts/timeout-attempt/submit');
    expect(find.text('Test Result'), findsOneWidget);
    expect(find.text('Unanswered'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _testSummary() => {
      'id': 8,
      'title': 'Java Basics',
      'description': 'Core language concepts.',
      'category': 'CORE_JAVA',
      'categoryLabel': 'Core Java',
      'kind': 'MOCK_TEST',
      'durationMinutes': 20,
      'negativeMarking': 0.25,
      'passingPercentage': 40,
      'status': 'PUBLISHED',
      'questionCount': 2,
      'totalMarks': 2,
      'createdAt': '2026-11-04T10:00:00',
    };

Map<String, dynamic> _result() => {
      'attemptId': 'attempt-8',
      'testId': 8,
      'testTitle': 'Java Basics',
      'totalQuestions': 2,
      'attemptedQuestions': 2,
      'correctAnswers': 1,
      'incorrectAnswers': 1,
      'unansweredQuestions': 0,
      'totalMarks': 2,
      'marksObtained': 1,
      'percentage': 50,
      'timeTakenSeconds': 12,
      'passingPercentage': 40,
      'passed': true,
      'submittedAt': '2026-11-04T10:00:12',
      'questions': [
        {
          'id': 51,
          'question': 'Which keyword creates a class?',
          'options': ['class', 'object', 'new', 'extends'],
          'selectedOption': 0,
          'correctOption': 0,
          'correct': true,
          'marksAwarded': 1,
          'explanation': 'The class keyword defines a class.',
        },
        {
          'id': 52,
          'question': 'Which type stores true or false?',
          'options': ['String', 'boolean', 'int', 'char'],
          'selectedOption': 0,
          'correctOption': 1,
          'correct': false,
          'marksAwarded': 0,
          'explanation':
              'Boolean is the wrapper class; boolean is the primitive.',
        },
      ],
    };
