package career.vault.mocktests;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PracticeTestRepository extends JpaRepository<PracticeTest, Long> {
    @EntityGraph(attributePaths = "questions")
    List<PracticeTest> findAllByOrderByCreatedAtDesc();

    @EntityGraph(attributePaths = "questions")
    List<PracticeTest> findByStatusOrderByCreatedAtDesc(TestStatus status);

    @EntityGraph(attributePaths = "questions")
    List<PracticeTest> findByKindAndStatusOrderByCreatedAtDesc(TestKind kind, TestStatus status);

    @EntityGraph(attributePaths = "questions")
    Optional<PracticeTest> findWithQuestionsById(long id);
}
