import 'package:flutter/material.dart';

import 'api.dart';
import 'course_api.dart';
import 'guidance_api.dart';
import 'mock_tests_api.dart';

class CareerHomeScreen extends StatefulWidget {
  const CareerHomeScreen({
    super.key,
    required this.onNavigate,
    required this.onSearch,
    required this.onJobDetails,
    required this.onLogin,
    required this.onRegister,
  });

  final ValueChanged<int> onNavigate;
  final void Function(String query, int page) onSearch;
  final ValueChanged<Job> onJobDetails;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  State<CareerHomeScreen> createState() => _CareerHomeScreenState();
}

class _CareerHomeScreenState extends State<CareerHomeScreen> {
  final _jobsApi = JobApi();
  final _coursesApi = CourseApi();
  final _guidanceApi = GuidanceApi();
  final _testsApi = MockTestsApi();
  final _search = TextEditingController();
  String _searchCategory = 'Government jobs';
  bool _loading = true;
  final Map<String, String> _sectionMessages = {};
  List<Job> _governmentJobs = [];
  List<Job> _itJobs = [];
  List<Course> _courses = [];
  List<GuidanceArticle> _articles = [];
  List<MockTestSummary> _tests = [];
  MockTestSummary? _dailyQuiz;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _jobsApi.close();
    _coursesApi.close();
    _guidanceApi.close();
    _testsApi.close();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _sectionMessages.clear();
    setState(() => _loading = true);
    final results = await Future.wait([
      _loadSection('government',
          () => _jobsApi.publicJobs(section: 'GOVERNMENT'), <Job>[]),
      _loadSection('itJobs', () => _jobsApi.publicJobs(section: 'IT'), <Job>[]),
      _loadSection(
          'courses', () => _coursesApi.courses(admin: false), <Course>[]),
      _loadSection('guidance', () => _guidanceApi.articles(admin: false),
          <GuidanceArticle>[]),
      _loadSection(
          'tests', () => _testsApi.tests(admin: false), <MockTestSummary>[]),
      _loadSection<MockTestSummary?>(
          'dailyQuiz', () => _testsApi.latestDailyQuiz(), null),
    ]);
    if (!mounted) return;
    setState(() {
      _governmentJobs = results[0] as List<Job>;
      _itJobs = results[1] as List<Job>;
      _courses = results[2] as List<Course>;
      _articles = results[3] as List<GuidanceArticle>;
      _tests = results[4] as List<MockTestSummary>;
      _dailyQuiz = results[5] as MockTestSummary?;
      _loading = false;
    });
  }

  Future<T> _loadSection<T>(
      String section, Future<T> Function() load, T fallback) async {
    try {
      return await load();
    } catch (error) {
      _sectionMessages[section] =
          error.toString().replaceFirst('Exception: ', '');
      return fallback;
    }
  }

  Widget _sectionIssue(String section) {
    final message = _sectionMessages[section];
    if (message == null) return const SizedBox.shrink();
    final requiresLogin = message.contains('401') ||
        message.toLowerCase().contains('log in') ||
        message.toLowerCase().contains('login');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfffffbeb),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xfffde68a)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(requiresLogin
              ? 'Please log in to access this feature.'
              : 'This section could not be loaded: $message'),
          if (requiresLogin)
            TextButton(
              onPressed: widget.onLogin,
              child: const Text('Log in'),
            ),
          if (requiresLogin)
            TextButton(
              onPressed: widget.onRegister,
              child: const Text('Register'),
            ),
        ],
      ),
    );
  }

  void _searchJobs() {
    widget.onSearch(
        _search.text.trim(), _searchCategory == 'Government jobs' ? 5 : 6);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 600
        ? 18.0
        : width < 1000
            ? 32.0
            : 56.0;
    final contentWidth = width - horizontal * 2;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(horizontal, 26, horizontal, 44),
        children: [
          _hero(width),
          const SizedBox(height: 32),
          _sectionHeading(
            context,
            'Start with what you need',
            'Choose a path and take your next step.',
          ),
          const SizedBox(height: 16),
          _exploreGrid(contentWidth),
          const SizedBox(height: 34),
          _jobsSection(
            context,
            title: 'Latest Government Jobs',
            subtitle: 'New opportunities from public sector employers.',
            jobs: _governmentJobs,
            page: 5,
            government: true,
            width: contentWidth,
          ),
          const SizedBox(height: 30),
          _jobsSection(
            context,
            title: 'Latest IT Jobs',
            subtitle: 'Explore software, cloud and engineering roles.',
            jobs: _itJobs,
            page: 6,
            government: false,
            width: contentWidth,
          ),
          const SizedBox(height: 34),
          _learningSection(context, width),
          const SizedBox(height: 34),
          _coursesSection(context, contentWidth),
          const SizedBox(height: 34),
          _practiceSection(context, width),
          const SizedBox(height: 34),
          _guidanceSection(context, contentWidth),
          const SizedBox(height: 36),
          _footer(context),
        ],
      ),
    );
  }

  Widget _hero(double width) => Container(
        padding: EdgeInsets.all(width < 600 ? 22 : 38),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff102b5c), Color(0xff1d4ed8), Color(0xff4338a8)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff1e3a8a).withValues(alpha: .16),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final searchPanel = Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: compact
                  ? Column(
                      children: [
                        TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchJobs(),
                          decoration: const InputDecoration(
                            hintText: 'Search jobs by title or keyword',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            filled: false,
                          ),
                        ),
                        const Divider(height: 1),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _searchCategory,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Job type',
                                  border: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Government jobs', child: Text('Government jobs')),
                                  DropdownMenuItem(value: 'IT jobs', child: Text('Private IT jobs')),
                                ],
                                onChanged: (value) => setState(
                                  () => _searchCategory = value ?? _searchCategory,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _searchJobs,
                              child: const Text('Search'),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.search, color: Color(0xff64748b)),
                        ),
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: _search,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _searchJobs(),
                            decoration: const InputDecoration(
                              hintText: 'Job title, organisation or keyword',
                              border: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                        Container(width: 1, height: 38, color: const Color(0xffe2e8f0)),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: _searchCategory,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Search in',
                              border: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Government jobs', child: Text('Government jobs')),
                              DropdownMenuItem(value: 'IT jobs', child: Text('Private IT jobs')),
                            ],
                            onChanged: (value) => setState(
                              () => _searchCategory = value ?? _searchCategory,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _searchJobs,
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('Find jobs'),
                        ),
                      ],
                    ),
            );
            final intro = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: .22)),
                  ),
                  child: const Text(
                    'CAREERVAULT  •  JOBS & LEARNING',
                    style: TextStyle(
                      color: Colors.white,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Your next career move starts here.',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Discover government opportunities, grow your IT skills and prepare with practical resources—all in one place.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .86),
                    height: 1.55,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),
                searchPanel,
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: () => widget.onNavigate(5),
                      icon: const Icon(Icons.account_balance_outlined, size: 18),
                      label: const Text('Government jobs'),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: () => widget.onNavigate(6),
                      icon: const Icon(Icons.code, size: 18),
                      label: const Text('IT jobs'),
                    ),
                  ],
                ),
              ],
            );
            if (compact) return intro;
            return Row(
              children: [
                Expanded(flex: 7, child: intro),
                const SizedBox(width: 34),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withValues(alpha: .18)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.explore_outlined, color: Colors.white, size: 38),
                        SizedBox(height: 18),
                        Text(
                          'One place.\nMore possibilities.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 12),
                        _HeroBenefit(icon: Icons.work_outline, text: 'Find your next opportunity'),
                        SizedBox(height: 12),
                        _HeroBenefit(icon: Icons.school_outlined, text: 'Learn at your own pace'),
                        SizedBox(height: 12),
                        _HeroBenefit(icon: Icons.trending_up, text: 'Prepare for what’s next'),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

  Widget _sectionHeading(BuildContext context, String title, String subtitle) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xff64748b))),
        ],
      );

  Widget _exploreGrid(double width) {
    final cards = [
      _ExploreItem('Government Jobs', 'Find the latest public sector openings.',
          Icons.account_balance_outlined, 5, const Color(0xffeaf2ff)),
      _ExploreItem('Private IT Jobs', 'Explore technology roles and teams.',
          Icons.code, 6, const Color(0xffeef2ff)),
      _ExploreItem('IT Preparation', 'Build practical technical skills.',
          Icons.menu_book_outlined, 7, const Color(0xffecfdf5)),
      _ExploreItem('Online Classes', 'Learn with published courses.',
          Icons.school_outlined, 11, const Color(0xfffff7ed)),
      _ExploreItem('Mock Tests & Quizzes', 'Practice and review your results.',
          Icons.quiz_outlined, 13, const Color(0xfff5f3ff)),
      _ExploreItem('Career Guidance', 'Explore articles for your next step.',
          Icons.lightbulb_outline, 15, const Color(0xfffff1f2)),
    ];
    final columns = width >= 1150
        ? 3
        : width >= 760
            ? 2
            : 1;
    final cardWidth = (width - (columns - 1) * 14) / columns;
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final item in cards)
          SizedBox(
            width: cardWidth,
            child: _ExploreCard(
                item: item, onTap: () => widget.onNavigate(item.page)),
          ),
      ],
    );
  }

  Widget _jobsSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Job> jobs,
    required int page,
    required bool government,
    required double width,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionHeading(context, title, subtitle)),
            TextButton(
              onPressed: () => widget.onNavigate(page),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (!_loading) _sectionIssue(government ? 'government' : 'itJobs'),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (jobs.isEmpty)
          _emptyCard(
            government
                ? 'No published government jobs are available right now.'
                : 'No published IT jobs are available right now.',
          )
        else
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final job in jobs.take(width >= 1000 ? 3 : 2))
                SizedBox(
                  width: width >= 950 ? (width - 28) / 3 : width,
                  child: _JobPreviewCard(
                    job: job,
                    government: government,
                    onDetails: () => widget.onJobDetails(job),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _learningSection(BuildContext context, double width) {
    const topics = [
      ('Java Programming', Icons.coffee_outlined),
      ('Spring Boot', Icons.settings_suggest_outlined),
      ('Microservices', Icons.hub_outlined),
      ('Python', Icons.code),
      ('SQL & Database', Icons.storage_outlined),
      ('React', Icons.web_outlined),
      ('System Design', Icons.account_tree_outlined),
      ('DevOps & Cloud', Icons.cloud_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xfff8fbff), Color(0xfff1f5ff)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffdce7fb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            context,
            'Grow your technical skills',
            'Explore preparation topics and build confidence one step at a time.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final topic in topics)
                ActionChip(
                  avatar: Icon(topic.$2, size: 18, color: Color(0xff2563eb)),
                  label: Text(topic.$1,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xffdbeafe)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  onPressed: () => widget.onNavigate(7),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => widget.onNavigate(7),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Explore IT Preparation'),
          ),
        ],
      ),
    );
  }

  Widget _coursesSection(BuildContext context, double width) {
    final columns = width >= 1050
        ? 3
        : width >= 680
            ? 2
            : 1;
    final cardWidth = (width - 14 * (columns - 1)) / columns;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _sectionHeading(
                context,
                'Learn with Online Classes',
                'Discover courses published by CareerVault administrators.',
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigate(11),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (!_loading) _sectionIssue('courses'),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_courses.isEmpty)
          _emptyCard('No published courses are available right now.')
        else
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final course in _courses.take(3))
                SizedBox(
                  width: cardWidth,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xffeff6ff),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.menu_book_outlined,
                                color: Color(0xff2563eb)),
                          ),
                          const SizedBox(height: 12),
                          if (course.imageUri != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                course.imageUri.toString(),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(course.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(
                            course.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xff64748b)),
                          ),
                          const SizedBox(height: 12),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xffeff6ff),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              child: Text(
                                course.price > 0
                                    ? '₹${course.price.toStringAsFixed(2)}'
                                    : 'Free',
                                style: const TextStyle(
                                    color: Color(0xff1d4ed8),
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => widget.onNavigate(11),
                              child: const Text('View details'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _practiceSection(BuildContext context, double width) {
    final mockTests = _tests.where((test) => !test.dailyQuiz).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          context,
          'Practice at your pace',
          'Sharpen your skills with tests and quick daily quizzes.',
        ),
        const SizedBox(height: 14),
        if (!_loading) _sectionIssue('tests'),
        if (!_loading) _sectionIssue('dailyQuiz'),
        LayoutBuilder(builder: (context, constraints) {
          final cardWidth = constraints.maxWidth > 720
              ? (constraints.maxWidth - 14) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _PracticeCard(
                width: cardWidth,
                icon: Icons.fact_check_outlined,
                title: 'Practice Mock Tests',
                description: mockTests.isEmpty
                    ? 'Prepare with available practice tests and review your progress.'
                    : '${mockTests.length} published practice tests are available.',
                onTap: () => widget.onNavigate(13),
              ),
              _PracticeCard(
                width: cardWidth,
                icon: Icons.today_outlined,
                title: 'Daily Quizzes',
                description: _dailyQuiz?.title ??
                    'Try a quick quiz and keep your learning momentum going.',
                onTap: () => widget.onNavigate(13),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _guidanceSection(BuildContext context, double width) {
    final columns = width >= 1050
        ? 3
        : width >= 680
            ? 2
            : 1;
    final cardWidth = (width - 14 * (columns - 1)) / columns;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _sectionHeading(
                context,
                'Career Guidance',
                'Ideas and practical advice for your professional journey.',
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigate(15),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (!_loading) _sectionIssue('guidance'),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_articles.isEmpty)
          _emptyCard('No published career guidance articles are available yet.')
        else
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final article in _articles.take(3))
                SizedBox(
                  width: cardWidth,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (article.imageUrl?.isNotEmpty ?? false)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                article
                                    .imageUri(_guidanceApi.baseUrl)
                                    .toString(),
                                height: 130,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          Chip(
                            label: Text(article.categoryLabel),
                            backgroundColor: const Color(0xffeff6ff),
                            side: BorderSide.none,
                            labelStyle: const TextStyle(
                                color: Color(0xff1d4ed8),
                                fontWeight: FontWeight.w700),
                          ),
                          Text(article.title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800,
                                  height: 1.3)),
                          const SizedBox(height: 6),
                          Text(
                            article.shortDescription,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xff64748b)),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => widget.onNavigate(15),
                              child: const Text('Read more'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _footer(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xff172554),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 18,
          children: [
            const SizedBox(
              width: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CareerVault',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Your Career. Your Opportunities.',
                      style: TextStyle(color: Color(0xffcbd5e1))),
                  SizedBox(height: 12),
                  Text(
                    'Explore jobs, learning resources and career guidance in one place.',
                    style: TextStyle(color: Color(0xffcbd5e1)),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _footerLink('Home', 20),
                _footerLink('Government Jobs', 5),
                _footerLink('IT Jobs', 6),
                _footerLink('IT Preparation', 7),
                _footerLink('Online Classes', 11),
                _footerLink('Career Guidance', 15),
              ],
            ),
            const SizedBox(
              width: 260,
              child: Text(
                'About CareerVault\nCreated by Jeetendra Pal. Bringing 12 years of experience across MNCs and leading investment banks, with previous experience at SBI, to help people discover opportunities and take their next career step.',
                style: TextStyle(color: Color(0xffcbd5e1), height: 1.5),
              ),
            ),
          ],
        ),
      );

  Widget _footerLink(String label, int page) => TextButton(
        onPressed: () => widget.onNavigate(page),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      );

  Widget _emptyCard(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xfff8fafc),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffe2e8f0)),
        ),
        child: Text(message, style: const TextStyle(color: Color(0xff64748b))),
      );
}


class _HeroBenefit extends StatelessWidget {
  const _HeroBenefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: const Color(0xffbfdbfe), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      );
}

class _ExploreItem {
  const _ExploreItem(
      this.title, this.description, this.icon, this.page, this.color);

  final String title;
  final String description;
  final IconData icon;
  final int page;
  final Color color;
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.item, required this.onTap});

  final _ExploreItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.icon,
                      size: 25, color: const Color(0xff3730a3)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(item.description,
                          style: const TextStyle(
                              color: Color(0xff64748b), height: 1.45)),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Explore',
                              style: TextStyle(
                                  color: Color(0xff2563eb),
                                  fontWeight: FontWeight.w700)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded,
                              size: 16, color: Color(0xff2563eb)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _JobPreviewCard extends StatelessWidget {
  const _JobPreviewCard({
    required this.job,
    required this.government,
    required this.onDetails,
  });

  final Job job;
  final bool government;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xffdbeafe), Color(0xffeef2ff)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      government
                          ? Icons.account_balance_outlined
                          : Icons.business_center_outlined,
                      color: const Color(0xff1d4ed8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800,
                                height: 1.3)),
                        const SizedBox(height: 5),
                        Text(job.organisation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xff64748b), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xffedf0f5)),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  if (job.location?.isNotEmpty ?? false)
                    _JobMeta(Icons.location_on_outlined, job.location!),
                  if (government && (job.qualification?.isNotEmpty ?? false))
                    _JobMeta(Icons.school_outlined, job.qualification!),
                  if (!government && job.experienceLevel.isNotEmpty)
                    _JobMeta(Icons.work_history_outlined, job.experienceLevel),
                  if (!government && (job.salary?.isNotEmpty ?? false))
                    _JobMeta(Icons.payments_outlined, job.salary!),
                  _JobMeta(Icons.event_outlined, 'Closes ${job.closingDate}'),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('View details'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _JobMeta extends StatelessWidget {
  const _JobMeta(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xff64748b)),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(color: Color(0xff475569), fontSize: 12)),
        ],
      );
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28, color: const Color(0xff4f46e5)),
                const SizedBox(height: 10),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(description,
                    style: const TextStyle(color: Color(0xff64748b))),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onTap,
                  child: const Text('Start practicing'),
                ),
              ],
            ),
          ),
        ),
      );
}
