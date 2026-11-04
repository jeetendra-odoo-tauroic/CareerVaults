import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'api.dart' show apiBaseUrl, AuthenticatedHttpClient, AuthSession;

class Course {
  const Course({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.status,
    this.imageUrl,
    this.createdAt,
  });

  final int id;
  final String name;
  final String category;
  final String description;
  final double price;
  final String status;
  final String? imageUrl;
  final String? createdAt;

  bool get published => status == 'PUBLISHED';

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        description: json['description'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'UNPUBLISHED',
        imageUrl: json['imageUrl'] as String?,
        createdAt: json['createdAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'description': description,
        'price': price,
        'status': status,
      };

  Uri? get imageUri {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    final base = Uri.parse(apiBaseUrl.replaceFirst(RegExp(r'/$'), ''));
    return base.replace(path: '${base.path}$imageUrl');
  }
}

class CourseApi {
  CourseApi({http.Client? client})
      : _client = AuthenticatedHttpClient(client ?? http.Client());

  final http.Client _client;
  Uri get _base => Uri.parse(apiBaseUrl.replaceFirst(RegExp(r'/$'), ''));

  Uri _uri(String path) => _base.replace(path: '${_base.path}$path');

  Future<List<Course>> courses({required bool admin}) async {
    final response = await _client.get(
      _uri(admin ? '/api/admin/courses' : '/api/courses'),
    );
    _check(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Course.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Course> course(int id) async {
    final response = await _client.get(_uri('/api/courses/$id'));
    return Course.fromJson(_decodeMap(response));
  }

  Future<Course> saveCourse(
    Map<String, dynamic> values, {
    int? id,
  }) async {
    final response = id == null
        ? await _client.post(
            _uri('/api/admin/courses'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(values),
          )
        : await _client.put(
            _uri('/api/admin/courses/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(values),
          );
    return Course.fromJson(_decodeMap(response));
  }

  Future<Course> uploadImage(int id, PlatformFile image) async {
    final bytes = image.bytes;
    if (bytes == null) throw Exception('Could not read the selected image.');
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/admin/courses/$id/image'),
    )
      ..headers.addAll({
        if (AuthSession.authorizationHeader != null)
          'Authorization': AuthSession.authorizationHeader!,
      })..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: image.name),
      );
    return Course.fromJson(_decodeMap(
      await http.Response.fromStream(await request.send()),
    ));
  }

  Future<void> setStatus(int id, String status) async {
    _check(await _client.put(
      _uri('/api/admin/courses/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    ));
  }

  Future<void> deleteCourse(int id) async {
    _check(await _client.delete(_uri('/api/admin/courses/$id')));
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
