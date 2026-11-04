import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'api.dart' show apiBaseUrl, AuthenticatedHttpClient, AuthSession;

class GuidanceCategory {
  const GuidanceCategory({required this.code, required this.label});

  final String code;
  final String label;

  factory GuidanceCategory.fromJson(Map<String, dynamic> json) =>
      GuidanceCategory(
        code: json['code'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );
}

class GuidanceArticle {
  const GuidanceArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryLabel,
    required this.shortDescription,
    this.content,
    this.imageUrl,
    this.status = 'PUBLISHED',
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String category;
  final String categoryLabel;
  final String shortDescription;
  final String? content;
  final String? imageUrl;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  bool get published => status == 'PUBLISHED';

  factory GuidanceArticle.fromJson(Map<String, dynamic> json) =>
      GuidanceArticle(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? '',
        categoryLabel: json['categoryLabel'] as String? ?? '',
        shortDescription: json['shortDescription'] as String? ?? '',
        content: json['content'] as String?,
        imageUrl: json['imageUrl'] as String?,
        status: json['status'] as String? ?? 'PUBLISHED',
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );

  Uri? imageUri(String baseUrl) {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    final base = Uri.parse(baseUrl.replaceFirst(RegExp(r'/$'), ''));
    return base.replace(path: '${base.path}$imageUrl');
  }
}

class GuidanceApi {
  GuidanceApi({http.Client? client})
      : _client = AuthenticatedHttpClient(client ?? http.Client());

  final http.Client _client;
  String? get _token => AuthSession.token;

  String get baseUrl => apiBaseUrl;
  Map<String, String> get adminHeaders => _headers();
  Uri get _base => Uri.parse(apiBaseUrl.replaceFirst(RegExp(r'/$'), ''));

  Uri _uri(String path, [Map<String, String>? query]) =>
      _base.replace(path: '${_base.path}$path', queryParameters: query);

  Map<String, String> _headers({bool json = false}) => {
        if (json) 'Content-Type': 'application/json',
        if ((_token ?? AuthSession.token)?.isNotEmpty ?? false)
          'Authorization': 'Bearer ${_token ?? AuthSession.token}',
      };

  Future<List<GuidanceCategory>> categories() async {
    final response = await _client.get(_uri('/api/guidance/categories'));
    _check(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => GuidanceCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<GuidanceArticle>> articles({
    required bool admin,
    String? category,
    String? search,
  }) async {
    final query = <String, String>{};
    if (!admin && category != null && category.isNotEmpty) {
      query['category'] = category;
    }
    if (!admin && search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final response = await _client.get(
      _uri(admin ? '/api/admin/guidance' : '/api/guidance', query),
      headers: _headers(),
    );
    _check(response);
    final decoded = jsonDecode(response.body);
    final data = admin
        ? decoded as List<dynamic>
        : (decoded['articles'] as List<dynamic>);
    return data
        .map((item) => GuidanceArticle.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<GuidanceArticle> article(int id, {required bool admin}) async {
    final path = admin ? '/api/admin/guidance/$id' : '/api/guidance/$id';
    final response = await _client.get(_uri(path), headers: _headers());
    return GuidanceArticle.fromJson(_decodeMap(response));
  }

  Future<GuidanceArticle> saveArticle(
    Map<String, dynamic> data, {
    int? id,
  }) async {
    final response = id == null
        ? await _client.post(
            _uri('/api/admin/guidance'),
            headers: _headers(json: true),
            body: jsonEncode(data),
          )
        : await _client.put(
            _uri('/api/admin/guidance/$id'),
            headers: _headers(json: true),
            body: jsonEncode(data),
          );
    return GuidanceArticle.fromJson(_decodeMap(response));
  }

  Future<GuidanceArticle> uploadImage(int id, PlatformFile image) async {
    final bytes = image.bytes;
    if (bytes == null) throw Exception('Could not read the selected image.');
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/admin/guidance/$id/image'),
    )
      ..headers.addAll(_headers())
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: image.name),
      );
    return GuidanceArticle.fromJson(_decodeMap(
      await http.Response.fromStream(await request.send()),
    ));
  }

  Future<void> setStatus(int id, String status) async {
    _check(await _client.put(
      _uri('/api/admin/guidance/$id/status'),
      headers: _headers(json: true),
      body: jsonEncode({'status': status}),
    ));
  }

  Future<void> deleteArticle(int id) async {
    _check(await _client.delete(
      _uri('/api/admin/guidance/$id'),
      headers: _headers(),
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
