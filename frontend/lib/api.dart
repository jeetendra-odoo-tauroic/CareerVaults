import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

class AuthSession {
  static String? token;
  static String? role;
  static Map<String, dynamic>? profile;

  static bool get signedIn => token != null && profile != null;
  static bool get isAdmin => role == 'ADMIN';
  static String? get authorizationHeader =>
      token == null ? null : 'Bearer $token';

  static void set(String accessToken, Map<String, dynamic> user) {
    token = accessToken;
    profile = user;
    role = user['role'] as String?;
  }

  static void clear() {
    token = null;
    role = null;
    profile = null;
  }
}

class AuthenticatedHttpClient extends http.BaseClient {
  AuthenticatedHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final token = AuthSession.token;
    if (token != null && token.isNotEmpty) {
      request.headers.putIfAbsent('Authorization', () => 'Bearer $token');
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

class Job {
  const Job({
    required this.id,
    required this.title,
    required this.organisation,
    required this.category,
    required this.experienceLevel,
    required this.applicationStartDate,
    required this.closingDate,
    required this.status,
    this.createdAt,
    this.advertisementNumber,
    this.qualification,
    this.salary,
    this.location,
    this.description,
    this.applicationUrl,
    this.notificationFileName,
  });

  final int id;
  final String title;
  final String organisation;
  final String category;
  final String experienceLevel;
  final String applicationStartDate;
  final String closingDate;
  final String status;
  final String? createdAt;
  final String? advertisementNumber;
  final String? qualification;
  final String? salary;
  final String? location;
  final String? description;
  final String? applicationUrl;
  final String? notificationFileName;

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        organisation: json['organisation'] as String? ?? '',
        category: json['category'] as String? ?? '',
        experienceLevel: json['experienceLevel'] as String? ?? '',
        applicationStartDate: json['applicationStartDate'] as String? ?? '',
        closingDate: json['closingDate'] as String? ?? '',
        status: json['status'] as String? ?? 'DRAFT',
        createdAt: json['createdAt'] as String?,
        advertisementNumber: json['advertisementNumber'] as String?,
        qualification: json['qualification'] as String?,
        salary: json['salary'] as String?,
        location: json['location'] as String?,
        description: json['description'] as String?,
        applicationUrl: json['applicationUrl'] as String?,
        notificationFileName: json['notificationFileName'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'organisation': organisation,
        'advertisementNumber': advertisementNumber,
        'category': category,
        'experienceLevel': experienceLevel,
        'qualification': qualification,
        'salary': salary,
        'location': location,
        'applicationStartDate': applicationStartDate,
        'closingDate': closingDate,
        'description': description,
        'applicationUrl': applicationUrl,
      };
}

class JobApi {
  JobApi({http.Client? client})
      : _client = AuthenticatedHttpClient(client ?? http.Client());

  final http.Client _client;
  Uri get _base => Uri.parse(apiBaseUrl.replaceFirst(RegExp(r'/$'), ''));

  Future<List<Job>> adminJobs() async {
    final response = await _client.get(_uri('/api/admin/jobs'));
    return _decodeJobs(response);
  }

  Future<List<Job>> publicJobs(
      {String? category, String? experience, String? section}) async {
    final query = <String, String>{};
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (experience != null && experience.isNotEmpty) {
      query['experienceLevel'] = experience;
    }
    if (section != null && section.isNotEmpty) query['section'] = section;
    final response = await _client.get(_uri('/api/jobs', query));
    return _decodeJobs(response);
  }

  Future<Job> saveJob(Map<String, dynamic> job, {int? id}) async {
    final response = id == null
        ? await _client.post(
            _uri('/api/admin/jobs'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(job),
          )
        : await _client.put(
            _uri('/api/admin/jobs/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(job),
          );
    return Job.fromJson(_decodeMap(response));
  }

  Future<void> deleteJob(int id) async {
    final response = await _client.delete(_uri('/api/admin/jobs/$id'));
    _check(response);
  }

  Future<void> setStatus(int id, String status) async {
    final response = await _client.put(
      _uri('/api/admin/jobs/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    _check(response);
  }

  Future<Map<String, dynamic>> uploadJobs(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null) throw Exception('Could not read the selected file.');
    final request =
        http.MultipartRequest('POST', _uri('/api/admin/jobs/import'))
          ..headers.addAll({
            if (AuthSession.authorizationHeader != null)
              'Authorization': AuthSession.authorizationHeader!,
          })
          ..files.add(
              http.MultipartFile.fromBytes('file', bytes, filename: file.name));
    final response = await http.Response.fromStream(await request.send());
    return _decodeMap(response);
  }

  Future<Job> uploadNotification(int id, PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null) throw Exception('Could not read the selected file.');
    final request =
        http.MultipartRequest('POST', _uri('/api/admin/jobs/$id/notification'))
          ..headers.addAll({
            if (AuthSession.authorizationHeader != null)
              'Authorization': AuthSession.authorizationHeader!,
          })
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: file.name),
          );
    final response = await http.Response.fromStream(await request.send());
    return Job.fromJson(_decodeMap(response));
  }

  Uri notificationUri(int id) => _uri('/api/jobs/$id/notification');
  Uri templateUri() => _uri('/api/admin/jobs/template.csv');

  Uri _uri(String path, [Map<String, String>? query]) =>
      _base.replace(path: '${_base.path}$path', queryParameters: query);

  List<Job> _decodeJobs(http.Response response) {
    _check(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Job.fromJson(item as Map<String, dynamic>))
        .toList();
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

class PreparationCategory {
  const PreparationCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.published,
    this.description,
  });

  final int id;
  final String name;
  final String slug;
  final bool published;
  final String? description;

  factory PreparationCategory.fromJson(Map<String, dynamic> json) =>
      PreparationCategory(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        description: json['description'] as String?,
        published: json['published'] as bool? ?? false,
      );
}

class PreparationSubtopic {
  const PreparationSubtopic({
    this.id,
    required this.title,
    this.slug,
    this.content,
    this.sortOrder = 0,
  });

  final int? id;
  final String title;
  final String? slug;
  final String? content;
  final int sortOrder;

  factory PreparationSubtopic.fromJson(Map<String, dynamic> json) =>
      PreparationSubtopic(
        id: json['id'] as int?,
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String?,
        content: json['content'] as String?,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'sortOrder': sortOrder,
      };
}

class PreparationResource {
  const PreparationResource({
    required this.id,
    required this.originalName,
    required this.contentType,
    required this.kind,
    required this.url,
  });

  final int id;
  final String originalName;
  final String contentType;
  final String kind;
  final String url;

  factory PreparationResource.fromJson(Map<String, dynamic> json) =>
      PreparationResource(
        id: json['id'] as int,
        originalName: json['originalName'] as String? ?? '',
        contentType: json['contentType'] as String? ?? '',
        kind: json['kind'] as String? ?? 'RESOURCE',
        url: json['url'] as String? ?? '',
      );

  Uri get uri {
    final base = Uri.parse(apiBaseUrl.replaceFirst(RegExp(r'/$'), ''));
    return base.replace(path: '${base.path}$url');
  }
}

class PreparationTopic {
  const PreparationTopic({
    required this.id,
    required this.category,
    required this.title,
    required this.slug,
    required this.introduction,
    required this.explanation,
    required this.published,
    this.codeExamples,
    this.practicalExamples,
    this.referenceLinks = const [],
    this.subtopics = const [],
    this.resources = const [],
    this.createdAt,
  });

  final int id;
  final PreparationCategory category;
  final String title;
  final String slug;
  final String introduction;
  final String explanation;
  final bool published;
  final String? codeExamples;
  final String? practicalExamples;
  final List<String> referenceLinks;
  final List<PreparationSubtopic> subtopics;
  final List<PreparationResource> resources;
  final String? createdAt;

  factory PreparationTopic.fromJson(Map<String, dynamic> json) =>
      PreparationTopic(
        id: json['id'] as int,
        category: PreparationCategory.fromJson(
          json['category'] as Map<String, dynamic>,
        ),
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        introduction: json['introduction'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        published: json['published'] as bool? ?? false,
        codeExamples: json['codeExamples'] as String?,
        practicalExamples: json['practicalExamples'] as String?,
        referenceLinks: (json['referenceLinks'] as List<dynamic>? ?? [])
            .whereType<String>()
            .toList(),
        subtopics: (json['subtopics'] as List<dynamic>? ?? [])
            .map((item) =>
                PreparationSubtopic.fromJson(item as Map<String, dynamic>))
            .toList(),
        resources: (json['resources'] as List<dynamic>? ?? [])
            .map((item) =>
                PreparationResource.fromJson(item as Map<String, dynamic>))
            .toList(),
        createdAt: json['createdAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'categoryId': category.id,
        'title': title,
        'introduction': introduction,
        'explanation': explanation,
        'codeExamples': codeExamples,
        'practicalExamples': practicalExamples,
        'referenceLinks': referenceLinks.join('\n'),
        'published': published,
        'subtopics': subtopics.map((item) => item.toJson()).toList(),
      };
}

class PreparationTopicPage {
  const PreparationTopicPage({
    required this.topics,
    required this.page,
    required this.totalPages,
    required this.totalElements,
  });

  final List<PreparationTopic> topics;
  final int page;
  final int totalPages;
  final int totalElements;
}

class PreparationApi {
  PreparationApi({http.Client? client})
      : _client = AuthenticatedHttpClient(client ?? http.Client());

  final http.Client _client;
  Uri get _base => Uri.parse(apiBaseUrl.replaceFirst(RegExp(r'/$'), ''));

  Uri _uri(String path, [Map<String, String>? query]) =>
      _base.replace(path: '${_base.path}$path', queryParameters: query);

  Future<List<PreparationCategory>> categories({bool admin = false}) async {
    final response = await _client.get(_uri(
      admin
          ? '/api/admin/preparation/categories'
          : '/api/preparation/categories',
    ));
    _check(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) =>
            PreparationCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PreparationTopicPage> topics({
    required bool admin,
    String? categorySlug,
    String? search,
    int page = 0,
  }) async {
    final query = <String, String>{'page': '$page', 'size': '50'};
    if (categorySlug != null && categorySlug.isNotEmpty) {
      query['category'] = categorySlug;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final path =
        admin ? '/api/admin/preparation/topics' : '/api/preparation/topics';
    final response = await _client.get(_uri(path, query));
    _check(response);
    final pageResult = jsonDecode(response.body) as Map<String, dynamic>;
    return PreparationTopicPage(
      topics: (pageResult['content'] as List<dynamic>)
          .map(
              (item) => PreparationTopic.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: pageResult['page'] as int? ?? page,
      totalPages: pageResult['totalPages'] as int? ?? 0,
      totalElements: pageResult['totalElements'] as int? ?? 0,
    );
  }

  Future<PreparationTopic> saveTopic(
    PreparationTopic topic, {
    int? id,
  }) async {
    final response = id == null
        ? await _client.post(
            _uri('/api/admin/preparation/topics'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(topic.toJson()),
          )
        : await _client.put(
            _uri('/api/admin/preparation/topics/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(topic.toJson()),
          );
    return PreparationTopic.fromJson(_decodeMap(response));
  }

  Future<PreparationCategory> saveCategory({
    int? id,
    required String name,
    String? description,
    required bool published,
  }) async {
    final body = jsonEncode({
      'name': name,
      'description': description,
      'published': published,
    });
    final response = id == null
        ? await _client.post(
            _uri('/api/admin/preparation/categories'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
        : await _client.put(
            _uri('/api/admin/preparation/categories/$id'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          );
    return PreparationCategory.fromJson(_decodeMap(response));
  }

  Future<void> setPublished(int id, bool published) async {
    final response = await _client.put(
      _uri('/api/admin/preparation/topics/$id/publication'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'published': published}),
    );
    _check(response);
  }

  Future<void> deleteTopic(int id) async {
    _check(await _client.delete(_uri('/api/admin/preparation/topics/$id')));
  }

  Future<void> deleteCategory(int id) async {
    _check(await _client.delete(_uri('/api/admin/preparation/categories/$id')));
  }

  Future<PreparationResource> uploadResource(
    int topicId,
    PlatformFile file, {
    required String kind,
  }) async {
    final bytes = file.bytes;
    if (bytes == null) throw Exception('Could not read the selected file.');
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/admin/preparation/topics/$topicId/resources', {
        'kind': kind,
      }),
    )
      ..headers.addAll({
        if (AuthSession.authorizationHeader != null)
          'Authorization': AuthSession.authorizationHeader!,
      })
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name),
      );
    final response = await http.Response.fromStream(await request.send());
    return PreparationResource.fromJson(_decodeMap(response));
  }

  Future<void> deleteResource(int topicId, int resourceId) async {
    _check(await _client.delete(
      _uri('/api/admin/preparation/topics/$topicId/resources/$resourceId'),
    ));
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
