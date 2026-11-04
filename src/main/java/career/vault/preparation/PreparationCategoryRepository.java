package career.vault.preparation;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PreparationCategoryRepository extends JpaRepository<PreparationCategory, Long> {
    List<PreparationCategory> findAllByOrderByNameAsc();
    List<PreparationCategory> findByPublishedTrueOrderByNameAsc();
    Optional<PreparationCategory> findBySlug(String slug);
    boolean existsByNameIgnoreCase(String name);
    boolean existsBySlugAndIdNot(String slug, Long id);
}
