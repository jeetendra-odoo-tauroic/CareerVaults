package career.vault.jobs;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface JobRepository extends JpaRepository<Job, Long> {
    List<Job> findAllByOrderByCreatedAtDesc();
    List<Job> findByStatusOrderByCreatedAtDesc(JobStatus status);
    List<Job> findByStatusAndCategoryIgnoreCaseOrderByCreatedAtDesc(JobStatus status, String category);
    List<Job> findByStatusAndExperienceLevelIgnoreCaseOrderByCreatedAtDesc(JobStatus status, String experienceLevel);
    List<Job> findByStatusAndCategoryIgnoreCaseAndExperienceLevelIgnoreCaseOrderByCreatedAtDesc(
            JobStatus status, String category, String experienceLevel);
    List<Job> findByStatusInAndClosingDateBefore(List<JobStatus> statuses, LocalDate date);

    @Query("""
            select j from Job j
            where lower(j.organisation) = lower(:organisation)
              and lower(j.title) = lower(:title)
              and ((:advertisementNumber is null and j.advertisementNumber is null)
                   or lower(j.advertisementNumber) = lower(:advertisementNumber))
            """)
    Optional<Job> findDuplicate(@Param("organisation") String organisation,
                                @Param("title") String title,
                                @Param("advertisementNumber") String advertisementNumber);

    @Query("""
            select j from Job j
            where j.status = :status
              and (:category is null or lower(j.category) = lower(:category))
              and (:experienceLevel is null or lower(j.experienceLevel) = lower(:experienceLevel))
            order by j.createdAt desc
            """)
    List<Job> findPublicJobs(@Param("status") JobStatus status,
                             @Param("category") String category,
                             @Param("experienceLevel") String experienceLevel);
}
