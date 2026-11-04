import 'dart:convert';

import 'package:careervault_app/guidance_api.dart';
import 'package:careervault_app/guidance_screen.dart';
import 'package:careervault_app/api.dart' show AuthSession;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _categories = [
  {'code': 'FRESHERS', 'label': 'Career Guidance for Freshers'},
  {'code': 'JAVA_ROADMAP', 'label': 'Java Career Roadmap'},
];

Map<String, dynamic> _article({
  String status = 'PUBLISHED',
  String? content,
  String? imageUrl,
}) =>
    {
      'id': 42,
      'title': 'Java Career Roadmap',
      'category': 'JAVA_ROADMAP',
      'categoryLabel': 'Java Career Roadmap',
      'shortDescription': 'A practical roadmap for Java developers.',
      if (content != null) 'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'status': status,
      'createdAt': '2026-01-02T03:04:05',
      'updatedAt': '2026-01-03T03:04:05',
    };

void main() {
  test('admin API requests use the account bearer token', () async {
    String? authorization;
    AuthSession.set('test-secret', {'role': 'ADMIN'});
    final api = GuidanceApi(client: MockClient((request) async {
      authorization = request.headers['authorization'];
      return http.Response(jsonEncode([_article()]), 200);
    }));

    await api.articles(admin: true);

    expect(authorization, 'Bearer test-secret');
    expect(api.adminHeaders['Authorization'], 'Bearer test-secret');
    api.close();
    AuthSession.clear();
  });

  testWidgets('public page shows published articles and opens details',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = GuidanceApi(
      client: MockClient((request) async {
        if (request.url.path == '/api/guidance/categories') {
          return http.Response(jsonEncode(_categories), 200);
        }
        if (request.url.path == '/api/guidance/42') {
          return http.Response(
            jsonEncode(_article(
              content: 'Start with Core Java, then build real projects.',
            )),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'articles': [_article()],
            'categories': _categories,
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CareerGuidanceScreen(admin: false, api: api)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Java Career Roadmap'), findsWidgets);
    expect(
        find.text('A practical roadmap for Java developers.'), findsOneWidget);

    await tester.ensureVisible(find.text('Read More'));
    await tester.tap(find.text('Read More'));
    await tester.pumpAndSettle();
    expect(find.text('Start with Core Java, then build real projects.'),
        findsOneWidget);
  });

  testWidgets('public title search displays the empty-results message',
      (tester) async {
    final requests = <Uri>[];
    final api = GuidanceApi(
      client: MockClient((request) async {
        requests.add(request.url);
        if (request.url.path == '/api/guidance/categories') {
          return http.Response(jsonEncode(_categories), 200);
        }
        return http.Response(
          jsonEncode({'articles': [], 'categories': _categories}),
          200,
        );
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CareerGuidanceScreen(admin: false, api: api)),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'No matching article');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('No career guidance articles found.'), findsOneWidget);
    expect(
        requests.any(
            (uri) => uri.queryParameters['search'] == 'No matching article'),
        isTrue);
  });

  testWidgets('admin account opens article management', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var status = 'UNPUBLISHED';
    String? receivedAuthorization;
    AuthSession.set('test-admin-token', {'role': 'ADMIN'});
    final api = GuidanceApi(
      client: MockClient((request) async {
        if (request.url.path == '/api/guidance/categories') {
          return http.Response(jsonEncode(_categories), 200);
        }
        receivedAuthorization = request.headers['authorization'];
        if (request.method == 'PUT' && request.url.path.endsWith('/status')) {
          status = (jsonDecode(request.body) as Map<String, dynamic>)['status']
              as String;
          return http.Response(jsonEncode(_article(status: status)), 200);
        }
        return http.Response(jsonEncode([_article(status: status)]), 200);
      }),
    );
    addTearDown(api.close);
    addTearDown(AuthSession.clear);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CareerGuidanceScreen(admin: true, api: api)),
    ));
    await tester.pumpAndSettle();

    expect(receivedAuthorization, 'Bearer test-admin-token');
    expect(find.text('Manage Career Guidance'), findsOneWidget);
    expect(find.text('Unpublished'), findsOneWidget);
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();
    expect(find.text('Published'), findsOneWidget);
  });
}
