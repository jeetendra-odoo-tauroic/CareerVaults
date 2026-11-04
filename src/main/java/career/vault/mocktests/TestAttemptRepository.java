package career.vault.mocktests;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;

public interface TestAttemptRepository extends JpaRepository<TestAttempt, String> {
    @EntityGraph(attributePaths = "questions")
    Optional<TestAttempt> findWithQuestionsById(String id);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from TestAttempt a where a.id = :id")
    Optional<TestAttempt> findForSubmission(@Param("id") String id);

    @EntityGraph(attributePaths = "questions")
    List<TestAttempt> findByGuestIdAndStatusOrderBySubmittedAtDesc(
            String guestId, AttemptStatus status);

    @EntityGraph(attributePaths = "questions")
    List<TestAttempt> findByOwnerIdAndStatusOrderBySubmittedAtDesc(
            String ownerId, AttemptStatus status);
}
