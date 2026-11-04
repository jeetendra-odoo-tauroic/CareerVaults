package career.vault.preparation;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface PreparationTopicRepository extends JpaRepository<PreparationTopic, Long> {
    @Query("""
            select t from PreparationTopic t
            join t.category c
            where (:categorySlug is null or c.slug = :categorySlug)
              and (:publishedOnly = false or (t.published = true and c.published = true))
              and (:search is null or lower(t.title) like lower(concat('%', :search, '%'))
                   or lower(t.introduction) like lower(concat('%', :search, '%')))
            """)
    Page<PreparationTopic> searchTopics(@Param("categorySlug") String categorySlug,
                                       @Param("publishedOnly") boolean publishedOnly,
                                       @Param("search") String search,
                                       Pageable pageable);

    @EntityGraph(attributePaths = "category")
    Optional<PreparationTopic> findByCategorySlugAndSlugAndPublishedTrueAndCategoryPublishedTrue(
            String categorySlug, String slug);

    @EntityGraph(attributePaths = "category")
    Optional<PreparationTopic> findWithDetailsById(Long id);

    boolean existsByCategoryIdAndSlugAndIdNot(Long categoryId, String slug, Long id);
    boolean existsByCategoryIdAndSlug(Long categoryId, String slug);
}
