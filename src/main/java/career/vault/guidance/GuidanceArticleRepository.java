package career.vault.guidance;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface GuidanceArticleRepository extends JpaRepository<GuidanceArticle, Long> {
    List<GuidanceArticle> findAllByOrderByUpdatedAtDesc();

    List<GuidanceArticle> findByStatusOrderByUpdatedAtDesc(GuidanceStatus status);

    List<GuidanceArticle> findByStatusAndTitleContainingIgnoreCaseOrderByUpdatedAtDesc(
            GuidanceStatus status, String title);

    List<GuidanceArticle> findByStatusAndCategoryOrderByUpdatedAtDesc(
            GuidanceStatus status, GuidanceCategory category);

    List<GuidanceArticle> findByStatusAndCategoryAndTitleContainingIgnoreCaseOrderByUpdatedAtDesc(
            GuidanceStatus status, GuidanceCategory category, String title);

    Optional<GuidanceArticle> findByIdAndStatus(long id, GuidanceStatus status);
}
