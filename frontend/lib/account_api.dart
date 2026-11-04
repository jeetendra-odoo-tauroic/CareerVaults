import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart' show apiBaseUrl, AuthenticatedHttpClient, AuthSession;

class AccountUser {
  const AccountUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.active,
    required this.registeredAt,
    this.mobileNumber,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final bool active;
  final String registeredAt;
  final String? mobileNumber;

  factory AccountUser.fromJson(Map<String, dynamic> json) => AccountUser(
        id: json['id'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        mobileNumber: json['mobileNumber'] as String?,
        role: json['role'] as String? ?? 'STUDENT',
        active: json['active'] as bool? ?? true,
        registeredAt: json['registeredAt'] as String? ?? '',
      );
}

class WebsiteAccessSetting {
  const WebsiteAccessSetting({
    required this.key,
    required this.section,
    required this.mode,
    required this.effectiveMode,
    required this.overridden,
    required this.locked,
    this.feature,
  });

  final String key;
  final String section;
  final String? feature;
  final String mode;
  final String effectiveMode;
  final bool overridden;
  final bool locked;

  factory WebsiteAccessSetting.fromJson(Map<String, dynamic> json) =>
      WebsiteAccessSetting(
        key: json['key'] as String? ?? '',
        section: json['section'] as String? ?? '',
        feature: json['feature'] as String?,
        mode: json['mode'] as String? ?? 'PUBLIC',
        effectiveMode: json['effectiveMode'] as String? ?? 'PUBLIC',
        overridden: json['overridden'] as bool? ?? false,
        locked: json['locked'] as bool? ?? false,
      );
}

class AccountApi {
  AccountApi({http.Client? client})
      : _client = AuthenticatedHttpClient(client ?? http.Client());

  static const _tokenKey = 'careervault.auth.jwt';
  final http.Client _client;
  Uri get _base => Uri.parse(apiBaseUrl.replaceFirst(RegExp(r'/$'), ''));

  Future<AccountUser?> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;
    AuthSession.token = token;
    final response = await _client.get(_uri('/api/auth/me'));
    if (response.statusCode == 401) {
      await preferences.remove(_tokenKey);
      AuthSession.clear();
      return null;
    }
    final user = AccountUser.fromJson(_decodeMap(response));
    AuthSession.set(token, _toMap(user));
    return user;
  }

  Future<AccountUser> login(String email, String password) async {
    final response = await _client.post(
      _uri('/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    final json = _decodeMap(response);
    final token = json['token'] as String;
    final user = AccountUser.fromJson(json['user'] as Map<String, dynamic>);
    AuthSession.set(token, json['user'] as Map<String, dynamic>);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
    return user;
  }

  Future<AccountUser> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    AccountUser.fromJson(_decodeMap(await _client.post(
      _uri('/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'confirmPassword': confirmPassword,
      }),
    )));
    return login(email, password);
  }

  Future<AccountUser> profile() async => AccountUser.fromJson(
      _decodeMap(await _client.get(_uri('/api/account/profile'))));

  Future<AccountUser> updateProfile(String fullName, String? mobileNumber) async =>
      _updateProfile(fullName, mobileNumber);

  Future<AccountUser> _updateProfile(String fullName, String? mobileNumber) async {
    final updated = AccountUser.fromJson(_decodeMap(await _client.put(
        _uri('/api/account/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fullName': fullName, 'mobileNumber': mobileNumber}),
      )));
    AuthSession.profile = _toMap(updated);
    return updated;
  }

  Future<void> changePassword(
      String currentPassword, String newPassword, String confirmPassword) async {
    _check(await _client.post(
      _uri('/api/account/password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmPassword,
      }),
    ));
    AuthSession.clear();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
  }

  Future<void> logout() async {
    try {
      _check(await _client.post(_uri('/api/auth/logout')));
    } finally {
      AuthSession.clear();
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_tokenKey);
    }
  }

  Future<List<AccountUser>> users({String search = ''}) async {
    final uri = _uri('/api/admin/users',
        search.trim().isEmpty ? null : {'search': search.trim()});
    return _decodeList(await _client.get(uri))
        .map(AccountUser.fromJson)
        .toList();
  }

  Future<AccountUser> setActive(AccountUser user, bool active) async =>
      AccountUser.fromJson(_decodeMap(await _client.put(
        _uri('/api/admin/users/${user.id}/activation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'active': active}),
      )));

  Future<List<WebsiteAccessSetting>> accessSettings({bool admin = false}) async =>
      _decodeList(await _client.get(_uri(
          admin ? '/api/admin/access-settings' : '/api/access-settings')))
          .map(WebsiteAccessSetting.fromJson)
          .toList();

  Future<WebsiteAccessSetting> updateAccessSetting(String key, String mode) async =>
      WebsiteAccessSetting.fromJson(_decodeMap(await _client.put(
        _uri('/api/admin/access-settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': key, 'mode': mode}),
      )));

  Uri _uri(String path, [Map<String, String>? query]) =>
      _base.replace(path: '${_base.path}$path', queryParameters: query);

  List<Map<String, dynamic>> _decodeList(http.Response response) {
    _check(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
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

  Map<String, dynamic> _toMap(AccountUser user) => {
        'id': user.id,
        'fullName': user.fullName,
        'email': user.email,
        'mobileNumber': user.mobileNumber,
        'role': user.role,
        'active': user.active,
        'registeredAt': user.registeredAt,
      };

  void close() => _client.close();
}
