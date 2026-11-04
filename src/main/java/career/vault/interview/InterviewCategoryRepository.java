package career.vault.interview;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface InterviewCategoryRepository extends JpaRepository<InterviewCategory, Long> {
    List<InterviewCategory> findAllByOrderByNameAsc();
    List<InterviewCategory> findByPublishedTrueOrderByNameAsc();
    Optional<InterviewCategory> findBySlug(String slug);
}
