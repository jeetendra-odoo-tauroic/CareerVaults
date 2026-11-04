import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';

const governmentJobTypes = [
  'All government jobs',
  'Banking',
  'UPSC / SSC',
  'Railway',
  'PSU',
  'Central / State Government',
  'Government IT / Technical',
];

const privateJobTypes = [
  'All private IT jobs',
  'Java Developer',
  'Spring Boot Developer',
  'Python Developer',
  'Backend Developer',
  'Full Stack Developer',
  'React Developer',
  'DevOps Engineer',
  'Cloud Engineer',
  'Software Architect',
];

const privateExperienceLevels = [
  'All experience',
  'Fresher',
  '0–2 years',
  '2–5 years',
  '5–8 years',
  '8–12 years',
  '12+ years',
];

const _pageSize = 10;

List<Job> filterJobs(
  List<Job> jobs, {
  required bool government,
  String search = '',
  String organisation = '',
  String qualification = '',
  String category = '',
  String location = '',
  String applicationStatus = '',
  String experience = '',
  String salary = '',
  String workMode = '',
}) {
  final query = search.trim().toLowerCase();
  final filtered = jobs.where((job) {
    final governmentJob = _isGovernmentJob(job);
    if (governmentJob != government) return false;
    final searchable = [
      job.title,
      job.organisation,
      job.category,
      job.description ?? '',
      job.qualification ?? '',
    ].join(' ').toLowerCase();
    if (query.isNotEmpty && !searchable.contains(query)) return false;
    if (_matches(organisation, job.organisation)) return false;
    if (_matches(qualification, job.qualification ?? '')) return false;
    if (category.isNotEmpty &&
        category != 'All government jobs' &&
        category != 'All private IT jobs' &&
        !_matchesJobCategory(category, job)) {
      return false;
    }
    if (_matches(location, job.location ?? '')) return false;
    if (applicationStatus.isNotEmpty &&
        !_matchesApplicationStatus(applicationStatus, job.closingDate)) {
      return false;
    }
    if (!government &&
        experience.isNotEmpty &&
        experience != 'All experience') {
      final normalized = _normalizeExperience(job.experienceLevel);
      if (normalized != experience) return false;
    }
    if (!government && salary.isNotEmpty) {
      final hasSalary = job.salary?.trim().isNotEmpty == true;
      if (salary == 'Salary disclosed' && !hasSalary) return false;
      if (salary == 'Not disclosed' && hasSalary) return false;
    }
    if (!government && workMode.isNotEmpty) {
      final text =
          '${job.location ?? ''} ${job.description ?? ''}'.toLowerCase();
      if (!text.contains(workMode.toLowerCase())) return false;
    }
    return true;
  }).toList()
    ..sort((first, second) {
      final firstDate = DateTime.tryParse(first.createdAt ?? '');
      final secondDate = DateTime.tryParse(second.createdAt ?? '');
      if (firstDate == null && secondDate == null) {
        return second.id.compareTo(first.id);
      }
      if (firstDate == null) return 1;
      if (secondDate == null) return -1;
      return secondDate.compareTo(firstDate);
    });

  return filtered;
}

List<Job> filterAndPaginateJobs(
  List<Job> jobs, {
  required bool government,
  String search = '',
  String organisation = '',
  String qualification = '',
  String category = '',
  String location = '',
  String applicationStatus = '',
  String experience = '',
  String salary = '',
  String workMode = '',
  int page = 0,
}) {
  final filtered = filterJobs(
    jobs,
    government: government,
    search: search,
    organisation: organisation,
    qualification: qualification,
    category: category,
    location: location,
    applicationStatus: applicationStatus,
    experience: experience,
    salary: salary,
    workMode: workMode,
  );
  final start = page * _pageSize;
  if (start >= filtered.length || start < 0) return const [];
  final end = (start + _pageSize).clamp(0, filtered.length);
  return filtered.sublist(start, end);
}

int countFilteredJobs(
  List<Job> jobs, {
  required bool government,
  String search = '',
  String organisation = '',
  String qualification = '',
  String category = '',
  String location = '',
  String applicationStatus = '',
  String experience = '',
  String salary = '',
  String workMode = '',
}) =>
    filterJobs(
      jobs,
      government: government,
      search: search,
      organisation: organisation,
      qualification: qualification,
      category: category,
      location: location,
      applicationStatus: applicationStatus,
      experience: experience,
      salary: salary,
      workMode: workMode,
    ).length;

bool _matchesJobCategory(String selected, Job job) {
  final text =
      '${job.title} ${job.category} ${job.organisation} ${job.description ?? ''}'
          .toLowerCase();
  final keywords = switch (selected) {
    'Banking' => ['bank'],
    'UPSC / SSC' => ['upsc', 'ssc'],
    'Railway' => ['railway', 'rail'],
    'PSU' => ['psu', 'public sector'],
    'Central / State Government' => [
        'central government',
        'state government',
        'central govt',
        'state govt',
      ],
    'Government IT / Technical' => [
        'government it',
        'technical',
        'engineer',
        'developer',
        'software',
        'technology',
      ],
    _ => [selected.toLowerCase()],
  };
  return keywords.any(text.contains);
}

bool _isGovernmentJob(Job job) {
  final category = job.category.toLowerCase();
  return category.contains('government') ||
      category.contains('govt') ||
      category.contains('banking') ||
      category.contains('upsc') ||
      category.contains('ssc') ||
      category.contains('railway') ||
      category.contains('psu');
}

bool _matches(String selected, String value) =>
    selected.isNotEmpty && selected != 'All' && selected != value;

bool _matchesApplicationStatus(String selected, String closingDate) {
  final closing = DateTime.tryParse(closingDate);
  if (closing == null) return false;
  final daysRemaining = closing.difference(DateTime.now()).inDays;
  return switch (selected) {
    'Open' => !closing.isBefore(DateTime.now()),
    'Closing soon (7 days)' =>
      !closing.isBefore(DateTime.now()) && daysRemaining <= 7,
    _ => true,
  };
}

String _normalizeExperience(String experience) {
  final value = experience.trim().toLowerCase();
  if (value == 'entry level' || value == 'fresher') return 'Fresher';
  if (value == 'any' || value.isEmpty) return 'All experience';
  if (value == '1–3 years' || value == '0–2 years' || value == '0-2 years') {
    return '0–2 years';
  }
  if (value == '3–5 years' || value == '2–5 years' || value == '2-5 years') {
    return '2–5 years';
  }
  if (value == '5+ years' || value == '5–8 years' || value == '5-8 years') {
    return '5–8 years';
  }
  if (value == '8–12 years' || value == '8-12 years') return '8–12 years';
  if (value == '12+ years' || value == '12+ years') return '12+ years';
  return experience;
}

String postedDateLabel(String? value) {
  final posted = DateTime.tryParse(value ?? '');
  if (posted == null) return 'Date unavailable';
  final days = DateTime.now().difference(posted).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 30) return '$days days ago';
  return '${posted.year}-${posted.month.toString().padLeft(2, '0')}-${posted.day.toString().padLeft(2, '0')}';
}

class PublicJobsScreen extends StatefulWidget {
  const PublicJobsScreen({
    super.key,
    required this.api,
    required this.government,
    this.initialSearch = '',
  });

  final JobApi api;
  final bool government;
  final String initialSearch;

  @override
  State<PublicJobsScreen> createState() => _PublicJobsScreenState();
}

class _PublicJobsScreenState extends State<PublicJobsScreen> {
  final _searchController = TextEditingController();
  List<Job> _jobs = [];
  bool _loading = true;
  String? _error;
  String _organisation = '';
  String _qualification = '';
  String _category = '';
  String _location = '';
  String _applicationStatus = '';
  String _technology = '';
  String _experience = '';
  String _salary = '';
  String _workMode = '';
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearch;
    _loadJobs();
  }

  @override
  void didUpdateWidget(covariant PublicJobsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSearch != widget.initialSearch) {
      _searchController.text = widget.initialSearch;
      _page = 0;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _jobs = await widget.api.publicJobs(
        section: widget.government ? 'GOVERNMENT' : 'IT',
      );
      if (!widget.government) {
        _jobs = _jobs.where((job) => !_isGovernmentJob(job)).toList();
      } else {
        _jobs = _jobs.where(_isGovernmentJob).toList();
      }
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Job> get _filteredOnPage => filterAndPaginateJobs(
        _jobs,
        government: widget.government,
        search: _searchController.text,
        organisation: _organisation,
        qualification: _qualification,
        category: widget.government ? _category : _technology,
        location: _location,
        applicationStatus: _applicationStatus,
        experience: _experience,
        salary: _salary,
        workMode: _workMode,
        page: _page,
      );

  int get _filteredCount => countFilteredJobs(
        _jobs,
        government: widget.government,
        search: _searchController.text,
        organisation: _organisation,
        qualification: _qualification,
        category: widget.government ? _category : _technology,
        location: _location,
        applicationStatus: _applicationStatus,
        experience: _experience,
        salary: _salary,
        workMode: _workMode,
      );

  void _update(VoidCallback update) {
    setState(() {
      update();
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final government = widget.government;
    final title = government ? 'Government Jobs' : 'Private IT Jobs';
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1120 ? 2 : 1;
    final filteredCount = _filteredCount;
    final pageCount = (filteredCount / _pageSize).ceil();

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: width < 600 ? 16 : 32,
          vertical: 24,
        ),
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(width < 600 ? 22 : 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff102b5c), Color(0xff1d4ed8), Color(0xff3478e8)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: Color(0x1c1d4ed8), blurRadius: 24, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CAREERVAULT  /  OPPORTUNITIES',
                  style: TextStyle(color: Color(0xffbfdbfe), letterSpacing: 1.5,
                    fontWeight: FontWeight.w800, fontSize: 11)),
                const SizedBox(height: 12),
                Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white, fontSize: width < 600 ? 27 : 34)),
                const SizedBox(height: 8),
                Text(
                  government
                    ? 'Explore public-sector careers, recruitment notifications and important application dates.'
                    : 'Find your next opportunity across software engineering, Java, cloud, data and DevOps.',
                  style: const TextStyle(color: Color(0xffe0ecff), height: 1.5, fontSize: 14),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  const Icon(Icons.verified_outlined, color: Color(0xffbfdbfe), size: 18),
                  const SizedBox(width: 8),
                  Text('Curated opportunities • Updated listings',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.manage_search, color: Color(0xff1d4ed8)),
                    const SizedBox(width: 8),
                    Text('Find the right opportunity',
                      style: Theme.of(context).textTheme.titleMedium),
                  ]),
                  const SizedBox(height: 12),
                  Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => _update(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: government
                        ? 'Search job title or organisation'
                        : 'Search title, technology or skills',
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              _update(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Refresh jobs',
                onPressed: _loadJobs,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
                  const SizedBox(height: 12),
                  _filters(government),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _ErrorPanel(message: _error!, onRetry: _loadJobs)
          else if (filteredCount == 0)
            const _EmptyJobs()
          else ...[
            Row(
              children: [
                Expanded(child: Text('Available opportunities',
                  style: Theme.of(context).textTheme.titleLarge)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: const Color(0xffeaf2ff),
                    borderRadius: BorderRadius.circular(30)),
                  child: Text('$filteredCount found',
                    style: const TextStyle(color: Color(0xff1d4ed8), fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final gap = 12.0;
              final cardWidth =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final job in _filteredOnPage)
                    SizedBox(
                      width: cardWidth,
                      child: _PublicJobCard(
                        job: job,
                        onViewDetails: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => JobDetailsScreen(
                              api: widget.api,
                              job: job,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
            if (pageCount > 1) ...[
              const SizedBox(height: 16),
              _Pagination(
                page: _page,
                pageCount: pageCount,
                onPage: (page) => setState(() => _page = page),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _filters(bool government) {
    final organisations = _jobs
        .map((job) => job.organisation)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final qualifications = _jobs
        .map((job) => job.qualification ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final categories = (government
            ? governmentJobTypes.skip(1).toList()
            : privateJobTypes.skip(1).toList())
        .toList();
    final locations = _jobs
        .map((job) => job.location ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (!government) {
      final technologies = [
        'All technologies',
        ...categories,
      ];
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _filterDropdown(
            'Technology',
            _technology,
            technologies,
            (value) => _update(() => _technology = value),
          ),
          _filterDropdown(
            'Experience level',
            _experience,
            privateExperienceLevels,
            (value) => _update(() => _experience = value),
          ),
          _filterDropdown(
            'Salary',
            _salary,
            const ['Any salary', 'Salary disclosed', 'Not disclosed'],
            (value) => _update(() => _salary = value),
          ),
          _filterDropdown(
            'Location',
            _location,
            ['All locations', ...locations],
            (value) => _update(() => _location = value),
          ),
          _filterDropdown(
            'Work mode',
            _workMode,
            const ['Any work mode', 'Remote', 'Hybrid', 'Onsite'],
            (value) => _update(() => _workMode = value),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _filterDropdown(
          'Organisation',
          _organisation,
          ['All organisations', ...organisations],
          (value) => _update(() => _organisation = value),
        ),
        _filterDropdown(
          'Qualification',
          _qualification,
          ['All qualifications', ...qualifications],
          (value) => _update(() => _qualification = value),
        ),
        _filterDropdown(
          'Job category',
          _category,
          governmentJobTypes,
          (value) => _update(() => _category = value),
        ),
        _filterDropdown(
          'Location',
          _location,
          ['All locations', ...locations],
          (value) => _update(() => _location = value),
        ),
        _filterDropdown(
          'Application status',
          _applicationStatus,
          const ['Any status', 'Open', 'Closing soon (7 days)'],
          (value) => _update(() => _applicationStatus = value),
        ),
      ],
    );
  }

  Widget _filterDropdown(
    String label,
    String selected,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    final normalized = selected.isEmpty ? options.first : selected;
    final isExperience = label == 'Experience level';
    return SizedBox(
      width: 205,
      child: DropdownButtonFormField<String>(
        initialValue: options.contains(normalized) ? normalized : options.first,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: options
            .map((value) => DropdownMenuItem(
                  value: value,
                  child: Text(
                    isExperience ? value : _filterLabel(value),
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(_filterValue(value));
          }
        },
      ),
    );
  }
}

String _filterLabel(String value) {
  if (value.startsWith('All ')) return value;
  if (value == 'Any salary' ||
      value == 'Any work mode' ||
      value == 'Any status') {
    return value;
  }
  return value;
}

String _filterValue(String value) {
  if (value.startsWith('All ') || value.startsWith('Any ')) return '';
  return value;
}

class _PublicJobCard extends StatelessWidget {
  const _PublicJobCard({required this.job, required this.onViewDetails});

  final Job job;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 1,
        child: InkWell(
          onTap: onViewDetails,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xffedf4ff),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.account_balance_outlined,
                      color: Color(0xff1d4ed8), size: 23),
                  ),
                  const SizedBox(width: 13),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16, height: 1.35)),
                      const SizedBox(height: 4),
                      Text(job.organisation,
                        style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w600)),
                    ],
                  )),
                  const Icon(Icons.arrow_outward, color: Color(0xff94a3b8), size: 18),
                ]),
                const SizedBox(height: 17),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _CardDetail(Icons.location_on_outlined, job.location ?? 'Location not specified'),
                  _CardDetail(Icons.work_outline, job.experienceLevel),
                  if (job.salary?.isNotEmpty == true)
                    _CardDetail(Icons.payments_outlined, job.salary!),
                ]),
                const SizedBox(height: 17),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('APPLICATION DEADLINE',
                      style: TextStyle(fontSize: 9, letterSpacing: 1, color: Color(0xff94a3b8), fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(job.closingDate, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xff334155))),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('POSTED', style: TextStyle(fontSize: 9, letterSpacing: 1, color: Color(0xff94a3b8), fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(postedDateLabel(job.createdAt), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xff64748b))),
                  ]),
                ]),
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View opportunity'),
                  )),
              ],
            ),
          ),
        ),
      );
}

class _CardDetail extends StatelessWidget {
  const _CardDetail(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 5),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.pageCount,
    required this.onPage,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Previous page',
            onPressed: page > 0 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          for (var index = 0; index < pageCount; index++)
            if (pageCount <= 7 ||
                (index - page).abs() <= 2 ||
                index == 0 ||
                index == pageCount - 1)
              TextButton(
                onPressed: () => onPage(index),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: index == page ? FontWeight.bold : null,
                  ),
                ),
              )
            else if ((index - page).abs() == 3)
              const Text('…'),
          IconButton(
            tooltip: 'Next page',
            onPressed: page + 1 < pageCount ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      );
}

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 36),
              const SizedBox(height: 8),
              Text('No jobs match your search',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('Try changing the search or filters.'),
            ],
          ),
        ),
      );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.cloud_off_outlined),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}

class JobDetailsScreen extends StatelessWidget {
  const JobDetailsScreen({
    super.key,
    required this.api,
    required this.job,
    this.openLink,
  });

  final JobApi api;
  final Job job;
  final Future<bool> Function(Uri uri)? openLink;

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = openLink == null
        ? await launchUrl(uri, mode: LaunchMode.externalApplication)
        : await openLink!(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Job details')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(job.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 5),
            Text(job.organisation,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(job.category)),
                Chip(label: Text(job.experienceLevel)),
                Chip(label: Text(job.location ?? 'Location not specified')),
              ],
            ),
            const SizedBox(height: 12),
            _DetailSection(
              title: 'Organisation details',
              children: [
                _DetailRow('Organisation', job.organisation),
                if (job.advertisementNumber?.isNotEmpty == true)
                  _DetailRow('Advertisement number', job.advertisementNumber!),
                _DetailRow('Location', job.location ?? 'Not specified'),
              ],
            ),
            _DetailSection(
              title: 'Job description',
              children: [
                Text(job.description?.trim().isNotEmpty == true
                    ? job.description!
                    : 'No detailed description was provided by the organisation.'),
              ],
            ),
            _DetailSection(
              title: 'Eligibility and requirements',
              children: [
                _DetailRow(
                    'Qualification', job.qualification ?? 'Not specified'),
                _DetailRow('Experience', job.experienceLevel),
                _DetailRow('Required skills',
                    'See job description or official notification.'),
              ],
            ),
            _DetailSection(
              title: 'Compensation and important dates',
              children: [
                _DetailRow('Salary', job.salary ?? 'Not specified'),
                _DetailRow('Application starts', job.applicationStartDate),
                _DetailRow('Application closes', job.closingDate),
                _DetailRow('Posted', postedDateLabel(job.createdAt)),
              ],
            ),
            _DetailSection(
              title: 'Selection process',
              children: const [
                Text(
                    'See the official notification for selection process details.'),
              ],
            ),
            if (job.notificationFileName != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('Official notification PDF'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _open(context, api.notificationUri(job.id)),
                ),
              ),
            if (job.applicationUrl?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.icon(
                  onPressed: () =>
                      _open(context, Uri.parse(job.applicationUrl!)),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Apply on the official website'),
                ),
              ),
          ],
        ),
      );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child:
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
