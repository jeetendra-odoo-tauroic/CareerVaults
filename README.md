# CareerVault Jobs

CareerVault Jobs is a single-service job management application: a Java 21 / Spring Boot REST API built with Maven, Spring Data JPA and an H2 file database, plus one Flutter (Dart) application for browsers, Android and iOS.

## Run locally

Requirements: Java 21, Maven 3.9+, Flutter SDK (with Dart), and the platform toolchains for Android/iOS builds.

### Start the backend

```powershell
mvn spring-boot:run
```

The API starts at `http://localhost:8080`. Keep this terminal open while using the app. To stop the API, press **Ctrl+C** in this terminal.

### Start the Flutter web app

Open a second PowerShell terminal:

```powershell
Set-Location frontend
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5173 --dart-define=API_BASE_URL=http://localhost:8080
```

Open `http://localhost:5173` in a browser. Keep this terminal open too; stop the Flutter web server with **Ctrl+C**. For a development browser that Flutter launches automatically, replace `-d web-server --web-hostname 127.0.0.1 --web-port 5173` with `-d chrome`.

### Start in the background (PowerShell)

From the project root, run `mvn spring-boot:run` and `flutter run` in separate terminals as above, or use `Start-Process` to keep each process separate. Save the process IDs it prints so you can stop only these application processes:

```powershell
$backend = Start-Process mvn -ArgumentList 'spring-boot:run' -PassThru
$backend.Id

Set-Location frontend
$web = Start-Process flutter -ArgumentList 'run -d web-server --web-hostname 127.0.0.1 --web-port 5173 --dart-define=API_BASE_URL=http://localhost:8080' -PassThru
$web.Id
```

Stop the background processes using the IDs printed above:

```powershell
Stop-Process -Id <backend-process-id>
Stop-Process -Id <web-process-id>
```

For normal development, the foreground-terminal method is recommended because **Ctrl+C** shuts down the server cleanly.

To run on a physical Android or iOS device, set `API_BASE_URL` to an HTTPS address reachable from the device, for example `--dart-define=API_BASE_URL=https://api.example.com`. Do not use `localhost` on a physical phone: it points back to the phone itself. Flutter web uses the same base URL; configure `CAREERVAULT_CORS_ALLOWED_ORIGINS` on the API for the browser app's deployed origin.

Build browser or Android output with `flutter build web` or `flutter build apk`. For iOS, run `flutter build ios` on macOS with Xcode installed.

Run backend tests with `mvn test` and Flutter tests with `cd frontend; flutter test`.

The H2 database is stored under `data/careervault`; uploaded notification PDFs are stored under `uploads`. Both paths are relative to the API's working directory.

## Features

- Add, edit, delete, publish and unpublish job listings from the admin dashboard.
- Upload official PDF notifications (PDF, max 10 MB).
- Bulk-import CSV or `.xlsx` files. Use **Upload Excel → Download CSV template** for the required header row. Dates must use `YYYY-MM-DD`; imported listings are drafts.
- Filter public listings by category and experience. Public listings are ordered newest first.
- Published listings whose closing date has passed are marked expired hourly and before public listings are returned.
- Duplicate submissions are rejected using organisation, title and advertisement number (case-insensitive).
- Manage Java and Python preparation categories, lesson articles, subtopics, examples, references, and learning resources in the dashboard. The initial Java/Python topic catalogue is seeded as drafts; public pages show only published topics.
- Browse published preparation lessons in the responsive Flutter web/mobile app, with category navigation, title/introduction search, pagination, and SEO-style category/topic URLs.
- Preparation images and PDF, TXT, or Markdown resources are validated and stored under `uploads/preparation` (15 MB maximum per upload).
- Browse a separate Private IT Interview Preparation catalogue covering Java, Spring, Python, databases, DevOps/cloud, frontend and architecture. Interview topic articles can be drafted, organised by experience level and published; this phase does not include interview questions or answers.
- Add and manage online courses with a course name, category, description, price, optional image and published/unpublished status. Public listings and details show published courses only; course images are limited to PNG, JPEG or WebP (5 MB maximum).
- Create government and IT mock tests or daily quizzes with four-option questions, backend-only answer keys, per-question marks, optional negative marking and an optional passing threshold. Authenticated users can take tests, receive automatically evaluated results and review their own attempt history.
- Create and manage career guidance articles across nine fixed categories, including optional images. Public listings, category/title search and article details show published articles only; management requires an ADMIN account.
- Register student accounts, view and update one's own profile, change passwords, and manage account activation as an administrator. Roles are limited to ADMIN and STUDENT.
- Configure public or login-required access for job listings/details, preparation, courses, tests, quizzes and guidance. Access settings persist in H2 and are enforced by the API on every request.

## API

- `GET /api/jobs?category=&experienceLevel=` — published jobs for the public site.
- `GET /api/admin/jobs?status=DRAFT|PUBLISHED|EXPIRED` — list admin jobs.
- `POST /api/admin/jobs`, `PUT /api/admin/jobs/{id}`, `DELETE /api/admin/jobs/{id}` — manage jobs.
- `PUT /api/admin/jobs/{id}/status` with `{"status":"PUBLISHED"}` or `{"status":"DRAFT"}` — publish / unpublish.
- `POST /api/admin/jobs/{id}/notification` — multipart field `file`.
- `GET /api/jobs/{id}/notification` — retrieve the uploaded notification.
- `POST /api/admin/jobs/import` — multipart field `file` containing a CSV or `.xlsx`.
- `GET /api/admin/jobs/template.csv` — download the import template.
- `GET /api/preparation/categories` and `GET /api/preparation/topics?category=&search=&page=&size=` — published learning categories and paginated lessons.
- `GET /api/preparation/categories/{categorySlug}/topics/{topicSlug}` — published lesson detail and its public resources.
- `GET /api/admin/preparation/categories` and `POST|PUT|DELETE /api/admin/preparation/categories/{id}` — manage learning categories (`POST` omits `{id}`).
- `GET /api/admin/preparation/topics?search=&page=&size=` — list draft and published lessons.
- `GET /api/admin/preparation/topics/{id}`, `POST /api/admin/preparation/topics`, `PUT|DELETE /api/admin/preparation/topics/{id}` — manage lesson articles, including subtopics and examples (`POST` omits `{id}`).
- `PUT /api/admin/preparation/topics/{id}/publication` with `{"published":true}` — publish or unpublish a lesson.
- `POST /api/admin/preparation/topics/{id}/resources` — multipart field `file`, optional `kind=IMAGE|RESOURCE`; `DELETE /api/admin/preparation/topics/{id}/resources/{resourceId}` removes a resource.
- `GET /api/preparation/resources/{id}` — retrieve a resource only when its lesson and category are published.
- `GET /api/interviews/categories` and `GET /api/interviews/topics?category=&search=&experienceLevel=&page=&size=` — published interview categories and paginated article topics.
- `GET /api/interviews/categories/{categorySlug}/topics/{topicSlug}` — public article detail using category/topic slugs.
- `GET /api/admin/interviews/categories` and `POST|PUT|DELETE /api/admin/interviews/categories/{id}` — interview category management (`POST` omits `{id}`).
- `GET /api/admin/interviews/topics?categoryId=&search=&experienceLevel=&page=&size=` — search draft and published interview topics.
- `GET /api/admin/interviews/topics/{id}`, `POST /api/admin/interviews/topics`, `PUT|DELETE /api/admin/interviews/topics/{id}` — manage interview preparation articles (`POST` omits `{id}`).
- `PUT /api/admin/interviews/topics/{id}/publication` with `{"published":true}` — publish or unpublish an interview article.
- `GET /api/courses` and `GET /api/courses/{id}` — list and view published courses.
- `GET /api/admin/courses` and `GET /api/admin/courses/{id}` — list and view all courses in the admin catalogue.
- `POST /api/admin/courses` and `PUT /api/admin/courses/{id}` — create or update a course using `name`, `category`, `description`, `price` and `status` (`PUBLISHED` or `UNPUBLISHED`).
- `PUT /api/admin/courses/{id}/status` with `{"status":"PUBLISHED"}` or `{"status":"UNPUBLISHED"}`, and `DELETE /api/admin/courses/{id}` — update publication status or delete a course.
- `POST /api/admin/courses/{id}/image` — multipart field `file` for an optional PNG, JPEG or WebP course image (5 MB maximum); `GET /api/courses/{id}/image` serves images only for published courses, while `GET /api/admin/courses/{id}/image` also serves unpublished-course images to the admin UI.
- `GET /api/test-categories` — available government and IT categories.
- `GET /api/tests`, `GET /api/daily-quiz` — published tests and the latest published daily quiz. Question answer keys are never included in these responses.
- `POST /api/tests/{id}/attempts` with a JWT bearer token — start an authenticated attempt. Returns question text/options only, with no correct answers or marks.
- `POST /api/test-attempts/{attemptId}/submit` with a JWT bearer token and `{"answers":{"<questionId>":0}}` — submit zero-based option selections; the server evaluates and returns marks, pass status and question-wise review. Attempts belong to the authenticated user and repeated submissions cannot create a second result.
- `GET /api/test-attempts/history` and `GET /api/test-attempts/{attemptId}` with a JWT bearer token — retrieve only the authenticated user's results.
- `GET /api/admin/tests`, `GET /api/admin/tests/{id}`, `POST /api/admin/tests`, `PUT /api/admin/tests/{id}`, `DELETE /api/admin/tests/{id}` — manage test metadata (`title`, `description`, `category`, `kind`, `durationMinutes`, `negativeMarking`, optional `passingPercentage`, and `status`).
- `PUT /api/admin/tests/{id}/status` with `{"status":"PUBLISHED"}` or `{"status":"DRAFT"}` — change publication status; a test needs at least one question before it can be published.
- `POST /api/admin/tests/{id}/questions`, `PUT /api/admin/tests/{id}/questions/{questionId}`, `DELETE /api/admin/tests/{id}/questions/{questionId}` — manage four-option questions, correct answer, marks and optional explanation.
- `GET /api/guidance/categories`, `GET /api/guidance?category=&search=`, `GET /api/guidance/{id}` — list categories, search/filter published articles and view published article details.
- `GET /api/guidance/{id}/image` — retrieve an image only when its article is published.
- `GET|POST /api/admin/guidance`, `GET|PUT|DELETE /api/admin/guidance/{id}` — list, create, retrieve, update or delete guidance articles.
- `PUT /api/admin/guidance/{id}/status` with `{"status":"PUBLISHED"}` or `{"status":"UNPUBLISHED"}` — change article visibility.
- `POST /api/admin/guidance/{id}/image` — multipart field `file` for an optional PNG, JPEG or WebP image (5 MB maximum); `GET /api/admin/guidance/{id}/image` serves images to authenticated admins, including unpublished articles.

### Accounts and access control

The public registration endpoint always creates a STUDENT; it does not accept a role. Passwords are stored as BCrypt hashes. Configure an initial administrator using `CAREERVAULT_BOOTSTRAP_ADMIN_EMAIL` and `CAREERVAULT_BOOTSTRAP_ADMIN_PASSWORD` (at least 12 characters). The bootstrap only creates the account if the email does not already exist; it never promotes an existing account. For production, set `CAREERVAULT_JWT_SECRET` to a stable, private value of at least 32 characters. The development fallback must not be used in production. JWTs expire after 12 hours; logout, password changes and deactivation invalidate existing tokens.

Account APIs: `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/me`, `POST /api/auth/logout`, `GET|PUT /api/account/profile`, and `POST /api/account/password`. Admin-only user management uses `GET /api/admin/users?search=` and `PUT /api/admin/users/{id}/activation` with `{"active":true|false}`. The final active ADMIN cannot be deactivated.

`GET /api/access-settings` returns the effective access configuration. ADMIN users can view/update settings with `GET|PUT /api/admin/access-settings`; update payloads contain a setting `key` and `mode` (`PUBLIC` or `LOGIN_REQUIRED`). Feature overrides supersede their section defaults. Settings are persisted in the existing H2 database and take effect immediately. Personal profiles and personal results/history remain login-required and cannot be made public. All `/api/admin/**` endpoints require ADMIN access.

Configure `CAREERVAULT_CORS_ALLOWED_ORIGINS` to a comma-separated allowlist of browser origins in production. Learning resource files are stored beneath `CAREERVAULT_PREPARATION_RESOURCE_DIR` (default `./uploads/preparation`).

Course images are stored beneath `CAREERVAULT_COURSE_IMAGE_DIR` (default `./uploads/courses`). The public course Contact button opens the device's email composer with the course name in the subject; no CareerVault recipient address is configured by default.

Career guidance images are stored beneath `CAREERVAULT_GUIDANCE_IMAGE_DIR` (default `./uploads/guidance`).

Existing guest-era mock-test attempt rows are retained in H2 but are not attached to an account or included in a student's history. The `owner_id` column is added by Hibernate schema update; no database reset is required.
