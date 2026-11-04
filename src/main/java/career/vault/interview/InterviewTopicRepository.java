package career.vault.interview;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface InterviewTopicRepository extends JpaRepository<InterviewTopic, Long> {
    @Query("""
            select t from InterviewTopic t
            join t.category c
            where (:categorySlug is null or c.slug = :categorySlug)
              and (:publishedOnly = false or (t.published = true and c.published = true))
              and (:search is null or lower(t.title) like lower(concat('%', :search, '%'))
                   or lower(t.introduction) like lower(concat('%', :search, '%')))
              and (:experienceLevel is null or
                   lower(concat('\n', coalesce(t.experienceLevels, ''), '\n'))
                   like lower(concat('%\n', :experienceLevel, '\n%')))
            """)
    Page<InterviewTopic> searchTopics(@Param("categorySlug") String categorySlug,
                                      @Param("publishedOnly") boolean publishedOnly,
                                      @Param("search") String search,
                                      @Param("experienceLevel") String experienceLevel,
                                      Pageable pageable);

    @EntityGraph(attributePaths = "category")
    Optional<InterviewTopic> findByCategorySlugAndSlugAndPublishedTrueAndCategoryPublishedTrue(
            String categorySlug, String slug);

    @EntityGraph(attributePaths = "category")
    Optional<InterviewTopic> findWithCategoryById(Long id);

    boolean existsByCategoryIdAndSlug(Long categoryId, String slug);
    boolean existsByCategoryIdAndSlugAndIdNot(Long categoryId, String slug, Long id);
    boolean existsByCategoryId(Long categoryId);
}
