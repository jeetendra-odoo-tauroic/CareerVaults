package career.vault.guidance;

import java.time.LocalDateTime;
import java.util.List;

public final class GuidanceViews {
    private GuidanceViews() {
    }

    public record CategoryView(String code, String label) {
        static CategoryView from(GuidanceCategory category) {
            return new CategoryView(category.name(), category.label());
        }
    }

    public record ArticleView(Long id, String title, GuidanceCategory category,
                              String categoryLabel, String shortDescription,
                              String content, String imageUrl, GuidanceStatus status,
                              LocalDateTime createdAt, LocalDateTime updatedAt) {
        static ArticleView from(GuidanceArticle article) {
            return from(article, false);
        }

        static ArticleView from(GuidanceArticle article, boolean admin) {
            return new ArticleView(article.getId(), article.getTitle(), article.getCategory(),
                    article.getCategory().label(), article.getShortDescription(),
                    article.getContent(), article.getImageFileName() == null ? null
                    : (admin ? "/api/admin/guidance/" : "/api/guidance/")
                    + article.getId() + "/image",
                    article.getStatus(), article.getCreatedAt(), article.getUpdatedAt());
        }
    }

    public record ArticleSummary(Long id, String title, GuidanceCategory category,
                                 String categoryLabel, String shortDescription,
                                 String imageUrl, LocalDateTime createdAt,
                                 LocalDateTime updatedAt) {
        static ArticleSummary from(GuidanceArticle article) {
            return new ArticleSummary(article.getId(), article.getTitle(), article.getCategory(),
                    article.getCategory().label(), article.getShortDescription(),
                    article.getImageFileName() == null ? null
                            : "/api/guidance/" + article.getId() + "/image",
                    article.getCreatedAt(), article.getUpdatedAt());
        }
    }

    public record ArticleList(List<ArticleSummary> articles,
                              List<CategoryView> categories) {
    }
}
