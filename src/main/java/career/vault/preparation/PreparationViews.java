package career.vault.preparation;

import java.time.LocalDateTime;
import java.util.List;

public final class PreparationViews {
    private PreparationViews() {
    }

    public record CategoryView(Long id, String name, String slug, String description, boolean published) {
        static CategoryView from(PreparationCategory category) {
            return new CategoryView(category.getId(), category.getName(), category.getSlug(),
                    category.getDescription(), category.isPublished());
        }
    }

    public record SubtopicView(Long id, String title, String slug, String content, int sortOrder) {
        static SubtopicView from(PreparationSubtopic subtopic) {
            return new SubtopicView(subtopic.getId(), subtopic.getTitle(), subtopic.getSlug(),
                    subtopic.getContent(), subtopic.getSortOrder());
        }
    }

    public record ResourceView(Long id, String originalName, String contentType, String kind,
                               String url, LocalDateTime createdAt) {
        static ResourceView from(PreparationResource resource) {
            return new ResourceView(resource.getId(), resource.getOriginalName(), resource.getContentType(),
                    resource.getKind(), "/api/preparation/resources/" + resource.getId(), resource.getCreatedAt());
        }
    }

    public record TopicView(Long id, CategoryView category, String title, String slug,
                            String introduction, String explanation, String codeExamples,
                            String practicalExamples, List<String> referenceLinks, boolean published,
                            LocalDateTime createdAt, LocalDateTime updatedAt,
                            List<SubtopicView> subtopics, List<ResourceView> resources) {
        static TopicView from(PreparationTopic topic) {
            List<String> links = topic.getReferenceLinks() == null ? List.of()
                    : topic.getReferenceLinks().lines().map(String::trim).filter(line -> !line.isEmpty()).toList();
            return new TopicView(topic.getId(), CategoryView.from(topic.getCategory()),
                    topic.getTitle(), topic.getSlug(), topic.getIntroduction(), topic.getExplanation(),
                    topic.getCodeExamples(), topic.getPracticalExamples(), links, topic.isPublished(),
                    topic.getCreatedAt(), topic.getUpdatedAt(),
                    topic.getSubtopics().stream().map(SubtopicView::from).toList(),
                    topic.getResources().stream().map(ResourceView::from).toList());
        }
    }

    public record PageView<T>(List<T> content, int page, int size, long totalElements,
                              int totalPages, boolean first, boolean last) {
        static <T> PageView<T> from(org.springframework.data.domain.Page<T> result) {
            return new PageView<>(result.getContent(), result.getNumber(), result.getSize(),
                    result.getTotalElements(), result.getTotalPages(), result.isFirst(), result.isLast());
        }
    }
}
