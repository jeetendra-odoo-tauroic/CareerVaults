import 'dart:convert';

import 'package:careervault_app/api.dart';
import 'package:careervault_app/public_jobs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Job _job({
  required int id,
  required String title,
  required String category,
  String experience = 'Entry level',
  String? description,
  String? qualification = 'Bachelor degree',
  String? location = 'Remote',
  String? salary = 'Competitive',
  String? createdAt,
}) =>
    Job(
      id: id,
      title: title,
      organisation: 'Organisation $id',
      category: category,
      experienceLevel: experience,
      applicationStartDate: '2026-10-01',
      closingDate: '2027-12-01',
      status: 'PUBLISHED',
      qualification: qualification,
      location: location,
      salary: salary,
      description: description,
      createdAt: createdAt ??
          '2026-10-${(id % 27 + 1).toString().padLeft(2, '0')}T10:00:00',
    );

void main() {
  final jobs = [
    _job(
      id: 1,
      title: 'Banking IT Engineer',
      category: 'Government IT',
      description: 'Public sector banking technical recruitment',
    ),
    _job(
      id: 2,
      title: 'Java Developer',
      category: 'Private IT',
      experience: '1–3 years',
      description: 'Spring Boot backend development',
      createdAt: '2026-11-02T10:00:00',
    ),
    _job(
      id: 3,
      title: 'Cloud Engineer',
      category: 'Private IT',
      experience: '5+ years',
      location: 'Onsite',
      description: 'Manage cloud services',
      createdAt: '2026-11-03T10:00:00',
    ),
    ...List.generate(
      20,
      (index) => _job(
        id: index + 4,
        title: 'Software Developer $index',
        category: 'Private IT',
        createdAt:
            '2026-10-${(index % 27 + 1).toString().padLeft(2, '0')}T10:00:00',
      ),
    ),
  ];

  test('government page classifies and filters government IT jobs', () {
    final result = filterJobs(
      jobs,
      government: true,
      category: 'Government IT / Technical',
    );

    expect(result.map((job) => job.id), [1]);
  });

  test('government filters include organisation, qualification and location',
      () {
    final result = filterJobs(
      jobs,
      government: true,
      organisation: 'Organisation 1',
      qualification: 'Bachelor degree',
      location: 'Remote',
      applicationStatus: 'Open',
    );

    expect(result.map((job) => job.id), [1]);
  });

  test('private IT page filters technology and experience', () {
    final result = filterJobs(
      jobs,
      government: false,
      search: 'spring boot',
      experience: '0–2 years',
    );

    expect(result.map((job) => job.id), [2]);
  });

  test('search matches technology in the job description', () {
    final result = filterJobs(
      jobs,
      government: false,
      search: 'cloud services',
    );

    expect(result.map((job) => job.id), [3]);
  });

  test('private IT salary and work-mode filters are applied', () {
    final result = filterJobs(
      jobs.take(3).toList(),
      government: false,
      salary: 'Salary disclosed',
      workMode: 'Remote',
    );

    expect(result.map((job) => job.id), [2]);
  });

  test('pagination sorts newest first and returns the requested page', () {
    final firstPage = filterAndPaginateJobs(jobs, government: false);
    final secondPage = filterAndPaginateJobs(jobs, government: false, page: 1);

    expect(countFilteredJobs(jobs, government: false), 22);
    expect(firstPage, hasLength(10));
    expect(secondPage, hasLength(10));
    expect(firstPage.first.id, 3);
    expect(
        firstPage
            .map((job) => job.id)
            .toSet()
            .intersection(secondPage.map((job) => job.id).toSet()),
        isEmpty);
  });

  testWidgets('job details show information and official links',
      (tester) async {
    final job = Job(
      id: 8,
      title: 'Backend Developer',
      organisation: 'Example Organisation',
      category: 'Private IT',
      experienceLevel: '2–5 years',
      applicationStartDate: '2026-11-01',
      closingDate: '2026-12-01',
      status: 'PUBLISHED',
      qualification: 'Bachelor degree',
      salary: 'Competitive',
      location: 'Remote',
      description: 'Build reliable services.',
      applicationUrl: 'https://jobs.example.com/apply',
      notificationFileName: 'notification.pdf',
      createdAt: '2026-10-30T10:00:00',
    );

    final openedLinks = <Uri>[];
    await tester.pumpWidget(MaterialApp(
      home: JobDetailsScreen(
        api: JobApi(),
        job: job,
        openLink: (uri) async {
          openedLinks.add(uri);
          return true;
        },
      ),
    ));

    expect(find.text('Backend Developer'), findsOneWidget);
    expect(find.text('Build reliable services.'), findsOneWidget);
    expect(find.text('Bachelor degree'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Official notification PDF'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Official notification PDF'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Apply on the official website'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Apply on the official website'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Official notification PDF'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Official notification PDF'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Apply on the official website'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Apply on the official website'));
    await tester.pump();

    expect(openedLinks, [
      Uri.parse('http://localhost:8080/api/jobs/8/notification'),
      Uri.parse('https://jobs.example.com/apply'),
    ]);
  });

  testWidgets('government listings show latest public government jobs',
      (tester) async {
    final api = _apiFor([
      jobs.first,
    ]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PublicJobsScreen(api: api, government: true),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Government Jobs'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Banking IT Engineer'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Banking IT Engineer'), findsOneWidget);
    await tester.ensureVisible(find.text('View Details'));
    expect(find.text('View Details'), findsOneWidget);
    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();
    expect(find.text('Job details'), findsOneWidget);
  });

  testWidgets('private IT listings support technology search on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _apiFor([jobs[1], jobs[2]]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PublicJobsScreen(api: api, government: false),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Private IT Jobs'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'cloud services');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

JobApi _apiFor(List<Job> jobs) => JobApi(
      client: MockClient((request) async => http.Response(
            jsonEncode(jobs
                .map((job) => {
                      'id': job.id,
                      'title': job.title,
                      'organisation': job.organisation,
                      'category': job.category,
                      'experienceLevel': job.experienceLevel,
                      'applicationStartDate': job.applicationStartDate,
                      'closingDate': job.closingDate,
                      'status': job.status,
                      'description': job.description,
                      'createdAt': job.createdAt,
                    })
                .toList()),
            200,
          )),
    );
