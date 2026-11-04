import 'dart:convert';

import 'package:careervault_app/course_api.dart';
import 'package:careervault_app/course_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('maps course details and keeps optional image absent', () {
    final course = Course.fromJson({
      'id': 42,
      'name': 'Java Development',
      'category': 'Programming',
      'description': 'A practical course.',
      'price': 2499.5,
      'status': 'PUBLISHED',
      'imageUrl': null,
    });

    expect(course.name, 'Java Development');
    expect(course.price, 2499.5);
    expect(course.published, isTrue);
    expect(course.imageUri, isNull);
    expect(course.toJson(), containsPair('status', 'PUBLISHED'));
  });

  test('uses the public endpoints for course listings and details', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      return http.Response(
        jsonEncode(request.url.path == '/api/courses'
            ? [_courseJson()]
            : _courseJson()),
        200,
      );
    });
    final api = CourseApi(client: client);

    final courses = await api.courses(admin: false);
    final detail = await api.course(courses.first.id);

    expect(paths, ['/api/courses', '/api/courses/42']);
    expect(detail.description, 'Build and deploy applications.');
    api.close();
  });

  testWidgets('shows public courses and opens course details on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = MockClient((request) async => http.Response(
          jsonEncode(request.url.path == '/api/courses'
              ? [_courseJson()]
              : _courseJson()),
          200,
        ));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CourseScreen(admin: false, api: CourseApi(client: client))),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Online Classes'), findsOneWidget);
    expect(find.text('Java Development'), findsOneWidget);
    expect(find.text('View Details'), findsOneWidget);
    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();

    expect(find.text('Build and deploy applications.'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin can add, edit, publish and delete a course',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var exists = false;
    var name = '';
    var category = '';
    var description = '';
    var price = 0.0;
    var status = 'UNPUBLISHED';
    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/api/admin/courses') {
        return http.Response(
          jsonEncode(exists ? [_courseJson(
            name: name,
            category: category,
            description: description,
            price: price,
            status: status,
          )] : []),
          200,
        );
      }
      if (request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        exists = true;
        name = body['name'] as String;
        category = body['category'] as String;
        description = body['description'] as String;
        price = (body['price'] as num).toDouble();
        status = body['status'] as String;
        return http.Response(
          jsonEncode(_courseJson(
            name: name,
            category: category,
            description: description,
            price: price,
            status: status,
          )),
          200,
        );
      }
      if (request.method == 'PUT' &&
          request.url.path == '/api/admin/courses/42/status') {
        status = (jsonDecode(request.body) as Map<String, dynamic>)['status']
            as String;
        return http.Response('{}', 200);
      }
      if (request.method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        name = body['name'] as String;
        category = body['category'] as String;
        description = body['description'] as String;
        price = (body['price'] as num).toDouble();
        status = body['status'] as String;
        return http.Response(
          jsonEncode(_courseJson(
            name: name,
            category: category,
            description: description,
            price: price,
            status: status,
          )),
          200,
        );
      }
      if (request.method == 'DELETE') {
        exists = false;
        return http.Response('', 204);
      }
      return http.Response('Unexpected request', 500);
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CourseScreen(admin: true, api: CourseApi(client: client))),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add course'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Java Development');
    await tester.enterText(find.byType(TextFormField).at(1), 'Programming');
    await tester.enterText(find.byType(TextFormField).at(2), 'A Java course.');
    await tester.enterText(find.byType(TextFormField).at(3), '99.50');
    await tester.tap(find.text('Save course'));
    await tester.pumpAndSettle();

    expect(find.text('Java Development'), findsOneWidget);
    expect(find.text('Publish'), findsOneWidget);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).at(0), 'Java Development Updated');
    await tester.tap(find.text('Save course'));
    await tester.pumpAndSettle();
    expect(find.text('Java Development Updated'), findsOneWidget);

    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();
    expect(status, 'PUBLISHED');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Delete'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('No courses are available yet.'), findsOneWidget);
    expect(exists, isFalse);
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _courseJson({
      String name = 'Java Development',
      String category = 'Programming',
      String description = 'Build and deploy applications.',
      double price = 2499.50,
      String status = 'PUBLISHED',
    }) =>
    {
      'id': 42,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'status': status,
      'imageUrl': null,
      'createdAt': '2026-01-05T10:00:00',
    };
