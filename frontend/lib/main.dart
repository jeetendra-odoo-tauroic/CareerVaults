import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'account_api.dart';
import 'account_screen.dart';
import 'career_home_screen.dart';
import 'course_screen.dart';
import 'guidance_screen.dart';
import 'interview_screen.dart';
import 'mock_tests_screen.dart';
import 'preparation_screen.dart';
import 'public_jobs_screen.dart';

void main() => runApp(const CareerVaultApp());

class CareerVaultApp extends StatelessWidget {
  const CareerVaultApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CareerVault',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff2563eb),
            primary: const Color(0xff1d4ed8),
            secondary: const Color(0xff2563eb),
            surface: const Color(0xffffffff),
            error: const Color(0xffb91c1c),
          ),
          scaffoldBackgroundColor: const Color(0xfff5f7fb),
          useMaterial3: true,
          visualDensity: VisualDensity.standard,
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              color: Color(0xff0f172a), fontWeight: FontWeight.w800,
              letterSpacing: -1.1, height: 1.15,
            ),
            headlineMedium: TextStyle(
              color: Color(0xff0f172a), fontWeight: FontWeight.w800,
              letterSpacing: -0.7, height: 1.2,
            ),
            headlineSmall: TextStyle(
              color: Color(0xff172554), fontWeight: FontWeight.w700,
              letterSpacing: -0.35,
            ),
            titleLarge: TextStyle(
              color: Color(0xff172554), fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
            titleMedium: TextStyle(
              color: Color(0xff1e293b), fontWeight: FontWeight.w700,
            ),
            bodyLarge: TextStyle(color: Color(0xff334155), height: 1.55),
            bodyMedium: TextStyle(color: Color(0xff475569), height: 1.5),
            bodySmall: TextStyle(color: Color(0xff64748b), height: 1.45),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 1,
            shadowColor: const Color(0x120f172a),
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xffe6ebf3)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xff172554),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: Color(0x120f172a),
            titleTextStyle: TextStyle(
              color: Color(0xff172554), fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15, vertical: 15,
            ),
            hintStyle: const TextStyle(color: Color(0xff94a3b8)),
            labelStyle: const TextStyle(
              color: Color(0xff475569), fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffdbe3ef)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffdbe3ef)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xff2563eb), width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffb91c1c)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffb91c1c), width: 1.6),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff2563eb),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xffe2e8f0),
              disabledForegroundColor: const Color(0xff94a3b8),
              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xff1d4ed8),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
              side: const BorderSide(color: Color(0xffcbd8ec)),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xff1d4ed8),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xffeff6ff),
            selectedColor: const Color(0xffdbeafe),
            disabledColor: const Color(0xfff1f5f9),
            labelStyle: const TextStyle(
              color: Color(0xff1e40af), fontWeight: FontWeight.w600,
            ),
            side: const BorderSide(color: Color(0xffdbeafe)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titleTextStyle: const TextStyle(
              color: Color(0xff172554), fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xffe8edf5), thickness: 1, space: 1,
          ),
        ),
        home: const CareerVaultHome(),
      );
}

class CareerVaultHome extends StatefulWidget {
  const CareerVaultHome({super.key});

  @override
  State<CareerVaultHome> createState() => _CareerVaultHomeState();
}

class _CareerVaultHomeState extends State<CareerVaultHome> {
  final _api = JobApi();
  final _accountApi = AccountApi();
  int _page = 20;
  bool _publicMode = true;
  bool _loading = true;
  String? _error;
  List<Job> _jobs = [];
  String _pendingJobSearch = '';

  @override
  void initState() {
    super.initState();
    _restoreAccount();
    _loadJobs();
  }

  @override
  void dispose() {
    _api.close();
    _accountApi.close();
    super.dispose();
  }

  Future<void> _restoreAccount() async {
    try {
      await _accountApi.restoreSession();
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _loadJobs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final jobs =
          _publicMode ? await _api.publicJobs() : await _api.adminJobs();
      if (mounted) setState(() => _jobs = jobs);
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _runAction(
      Future<void> Function() action, String success) async {
    try {
      await action();
      await _loadJobs();
      if (mounted) _notify(success);
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _selectPage(int index) {
    setState(() {
      _page = index;
      if (index != 5 && index != 6) _pendingJobSearch = '';
      _publicMode = (index >= 5 && index <= 7) ||
          index == 9 ||
          index == 11 ||
          index == 13 ||
          index == 15 ||
          index == 20;
    });
    Navigator.of(context).maybePop();
    if (index < 5) _loadJobs();
  }

  Future<void> _openAuth({required bool register}) async {
    final user = await showDialog<AccountUser>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AccountAccessForm(
            api: _accountApi,
            register: register,
            onSuccess: (account) => Navigator.of(dialogContext).pop(account),
          ),
        ),
      ),
    );
    if (user == null || !mounted) return;
    setState(() {});
    _selectPage(user.role == 'ADMIN' ? 0 : 5);
  }

  Future<void> _logout() async {
    try {
      await _accountApi.logout();
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {});
        _selectPage(5);
      }
    }
  }

  void _onSignedOut() {
    if (!mounted) return;
    setState(() {});
    _selectPage(5);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    final content = _buildPage();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: InkWell(
          onTap: () => _selectPage(20),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.work_history_outlined, color: Color(0xff2563eb)),
              SizedBox(width: 9),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CareerVault',
                    style: TextStyle(
                      color: Color(0xff172554),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text('Your Career. Your Opportunities.',
                      style: TextStyle(fontSize: 10, color: Color(0xff64748b))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (AuthSession.signedIn) ...[
            if (AuthSession.isAdmin)
              PopupMenuButton<int>(
                tooltip: 'Admin dashboard',
                icon: const Icon(Icons.admin_panel_settings_outlined),
                onSelected: _selectPage,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 0, child: Text('Admin Dashboard')),
                  PopupMenuItem(value: 1, child: Text('Manage jobs')),
                  PopupMenuItem(value: 2, child: Text('Add job')),
                  PopupMenuItem(value: 3, child: Text('Upload Excel')),
                  PopupMenuItem(value: 4, child: Text('Upload PDF')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 8, child: Text('Manage IT Preparation')),
                  PopupMenuItem(
                      value: 10, child: Text('Manage Interview content')),
                  PopupMenuItem(value: 12, child: Text('Manage courses')),
                  PopupMenuItem(value: 14, child: Text('Manage tests')),
                  PopupMenuItem(
                      value: 16, child: Text('Manage Career Guidance')),
                  PopupMenuItem(value: 18, child: Text('Registered users')),
                  PopupMenuItem(
                      value: 19, child: Text('Website Access Settings')),
                ],
              ),
            IconButton(
              tooltip: 'My Account',
              onPressed: () => _selectPage(17),
              icon: const Icon(Icons.account_circle_outlined),
            ),
            IconButton(
              tooltip: 'Logout',
              onPressed: _logout,
              icon: const Icon(Icons.logout),
            ),
          ] else if (compact)
            PopupMenuButton<bool>(
              tooltip: 'Log in or register',
              icon: const Icon(Icons.person_outline),
              onSelected: (register) => _openAuth(register: register),
              itemBuilder: (context) => const [
                PopupMenuItem(value: false, child: Text('Log in')),
                PopupMenuItem(value: true, child: Text('Register')),
              ],
            )
          else ...[
            TextButton.icon(
              onPressed: () => _openAuth(register: false),
              icon: const Icon(Icons.login),
              label: const Text('Log in'),
            ),
            FilledButton.tonal(
              onPressed: () => _openAuth(register: true),
              child: const Text('Register'),
            ),
          ],
          const SizedBox(width: 14),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _topNavigation(),
        ),
      ),
      body: content,
    );
  }

  Widget _topNavigation() {
    const destinations = <(String, IconData, int)>[
      ('Home', Icons.home_outlined, 20),
      ('Government Jobs', Icons.account_balance_outlined, 5),
      ('IT Jobs', Icons.code_outlined, 6),
      ('IT Preparation', Icons.menu_book_outlined, 7),
      ('Interview Preparation', Icons.record_voice_over_outlined, 9),
      ('Online Classes', Icons.school_outlined, 11),
      ('Mock Tests & Quizzes', Icons.quiz_outlined, 13),
      ('Career Guidance', Icons.lightbulb_outline, 15),
    ];
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xfff8fafc),
        border: Border(top: BorderSide(color: Color(0xffe2e8f0))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final destination in destinations)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TextButton.icon(
                onPressed: () => _selectPage(destination.$3),
                icon: Icon(destination.$2,
                    size: 18,
                    color: _page == destination.$3
                        ? const Color(0xff1d4ed8)
                        : const Color(0xff64748b)),
                label: Text(
                  destination.$1,
                  style: TextStyle(
                    color: _page == destination.$3
                        ? const Color(0xff1e40af)
                        : const Color(0xff334155),
                    fontWeight: _page == destination.$3
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    if (_page == 20) {
      return CareerHomeScreen(
        onNavigate: _selectPage,
        onSearch: (query, page) {
          setState(() => _pendingJobSearch = query);
          _selectPage(page);
        },
        onJobDetails: (job) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => JobDetailsScreen(api: _api, job: job),
            ),
          );
        },
        onLogin: () => _openAuth(register: false),
        onRegister: () => _openAuth(register: true),
      );
    }
    if (_page == 17) {
      return AccountScreen(api: _accountApi, onLogout: _onSignedOut);
    }
    if (_page == 18 && AuthSession.isAdmin) {
      return AdminUsersScreen(api: _accountApi);
    }
    if (_page == 19 && AuthSession.isAdmin) {
      return AccessSettingsScreen(api: _accountApi);
    }
    if (_publicMode) {
      if (_page == 7) {
        return const PreparationScreen(admin: false);
      }
      if (_page == 9) return const InterviewScreen(admin: false);
      if (_page == 11) return const CourseScreen(admin: false);
      if (_page == 13) {
        return MockTestsScreen(
          admin: false,
          onLogin: () => _openAuth(register: false),
          onRegister: () => _openAuth(register: true),
        );
      }
      if (_page == 15) return const CareerGuidanceScreen(admin: false);
      return PublicJobsScreen(
        key: ValueKey(_page),
        api: _api,
        government: _page == 5,
        initialSearch: _pendingJobSearch,
      );
    }
    if (_page == 8) return const PreparationScreen(admin: true);
    if (_page == 10) return const InterviewScreen(admin: true);
    if (_page == 12) return const CourseScreen(admin: true);
    if (_page == 14) return const MockTestsScreen(admin: true);
    if (_page == 16) return const CareerGuidanceScreen(admin: true);
    if (_error != null && _page < 5) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 40),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadJobs,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check that the API is running and API_BASE_URL points to a reachable address.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_loading && _page < 5) {
      return const Center(child: CircularProgressIndicator());
    }
    final page = switch (_page) {
      0 => _dashboard(),
      1 => _manageJobs(),
      2 => JobFormScreen(
          onSave: (values) async {
            await _api.saveJob(values);
            if (mounted) {
              _notify('Job saved as draft.');
              _selectPage(1);
            }
          },
        ),
      3 => BulkUploadScreen(
          onImport: _api.uploadJobs,
          onTemplate: () => launchUrl(_api.templateUri(),
              mode: LaunchMode.externalApplication),
          onComplete: (message) async {
            await _loadJobs();
            if (mounted) _notify(message);
          },
        ),
      4 => PdfUploadScreen(
          jobs: _jobs,
          onUpload: _api.uploadNotification,
          onComplete: () async {
            await _loadJobs();
            if (mounted) _notify('Notification PDF uploaded.');
          },
        ),
      18 when AuthSession.isAdmin => AdminUsersScreen(api: _accountApi),
      19 when AuthSession.isAdmin => AccessSettingsScreen(api: _accountApi),
      _ => _dashboard(),
    };
    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: page,
    );
  }

  Widget _dashboard() {
    final drafts = _jobs.where((job) => job.status == 'DRAFT').length;
    final published = _jobs.where((job) => job.status == 'PUBLISHED').length;
    final expired = _jobs.where((job) => job.status == 'EXPIRED').length;
    return _PageContent(
      title: 'Good morning, Admin',
      subtitle: 'Here’s what’s happening with your job listings.',
      action: FilledButton.icon(
        onPressed: () => _selectPage(2),
        icon: const Icon(Icons.add),
        label: const Text('Add job'),
      ),
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth > 900
              ? 4
              : constraints.maxWidth > 500
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                  'Total listings', _jobs.length, Icons.work_outline, width),
              _StatCard(
                  'Published', published, Icons.check_circle_outline, width),
              _StatCard('Drafts', drafts, Icons.edit_note, width),
              _StatCard('Expired', expired, Icons.event_busy_outlined, width),
            ],
          );
        }),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
                child: Text('Latest jobs',
                    style: Theme.of(context).textTheme.titleLarge)),
            TextButton(
                onPressed: () => _selectPage(1),
                child: const Text('Manage all')),
          ],
        ),
        const SizedBox(height: 8),
        if (_jobs.isEmpty)
          const _EmptyState('No jobs yet. Add a listing to get started.')
        else
          for (final job in _jobs.take(5)) _JobCard(job: job),
      ],
    );
  }

  Widget _manageJobs() => _PageContent(
        title: 'Manage jobs',
        subtitle: 'Review, edit and manage all your job listings.',
        action: FilledButton.icon(
          onPressed: () => _selectPage(2),
          icon: const Icon(Icons.add),
          label: const Text('Add job'),
        ),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final status in ['All', 'DRAFT', 'PUBLISHED', 'EXPIRED'])
                ChoiceChip(
                  label:
                      Text(status == 'All' ? 'All jobs' : _statusLabel(status)),
                  selected: _statusFilter == status,
                  onSelected: (_) => setState(() => _statusFilter = status),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: _categoryFilter,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const ['All', 'Government IT', 'Private IT', 'Other']
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _categoryFilter = value ?? 'All'),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: _experienceFilter,
                  decoration: const InputDecoration(labelText: 'Experience'),
                  items: const [
                    'All',
                    'Entry level',
                    '1–3 years',
                    '3–5 years',
                    '5+ years',
                    'Any'
                  ]
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _experienceFilter = value ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_visibleJobs.isEmpty)
            const _EmptyState('No jobs in this category.')
          else
            for (final job in _visibleJobs)
              _JobCard(
                job: job,
                onEdit: () => _selectEdit(job),
                onPublish: () => _runAction(
                  () => _api.setStatus(job.id, 'PUBLISHED'),
                  'Job published.',
                ),
                onUnpublish: () => _runAction(
                  () => _api.setStatus(job.id, 'DRAFT'),
                  'Job moved to drafts.',
                ),
                onDelete: () => _confirmDelete(job),
              ),
        ],
      );

  String _statusFilter = 'All';
  String _categoryFilter = 'All';
  String _experienceFilter = 'All';
  List<Job> get _visibleJobs => _jobs.where((job) {
        final matchesStatus =
            _statusFilter == 'All' || job.status == _statusFilter;
        final matchesCategory =
            _categoryFilter == 'All' || job.category == _categoryFilter;
        final matchesExperience = _experienceFilter == 'All' ||
            job.experienceLevel == _experienceFilter;
        return matchesStatus && matchesCategory && matchesExperience;
      }).toList();

  void _selectEdit(Job job) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Edit job')),
          body: JobFormScreen(
            job: job,
            onSave: (values) async {
              await _api.saveJob(values, id: job.id);
              if (mounted) {
                Navigator.of(context).pop();
                _loadJobs();
                _notify('Job updated.');
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Job job) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete job?'),
        content: Text('Delete "${job.title}" at ${job.organisation}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (shouldDelete == true) {
      await _runAction(() => _api.deleteJob(job.id), 'Job deleted.');
    }
  }
}

String _statusLabel(String status) =>
    '${status[0]}${status.substring(1).toLowerCase()}';

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.title,
    required this.subtitle,
    required this.children,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.count, this.icon, this.width);
  final String label;
  final int count;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Text('$count',
                    style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ),
        ),
      );
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    this.onEdit,
    this.onPublish,
    this.onUnpublish,
    this.onDelete,
  });

  final Job job;
  final VoidCallback? onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onUnpublish;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 3),
                        Text(
                            '${job.organisation} · ${job.location ?? 'Location not specified'}'),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(_statusLabel(job.status)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _InfoChip(job.category),
                  _InfoChip(job.experienceLevel),
                  _InfoChip('Closes ${job.closingDate}'),
                  if (job.advertisementNumber?.isNotEmpty == true)
                    _InfoChip(job.advertisementNumber!),
                ],
              ),
              if (onEdit != null ||
                  onPublish != null ||
                  onUnpublish != null ||
                  onDelete != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 4,
                    children: [
                      if (onEdit != null)
                        IconButton(
                            tooltip: 'Edit',
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined)),
                      if (onPublish != null)
                        IconButton(
                            tooltip: 'Publish',
                            onPressed: onPublish,
                            icon: const Icon(Icons.publish)),
                      if (onUnpublish != null)
                        IconButton(
                            tooltip: 'Unpublish',
                            onPressed: onUnpublish,
                            icon: const Icon(Icons.unpublished_outlined)),
                      if (onDelete != null)
                        IconButton(
                            tooltip: 'Delete',
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Center(child: Text(message)),
        ),
      );
}

class JobFormScreen extends StatefulWidget {
  const JobFormScreen({super.key, required this.onSave, this.job});
  final Job? job;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  String _category = 'Government IT';
  String _experience = 'Entry level';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    _category = job?.category ?? _category;
    _experience = job?.experienceLevel ?? _experience;
    final initial = <String, String>{
      'title': job?.title ?? '',
      'organisation': job?.organisation ?? '',
      'advertisementNumber': job?.advertisementNumber ?? '',
      'qualification': job?.qualification ?? '',
      'salary': job?.salary ?? '',
      'location': job?.location ?? '',
      'applicationStartDate': job?.applicationStartDate ?? '',
      'closingDate': job?.closingDate ?? '',
      'description': job?.description ?? '',
      'applicationUrl': job?.applicationUrl ?? '',
    };
    for (final entry in initial.entries) {
      _controllers[entry.key] = TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(String key) async {
    final current = DateTime.tryParse(_controllers[key]!.text);
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      _controllers[key]!.text =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final start = _controllers['applicationStartDate']!.text;
    final close = _controllers['closingDate']!.text;
    if (start.compareTo(close) > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Start date must be on or before closing date.')),
      );
      return;
    }
    setState(() => _saving = true);
    final values = <String, dynamic>{
      for (final entry in _controllers.entries)
        entry.key:
            entry.value.text.trim().isEmpty ? null : entry.value.text.trim(),
      'category': _category,
      'experienceLevel': _experience,
    };
    try {
      await widget.onSave(values);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String key, String label,
      {bool required = false, int lines = 1, bool date = false}) {
    return TextFormField(
      controller: _controllers[key],
      readOnly: date,
      onTap: date ? () => _pickDate(key) : null,
      maxLines: lines,
      keyboardType:
          key == 'applicationUrl' ? TextInputType.url : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: date ? const Icon(Icons.calendar_today_outlined) : null,
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '$label is required.';
        }
        if (date &&
            value != null &&
            value.isNotEmpty &&
            DateTime.tryParse(value) == null) {
          return 'Select a valid date.';
        }
        if (key == 'applicationUrl' && value != null && value.isNotEmpty) {
          final uri = Uri.tryParse(value);
          if (uri == null ||
              !uri.hasScheme ||
              !['https', 'http'].contains(uri.scheme)) {
            return 'Enter a valid HTTP or HTTPS URL.';
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(widget.job == null ? 'Add a job' : 'Edit job',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('New listings are saved as drafts.'),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    LayoutBuilder(builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 600;
                      final fieldWidth = wide
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                              width: fieldWidth,
                              child:
                                  _field('title', 'Job title', required: true)),
                          SizedBox(
                              width: fieldWidth,
                              child: _field('organisation', 'Organisation',
                                  required: true)),
                          SizedBox(
                              width: fieldWidth,
                              child: _field('advertisementNumber',
                                  'Advertisement number')),
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: const InputDecoration(
                                  labelText: 'Job category'),
                              items: const [
                                'Government IT',
                                'Private IT',
                                'Other'
                              ]
                                  .map((value) => DropdownMenuItem(
                                      value: value, child: Text(value)))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _category = value!),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: _experience,
                              decoration: const InputDecoration(
                                  labelText: 'Experience level'),
                              items: const [
                                'Entry level',
                                '1–3 years',
                                '3–5 years',
                                '5+ years',
                                'Any'
                              ]
                                  .map((value) => DropdownMenuItem(
                                      value: value, child: Text(value)))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _experience = value!),
                            ),
                          ),
                          SizedBox(
                              width: fieldWidth,
                              child: _field('qualification', 'Qualification')),
                          SizedBox(
                              width: fieldWidth,
                              child: _field('salary', 'Salary / pay scale')),
                          SizedBox(
                              width: fieldWidth,
                              child: _field('location', 'Location')),
                          SizedBox(
                              width: fieldWidth,
                              child: _field('applicationStartDate',
                                  'Application start date',
                                  required: true, date: true)),
                          SizedBox(
                              width: fieldWidth,
                              child: _field(
                                  'closingDate', 'Application closing date',
                                  required: true, date: true)),
                          SizedBox(
                              width: constraints.maxWidth,
                              child: _field('applicationUrl',
                                  'Official application URL')),
                          SizedBox(
                              width: constraints.maxWidth,
                              child: _field('description', 'Job description',
                                  lines: 4)),
                        ],
                      );
                    }),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_outlined),
                        label: Text(widget.job == null
                            ? 'Save as draft'
                            : 'Save changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({
    super.key,
    required this.onImport,
    required this.onTemplate,
    required this.onComplete,
  });
  final Future<Map<String, dynamic>> Function(PlatformFile) onImport;
  final Future<bool> Function() onTemplate;
  final Future<void> Function(String) onComplete;

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  PlatformFile? _file;
  bool _busy = false;
  String? _result;
  List<dynamic> _rowErrors = [];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (result != null && mounted) setState(() => _file = result.files.single);
  }

  Future<void> _upload() async {
    if (_file == null) return;
    setState(() => _busy = true);
    try {
      final response = await widget.onImport(_file!);
      final imported = response['imported'] ?? 0;
      final duplicates = response['duplicates'] ?? 0;
      _rowErrors = response['errors'] as List<dynamic>? ?? [];
      _result =
          'Imported $imported jobs · $duplicates duplicate(s) skipped · ${_rowErrors.length} row error(s).';
      await widget.onComplete(_result!);
    } catch (error) {
      _result = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _PageContent(
        title: 'Upload job listings',
        subtitle: 'Import multiple jobs from a CSV or Excel spreadsheet.',
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.table_view_outlined, size: 32),
                  const SizedBox(height: 12),
                  Text('Import from file',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  const Text(
                      'Use the CSV template. Dates must use YYYY-MM-DD. Imported jobs start as drafts.'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: widget.onTemplate,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Download CSV template'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(_file?.name ?? 'Choose CSV or XLSX file'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _file == null || _busy ? null : _upload,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload_file),
                    label: const Text('Import jobs'),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 14),
                    Text(_result!),
                    for (final error in _rowErrors.take(20)) Text('• $error'),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
}

class PdfUploadScreen extends StatefulWidget {
  const PdfUploadScreen({
    super.key,
    required this.jobs,
    required this.onUpload,
    required this.onComplete,
  });
  final List<Job> jobs;
  final Future<Job> Function(int, PlatformFile) onUpload;
  final Future<void> Function() onComplete;

  @override
  State<PdfUploadScreen> createState() => _PdfUploadScreenState();
}

class _PdfUploadScreenState extends State<PdfUploadScreen> {
  int? _jobId;
  PlatformFile? _file;
  bool _busy = false;
  String? _error;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && mounted) setState(() => _file = result.files.single);
  }

  Future<void> _upload() async {
    if (_jobId == null || _file == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onUpload(_jobId!, _file!);
      if (mounted) setState(() => _file = null);
      await widget.onComplete();
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _PageContent(
        title: 'Upload notification PDF',
        subtitle: 'Attach an official notification to an existing job.',
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<int>(
                      initialValue: _jobId,
                      decoration:
                          const InputDecoration(labelText: 'Job listing'),
                      items: widget.jobs
                          .map((job) => DropdownMenuItem(
                                value: job.id,
                                child: Text(
                                    '${job.title} — ${job.organisation}',
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _jobId = value),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(_file?.name ?? 'Choose PDF (max 10 MB)'),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _jobId == null || _file == null || _busy
                        ? null
                        : _upload,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload),
                    label: const Text('Upload PDF'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
}
