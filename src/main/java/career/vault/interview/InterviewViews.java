package career.vault.interview;

import java.time.LocalDateTime;
import java.util.List;

public final class InterviewViews {
    private InterviewViews() {
    }

    public record CategoryView(Long id, String name, String slug, String description, boolean published) {
        static CategoryView from(InterviewCategory category) {
            return new CategoryView(category.getId(), category.getName(), category.getSlug(),
                    category.getDescription(), category.isPublished());
        }
    }

    public record TopicView(Long id, CategoryView category, String title, String slug,
                            String introduction, String article, List<String> experienceLevels,
                            boolean published, LocalDateTime createdAt, LocalDateTime updatedAt) {
        static TopicView from(InterviewTopic topic) {
            return new TopicView(topic.getId(), CategoryView.from(topic.getCategory()),
                    topic.getTitle(), topic.getSlug(), topic.getIntroduction(), topic.getArticle(),
                    topic.getExperienceLevels(), topic.isPublished(), topic.getCreatedAt(), topic.getUpdatedAt());
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
