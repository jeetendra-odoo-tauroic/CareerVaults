package career.vault.jobs;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "jobs", indexes = {
        @Index(name = "idx_jobs_status_closing_date", columnList = "status, closing_date"),
        @Index(name = "idx_jobs_published_created", columnList = "status, created_at")
})
public class Job {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Size(max = 200)
    @Column(nullable = false)
    private String title;

    @NotBlank
    @Size(max = 200)
    @Column(nullable = false)
    private String organisation;

    @Size(max = 100)
    private String advertisementNumber;

    @NotBlank
    @Size(max = 100)
    @Column(nullable = false)
    private String category;

    @NotBlank
    @Size(max = 100)
    @Column(nullable = false)
    private String experienceLevel;

    @Size(max = 500)
    private String qualification;

    @Size(max = 200)
    private String salary;

    @Size(max = 200)
    private String location;

    @NotNull
    @Column(nullable = false)
    private LocalDate applicationStartDate;

    @NotNull
    @Column(nullable = false)
    private LocalDate closingDate;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Size(max = 2048)
    private String applicationUrl;

    private String notificationFileName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private JobStatus status = JobStatus.DRAFT;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    protected Job() {
    }

    public void apply(JobInput input) {
        title = input.title().trim();
        organisation = input.organisation().trim();
        advertisementNumber = clean(input.advertisementNumber());
        category = input.category().trim();
        experienceLevel = input.experienceLevel().trim();
        qualification = clean(input.qualification());
        salary = clean(input.salary());
        location = clean(input.location());
        applicationStartDate = input.applicationStartDate();
        closingDate = input.closingDate();
        description = clean(input.description());
        applicationUrl = clean(input.applicationUrl());
    }

    private String clean(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    public void setStatus(JobStatus status) {
        this.status = status;
    }

    public void setNotificationFileName(String notificationFileName) {
        this.notificationFileName = notificationFileName;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public String getOrganisation() { return organisation; }
    public String getAdvertisementNumber() { return advertisementNumber; }
    public String getCategory() { return category; }
    public String getExperienceLevel() { return experienceLevel; }
    public String getQualification() { return qualification; }
    public String getSalary() { return salary; }
    public String getLocation() { return location; }
    public LocalDate getApplicationStartDate() { return applicationStartDate; }
    public LocalDate getClosingDate() { return closingDate; }
    public String getDescription() { return description; }
    public String getApplicationUrl() { return applicationUrl; }
    public String getNotificationFileName() { return notificationFileName; }
    public JobStatus getStatus() { return status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
