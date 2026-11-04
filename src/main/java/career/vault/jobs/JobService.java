package career.vault.jobs;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URI;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class JobService {
    private final JobRepository repository;

    public JobService(JobRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public Job create(JobInput input) {
        ensureNotDuplicate(input, null);
        Job job = new Job();
        job.apply(input);
        LocalDateTime now = LocalDateTime.now();
        job.setCreatedAt(now);
        job.setUpdatedAt(now);
        if (job.getClosingDate().isBefore(LocalDate.now())) {
            job.setStatus(JobStatus.EXPIRED);
        }
        return repository.save(job);
    }

    @Transactional
    public Job update(long id, JobInput input) {
        Job job = get(id);
        ensureNotDuplicate(input, id);
        job.apply(input);
        job.setUpdatedAt(LocalDateTime.now());
        if (job.getClosingDate().isBefore(LocalDate.now())) {
            job.setStatus(JobStatus.EXPIRED);
        }
        return repository.save(job);
    }

    @Transactional(readOnly = true)
    public Job get(long id) {
        return repository.findById(id).orElseThrow(() -> new JobNotFoundException(id));
    }

    @Transactional(readOnly = true)
    public List<Job> all() {
        return repository.findAllByOrderByCreatedAtDesc();
    }

    @Transactional(readOnly = true)
    public List<Job> byStatus(JobStatus status) {
        return repository.findByStatusOrderByCreatedAtDesc(status);
    }

    @Transactional
    public List<Job> publicJobs(String category, String experienceLevel) {
        expireJobs();
        return repository.findPublicJobs(JobStatus.PUBLISHED, blankToNull(category), blankToNull(experienceLevel));
    }

    @Transactional
    public Job save(Job job) {
        job.setUpdatedAt(LocalDateTime.now());
        return repository.save(job);
    }

    @Transactional
    public void delete(long id) {
        repository.delete(get(id));
    }

    @Transactional
    public Job setStatus(long id, JobStatus status) {
        Job job = get(id);
        if (status == JobStatus.PUBLISHED && job.getClosingDate().isBefore(LocalDate.now())) {
            throw new IllegalArgumentException("Expired jobs cannot be published.");
        }
        job.setStatus(status);
        job.setUpdatedAt(LocalDateTime.now());
        return repository.save(job);
    }

    @Transactional
    public void expireJobs() {
        List<Job> expired = repository.findByStatusInAndClosingDateBefore(
                List.of(JobStatus.DRAFT, JobStatus.PUBLISHED), LocalDate.now());
        expired.forEach(job -> {
            job.setStatus(JobStatus.EXPIRED);
            job.setUpdatedAt(LocalDateTime.now());
        });
        repository.saveAll(expired);
    }

    @Scheduled(cron = "0 0 * * * *")
    @Transactional
    public void expireJobsOnSchedule() {
        expireJobs();
    }

    private void ensureNotDuplicate(JobInput input, Long currentId) {
        if (input.title() == null || input.title().isBlank()
                || input.organisation() == null || input.organisation().isBlank()
                || input.category() == null || input.category().isBlank()
                || input.experienceLevel() == null || input.experienceLevel().isBlank()) {
            throw new IllegalArgumentException("Title, organisation, category and experience level are required.");
        }
        if (input.applicationStartDate() == null || input.closingDate() == null) {
            throw new IllegalArgumentException("Application start and closing dates are required.");
        }
        if (input.applicationStartDate().isAfter(input.closingDate())) {
            throw new IllegalArgumentException("Application start date must be on or before the closing date.");
        }
        if (input.applicationUrl() != null && !input.applicationUrl().isBlank()) {
            URI applicationUri;
            try {
                applicationUri = URI.create(input.applicationUrl().trim());
            } catch (IllegalArgumentException exception) {
                throw new IllegalArgumentException("Official application URL must be a valid HTTP or HTTPS URL.");
            }
            if (!applicationUri.isAbsolute()
                    || !("http".equalsIgnoreCase(applicationUri.getScheme())
                    || "https".equalsIgnoreCase(applicationUri.getScheme()))) {
                throw new IllegalArgumentException("Official application URL must use HTTP or HTTPS.");
            }
        }
        repository.findDuplicate(input.organisation().trim(), input.title().trim(),
                        blankToNull(input.advertisementNumber()))
                .filter(existing -> !existing.getId().equals(currentId))
                .ifPresent(existing -> {
                    throw new DuplicateJobException("A job with the same organisation, title and advertisement number already exists.");
                });
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
