import 'package:careervault_app/api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps learning category, topic, subtopics and resources', () {
    final topic = PreparationTopic.fromJson({
      'id': 12,
      'category': {
        'id': 2,
        'name': 'Java Development',
        'slug': 'java-development',
        'published': true,
      },
      'title': 'Collections Framework',
      'slug': 'collections-framework',
      'introduction': 'Learn the Java collections APIs.',
      'explanation': 'Collections group objects into useful data structures.',
      'published': true,
      'referenceLinks': ['https://docs.oracle.com/'],
      'subtopics': [
        {
          'id': 4,
          'title': 'Lists',
          'slug': 'lists',
          'content': 'Ordered collections.',
          'sortOrder': 1,
        },
      ],
      'resources': [
        {
          'id': 8,
          'originalName': 'collections.pdf',
          'contentType': 'application/pdf',
          'kind': 'RESOURCE',
          'url': '/api/preparation/resources/8',
        },
      ],
    });

    expect(topic.category.slug, 'java-development');
    expect(topic.title, 'Collections Framework');
    expect(topic.subtopics.single.title, 'Lists');
    expect(topic.resources.single.originalName, 'collections.pdf');
    expect(topic.toJson()['referenceLinks'], 'https://docs.oracle.com/');
  });

  test('topic pages expose pagination metadata', () {
    final result = PreparationTopicPage(
      topics: const [],
      page: 1,
      totalPages: 3,
      totalElements: 27,
    );

    expect(result.page, 1);
    expect(result.totalPages, 3);
    expect(result.totalElements, 27);
  });
}
