import 'dart:convert';

import 'package:careervault_app/api.dart';
import 'package:careervault_app/preparation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

void main() {
  testWidgets('public preparation page loads, filters and opens a lesson',
      (tester) async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      if (request.url.path.endsWith('/preparation/categories')) {
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'name': 'Java Development',
              'slug': 'java-development',
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
              'id': 4,
              'category': {
                'id': 1,
                'name': 'Java Development',
                'slug': 'java-development',
                'published': true,
              },
              'title': 'Java Introduction',
              'slug': 'java-introduction',
              'introduction': 'Start learning Java.',
              'explanation': 'Java runs on the Java Virtual Machine.',
              'published': true,
              'subtopics': [],
              'resources': [],
              'referenceLinks': [],
            },
          ],
          'page': 0,
          'size': 50,
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
        body: PreparationScreen(
          admin: false,
          api: PreparationApi(client: client),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('IT Preparation'), findsOneWidget);
    expect(find.text('Java Development'), findsOneWidget);
    expect(find.text('Java Introduction'), findsOneWidget);
    expect(requests, hasLength(2));

    await tester.tap(find.text('Java Introduction'));
    await tester.pumpAndSettle();
    expect(find.text('Java runs on the Java Virtual Machine.'), findsOneWidget);
    expect(find.text('Back to topics'), findsOneWidget);
  });
}
