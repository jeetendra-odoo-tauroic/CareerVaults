import 'package:careervault_app/api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps job API fields into a job model', () {
    final job = Job.fromJson({
      'id': 42,
      'title': 'Software Engineer',
      'organisation': 'Example Organisation',
      'category': 'Government IT',
      'experienceLevel': 'Entry level',
      'applicationStartDate': '2026-11-01',
      'closingDate': '2026-12-01',
      'status': 'PUBLISHED',
      'notificationFileName': 'notice.pdf',
    });

    expect(job.id, 42);
    expect(job.title, 'Software Engineer');
    expect(job.status, 'PUBLISHED');
    expect(job.notificationFileName, 'notice.pdf');
  });

  test('serializes the job fields expected by the API', () {
    final job = Job.fromJson({
      'id': 42,
      'title': 'Software Engineer',
      'organisation': 'Example Organisation',
      'category': 'Private IT',
      'experienceLevel': '3–5 years',
      'applicationStartDate': '2026-11-01',
      'closingDate': '2026-12-01',
      'status': 'DRAFT',
    });

    expect(job.toJson(), containsPair('title', 'Software Engineer'));
    expect(job.toJson(), containsPair('closingDate', '2026-12-01'));
    expect(job.toJson().containsKey('status'), isFalse);
  });
}
