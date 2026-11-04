import 'dart:convert';

import 'package:careervault_app/interview_api.dart';
import 'package:careervault_app/interview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('maps interview article content and experience levels', () {
    final topic = InterviewTopic.fromJson({
      'id': 5,
      'category': {
        'id': 1,
        'name': 'Java Interviews',
        'slug': 'java-interviews',
        'published': true,
      },
      'title': 'Core Java',
      'slug': 'core-java',
      'introduction': 'Prepare for Java interviews.',
      'article': 'Review Java language concepts.',
      'experienceLevels': ['Fresher', '0–2 years'],
      'published': true,
    });

    expect(topic.category.slug, 'java-interviews');
    expect(topic.article, 'Review Java language concepts.');
    expect(topic.experienceLevels, ['Fresher', '0–2 years']);
  });

  test('sends category, search, experience and page filters to the API',
      () async {
    Uri? requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response(
        jsonEncode({
          'content': [],
          'page': 2,
          'size': 10,
          'totalElements': 24,
          'totalPages': 3,
          'first': false,
          'last': true,
        }),
        200,
      );
    });

    final result = await InterviewApi(client: client).topics(
      admin: false,
      categorySlug: 'spring-interviews',
      search: 'spring boot',
      experienceLevel: '2–5 years',
      page: 2,
    );

    expect(requested!.queryParameters['category'], 'spring-interviews');
    expect(requested!.queryParameters['search'], 'spring boot');
    expect(requested!.queryParameters['experienceLevel'], '2–5 years');
    expect(requested!.queryParameters['page'], '2');
    expect(result.totalPages, 3);
    expect(result.totalElements, 24);
  });

  testWidgets(
      'landing categories filter articles and open details responsively',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requestedUris = <Uri>[];
    final client = MockClient((request) async {
      requestedUris.add(request.url);
      if (request.url.path == '/api/interviews/categories') {
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'name': 'Java Interviews',
              'slug': 'java-interviews',
              'description': 'Java interview preparation.',
              'published': true,
            },
          ]),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'content': [
            {
              'id': 5,
              'category': {
                'id': 1,
                'name': 'Java Interviews',
                'slug': 'java-interviews',
                'published': true,
              },
              'title': 'Core Java',
              'slug': 'core-java',
              'introduction': 'Prepare for Java interviews.',
              'article': 'Review Java language concepts.',
              'experienceLevels': ['Fresher'],
              'published': true,
            },
          ],
          'page': 0,
          'size': 10,
          'totalElements': 1,
          'totalPages': 1,
          'first': true,
          'last': true,
        }),
        200,
      );
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: InterviewScreen(admin: false, api: InterviewApi(client: client)),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Private IT Interview Preparation'), findsOneWidget);
    expect(find.text('Popular interview categories'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Core Java'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Core Java'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(requestedUris, hasLength(2));

    await tester.tap(find.text('Core Java'));
    await tester.pumpAndSettle();
    expect(find.text('Review Java language concepts.'), findsOneWidget);
    expect(find.text('Back to interview topics'), findsOneWidget);
  });
}
