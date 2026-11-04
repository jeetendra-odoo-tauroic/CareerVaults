import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart' show apiBaseUrl, AuthenticatedHttpClient;

const interviewExperienceLevels = [
  'Fresher',
  '0–2 years',
  '2–5 years',
  '5–8 years',
  '8–12 years',
  '12+ years',
];

class InterviewCategory {
  const InterviewCategory({
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

  factory InterviewCategory.fromJson(Map<String, dynamic> json) =>
      InterviewCategory(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        description: json['description'] as String?,
        published: json['published'] as bool? ?? false,
      );
}

class InterviewTopic {
  const InterviewTopic({
    required this.id,
    required this.category,
    required this.title,
    required this.slug,
    required this.introduction,
    required this.article,
    required this.experienceLevels,
    required this.published,
    this.createdAt,
  });

  final int id;
  final InterviewCategory category;
  final String title;
  final String slug;
  final String introduction;
  final String article;
  final List<String> experienceLevels;
  final bool published;
  final String? createdAt;

  factory InterviewTopic.fromJson(Map<String, dynamic> json) => InterviewTopic(
        id: json['id'] as int,
        category: InterviewCategory.fromJson(
          json['category'] as Map<String, dynamic>,
        ),
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        introduction: json['introduction'] as String? ?? '',
        article: json['article'] as String? ?? '',
        experienceLevels: (json['experienceLevels'] as List<dynamic>? ?? [])
            .whereType<String>()
            .toList(),
        published: json['published'] as bool? ?? false,
        createdAt: json['createdAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'categoryId': category.id,
        'title': title,
        'introduction': introduction,
        'article': article,
        'experienceLevels': experienceLevels,
        'published': published,
      };
}

class InterviewTopicPage {
  const InterviewTopicPage({
    required this.topics,
    required this.page,
    required this.totalPages,
    required this.totalElements,
  });

  final List<InterviewTopic> topics;
  final int page;
  final int totalPages;
  final int totalElements;
}

class InterviewApi {
  InterviewApi({http.Client? client})
      : _client = AuthenticatedHttpClient(client ?? http.Client());

  final http.Client _client;
  Uri get _base => Uri.parse(apiBaseUrl.replaceFirst(RegExp(r'/$'), ''));

  Uri _uri(String path, [Map<String, String>? query]) =>
      _base.replace(path: '${_base.path}$path', queryParameters: query);

  Future<List<InterviewCategory>> categories({bool admin = false}) async {
    final response = await _client.get(_uri(
      admin ? '/api/admin/interviews/categories' : '/api/interviews/categories',
    ));
    _check(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => InterviewCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<InterviewTopicPage> topics({
    required bool admin,
    String? categorySlug,
    int? categoryId,
    String? search,
    String? experienceLevel,
    int page = 0,
  }) async {
    final query = <String, String>{'page': '$page', 'size': '10'};
    if (categorySlug != null && categorySlug.isNotEmpty) {
      query['category'] = categorySlug;
    }
    if (categoryId != null) {
      query['categoryId'] = '$categoryId';
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (experienceLevel != null && experienceLevel.isNotEmpty) {
      query['experienceLevel'] = experienceLevel;
    }
    final response = await _client.get(_uri(
      admin ? '/api/admin/interviews/topics' : '/api/interviews/topics',
      query,
    ));
    _check(response);
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    return InterviewTopicPage(
      topics: (result['content'] as List<dynamic>)
          .map((item) => InterviewTopic.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: result['page'] as int? ?? page,
      totalPages: result['totalPages'] as int? ?? 0,
      totalElements: result['totalElements'] as int? ?? 0,
    );
  }

  Future<InterviewTopic> saveTopic(
    InterviewTopic topic, {
    int? id,
  }) async {
    final response = id == null
        ? await _client.post(
            _uri('/api/admin/interviews/topics'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(topic.toJson()),
          )
        : await _client.put(
            _uri('/api/admin/interviews/topics/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(topic.toJson()),
          );
    return InterviewTopic.fromJson(_decodeMap(response));
  }

  Future<InterviewCategory> saveCategory({
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
            _uri('/api/admin/interviews/categories'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
        : await _client.put(
            _uri('/api/admin/interviews/categories/$id'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          );
    return InterviewCategory.fromJson(_decodeMap(response));
  }

  Future<void> setPublished(int id, bool published) async {
    _check(await _client.put(
      _uri('/api/admin/interviews/topics/$id/publication'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'published': published}),
    ));
  }

  Future<void> deleteTopic(int id) async {
    _check(await _client.delete(_uri('/api/admin/interviews/topics/$id')));
  }

  Future<void> deleteCategory(int id) async {
    _check(await _client.delete(_uri('/api/admin/interviews/categories/$id')));
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
