import 'package:flutter/material.dart';

import 'account_api.dart';

class AccountAccessForm extends StatefulWidget {
  const AccountAccessForm({
    super.key,
    required this.api,
    required this.register,
    required this.onSuccess,
  });

  final AccountApi api;
  final bool register;
  final ValueChanged<AccountUser> onSuccess;

  @override
  State<AccountAccessForm> createState() => _AccountAccessFormState();
}

class _AccountAccessFormState extends State<AccountAccessForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = widget.register
          ? await widget.api.register(
              fullName: _name.text.trim(),
              email: _email.text.trim(),
              password: _password.text,
              confirmPassword: _confirm.text,
            )
          : await widget.api.login(_email.text.trim(), _password.text);
      if (mounted) widget.onSuccess(user);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(widget.register ? 'Create your CareerVault account' : 'Log in',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text('Student accounts are created with the STUDENT role.'),
                    if (widget.register) ...[
                      const SizedBox(height: 16),
                      _input(_name, 'Full name'),
                    ],
                    const SizedBox(height: 16),
                    _input(_email, 'Email address', email: true),
                    const SizedBox(height: 16),
                    _input(_password, 'Password', secret: true),
                    if (widget.register) ...[
                      const SizedBox(height: 16),
                      _input(_confirm, 'Confirm password', secret: true),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.register ? 'Register' : 'Log in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _input(TextEditingController controller, String label,
          {bool email = false, bool secret = false}) =>
      TextFormField(
        controller: controller,
        obscureText: secret,
        keyboardType: email ? TextInputType.emailAddress : null,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Required.';
          if (email && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
            return 'Enter a valid email address.';
          }
          if (secret && value.length < 8) return 'Use at least 8 characters.';
          if (label == 'Confirm password' && value != _password.text) {
            return 'Passwords do not match.';
          }
          return null;
        },
      );
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.api, required this.onLogout});

  final AccountApi api;
  final VoidCallback onLogout;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  AccountUser? _user;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await widget.api.profile();
      if (mounted) setState(() => _user = user);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final user = _user;
    if (user == null) return;
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (context) => _EditProfileDialog(user: user),
    );
    if (result == null) return;
    try {
      final updated = await widget.api.updateProfile(result.$1, result.$2);
      if (mounted) setState(() => _user = updated);
    } catch (error) {
      if (mounted) _message(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _changePassword() async {
    final values = await showDialog<(String, String, String)>(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
    if (values == null) return;
    try {
      await widget.api.changePassword(values.$1, values.$2, values.$3);
      if (mounted) {
        _message('Password changed. Please log in again.');
        widget.onLogout();
      }
    } catch (error) {
      if (mounted) _message(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _logout() async {
    try {
      await widget.api.logout();
      if (mounted) widget.onLogout();
    } catch (error) {
      if (mounted) _message(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    final user = _user!;
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
        vertical: 24,
      ),
      children: [
        Text('My Account', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _profileRow('Full Name', user.fullName),
                _profileRow('Email Address', user.email),
                _profileRow('Mobile Number', user.mobileNumber ?? 'Not provided'),
                _profileRow('Account Role', user.role),
                _profileRow('Registration Date', _date(user.registeredAt)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _edit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit profile'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _changePassword,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Change password'),
                    ),
                    TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.sizeOf(context).width < 600 ? 118 : 170,
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectableText(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      );
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.user});
  final AccountUser user;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _mobile = TextEditingController(text: widget.user.mobileNumber);

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Edit profile'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 12),
              TextFormField(controller: _mobile, decoration: const InputDecoration(labelText: 'Mobile number')),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.user.email,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Email address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: _name.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, (_name.text.trim(), _mobile.text.trim())),
            child: const Text('Save'),
          ),
        ],
      );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Change password'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _passwordField(_current, 'Current password'),
              const SizedBox(height: 12),
              _passwordField(_new, 'New password'),
              const SizedBox(height: 12),
              _passwordField(_confirm, 'Confirm new password'),
              if (_error != null) Text(_error!),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (_new.text.length < 8) {
                setState(() => _error = 'Use at least 8 characters.');
              } else if (_new.text != _confirm.text) {
                setState(() => _error = 'New passwords do not match.');
              } else {
                Navigator.pop(context, (_current.text, _new.text, _confirm.text));
              }
            },
            child: const Text('Change password'),
          ),
        ],
      );

  Widget _passwordField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(labelText: label),
      );
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, required this.api});
  final AccountApi api;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _search = TextEditingController();
  List<AccountUser> _users = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await widget.api.users(search: _search.text);
      if (mounted) setState(() => _users = users);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(AccountUser user) async {
    try {
      await widget.api.setActive(user, !user.active);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(user.active ? 'Account deactivated.' : 'Account activated.'),
        ));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Registered Users', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          decoration: InputDecoration(
            labelText: 'Search name or email',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.arrow_forward)),
          ),
          onSubmitted: (_) => _load(),
        ),
        if (_error != null) Padding(
          padding: const EdgeInsets.all(12),
          child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
        const SizedBox(height: 12),
        if (_users.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No registered users found.')),
          ),
        for (final user in _users)
          Card(
            child: ListTile(
              title: Text(user.fullName),
              subtitle: Text('${user.email} · ${user.role} · Registered ${_date(user.registeredAt)}'),
              trailing: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(label: Text(user.active ? 'Active' : 'Inactive')),
                  TextButton(
                    onPressed: () => _toggle(user),
                    child: Text(user.active ? 'Deactivate' : 'Activate'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class AccessSettingsScreen extends StatefulWidget {
  const AccessSettingsScreen({super.key, required this.api});
  final AccountApi api;

  @override
  State<AccessSettingsScreen> createState() => _AccessSettingsScreenState();
}

class _AccessSettingsScreenState extends State<AccessSettingsScreen> {
  List<WebsiteAccessSetting> _settings = [];
  final Map<String, String> _changed = {};
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settings = await widget.api.accessSettings(admin: true);
      if (mounted) setState(() => _settings = settings);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(WebsiteAccessSetting setting) async {
    final mode = _changed[setting.key] ?? setting.effectiveMode;
    try {
      await widget.api.updateAccessSetting(setting.key, mode);
      _changed.remove(setting.key);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Website access setting saved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    final sections = <String, List<WebsiteAccessSetting>>{};
    for (final setting in _settings) {
      sections.putIfAbsent(setting.section, () => []).add(setting);
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Website Access Settings',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Feature settings override their section default. Account profiles and personal results always require login.'),
        const SizedBox(height: 16),
        for (final entry in sections.entries) ...[
          Text(entry.key, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final setting in entry.value) _settingRow(setting),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _settingRow(WebsiteAccessSetting setting) {
    final selected = _changed[setting.key] ?? setting.effectiveMode;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(setting.feature ?? setting.section),
                  Text(
                    setting.locked
                        ? 'Always login required'
                        : 'Current access: ${setting.effectiveMode}${setting.overridden ? ' (feature override)' : ' (section default)'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            DropdownButton<String>(
              value: selected,
              onChanged: setting.locked
                  ? null
                  : (value) => setState(() => _changed[setting.key] = value!),
              items: const [
                DropdownMenuItem(value: 'PUBLIC', child: Text('PUBLIC')),
                DropdownMenuItem(
                    value: 'LOGIN_REQUIRED', child: Text('LOGIN_REQUIRED')),
              ],
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: setting.locked || !_changed.containsKey(setting.key)
                  ? null
                  : () => _save(setting),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

String _date(String value) => value.length < 10 ? '—' : value.substring(0, 10);
