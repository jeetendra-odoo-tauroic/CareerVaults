package career.vault.jobs;

import career.vault.accounts.CurrentAccount;
import career.vault.access.AccessMode;
import career.vault.access.AccessSettingsService;
import jakarta.validation.Valid;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api")
public class JobController {
    private final JobService service;
    private final JobBulkImportService bulkImportService;
    private final AccessSettingsService accessSettings;
    private final Path uploadDirectory;

    public JobController(JobService service, JobBulkImportService bulkImportService,
                         AccessSettingsService accessSettings,
                         @org.springframework.beans.factory.annotation.Value("${careervault.upload-dir}") String uploadDirectory) {
        this.service = service;
        this.bulkImportService = bulkImportService;
        this.accessSettings = accessSettings;
        this.uploadDirectory = Paths.get(uploadDirectory).toAbsolutePath().normalize();
    }

    @GetMapping("/jobs")
    public List<Job> publicJobs(@RequestParam(required = false) String category,
                               @RequestParam(required = false) String experienceLevel,
                               @RequestParam(required = false) String section) {
        List<Job> jobs = service.publicJobs(category, experienceLevel);
        if ("GOVERNMENT".equalsIgnoreCase(section)) {
            return jobs.stream().filter(this::isGovernmentJob).toList();
        }
        if ("IT".equalsIgnoreCase(section)) {
            return jobs.stream().filter(job -> !isGovernmentJob(job)).toList();
        }
        if (category != null || CurrentAccount.isAuthenticated()) {
            return jobs;
        }
        boolean governmentPublic =
                accessSettings.mode("GOVERNMENT_JOB_LISTINGS") == AccessMode.PUBLIC;
        boolean itPublic = accessSettings.mode("IT_JOB_LISTINGS") == AccessMode.PUBLIC;
        return jobs.stream().filter(job -> isGovernmentJob(job) ? governmentPublic : itPublic).toList();
    }

    @GetMapping("/jobs/{id}")
    public Job publicJob(@PathVariable long id) {
        Job job = service.get(id);
        if (job.getStatus() != JobStatus.PUBLISHED
                || job.getClosingDate().isBefore(java.time.LocalDate.now())) {
            throw new JobNotFoundException(id);
        }
        return job;
    }

    @GetMapping("/admin/jobs")
    public List<Job> allJobs(@RequestParam(required = false) JobStatus status) {
        return status == null ? service.all() : service.byStatus(status);
    }

    @PostMapping("/admin/jobs")
    public Job create(@Valid @RequestBody JobInput input) {
        return service.create(input);
    }

    @PutMapping("/admin/jobs/{id}")
    public Job update(@PathVariable long id, @Valid @RequestBody JobInput input) {
        return service.update(id, input);
    }

    @DeleteMapping("/admin/jobs/{id}")
    public ResponseEntity<Void> delete(@PathVariable long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/admin/jobs/{id}/status")
    public Job setStatus(@PathVariable long id, @RequestBody Map<String, JobStatus> request) {
        JobStatus status = request.get("status");
        if (status == null || status == JobStatus.EXPIRED) {
            throw new IllegalArgumentException("Status must be DRAFT or PUBLISHED.");
        }
        return service.setStatus(id, status);
    }

    @PostMapping(value = "/admin/jobs/{id}/notification", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Job uploadNotification(@PathVariable long id, @RequestParam("file") MultipartFile file) throws IOException {
        if (file.isEmpty() || file.getSize() > 10 * 1024 * 1024) {
            throw new IllegalArgumentException("Choose a non-empty PDF smaller than 10 MB.");
        }
        byte[] content = file.getBytes();
        if (content.length < 5 || content[0] != '%' || content[1] != 'P'
                || content[2] != 'D' || content[3] != 'F' || content[4] != '-') {
            throw new IllegalArgumentException("The notification must be a valid PDF file.");
        }

        Job job = service.get(id);
        Files.createDirectories(uploadDirectory);
        String storedName = UUID.randomUUID() + ".pdf";
        Files.write(uploadDirectory.resolve(storedName), content);
        job.setNotificationFileName(storedName);
        return service.save(job);
    }

    @GetMapping("/jobs/{id}/notification")
    public ResponseEntity<Resource> notification(@PathVariable long id) throws IOException {
        Job job = service.get(id);
        if (job.getStatus() != JobStatus.PUBLISHED
                || job.getClosingDate().isBefore(java.time.LocalDate.now())
                || job.getNotificationFileName() == null) {
            return ResponseEntity.notFound().build();
        }
        Path file = uploadDirectory.resolve(job.getNotificationFileName()).normalize();
        if (!file.startsWith(uploadDirectory) || !Files.isRegularFile(file)) {
            return ResponseEntity.notFound().build();
        }
        Resource resource = new ByteArrayResource(Files.readAllBytes(file));
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.inline().filename("job-notification-" + id + ".pdf").build().toString())
                .body(resource);
    }

    @PostMapping(value = "/admin/jobs/import", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public JobBulkImportService.ImportResult importJobs(@RequestParam("file") MultipartFile file) throws IOException {
        if (file.isEmpty() || file.getSize() > 10 * 1024 * 1024) {
            throw new IllegalArgumentException("Choose a non-empty CSV or Excel file smaller than 10 MB.");
        }
        String name = file.getOriginalFilename();
        if (name == null || !(name.toLowerCase().endsWith(".csv") || name.toLowerCase().endsWith(".xlsx"))) {
            throw new IllegalArgumentException("Only CSV and .xlsx files are supported.");
        }
        return bulkImportService.importFile(name, file.getInputStream());
    }

    @GetMapping(value = "/admin/jobs/template.csv", produces = "text/csv")
    public ResponseEntity<String> csvTemplate() {
        String template = "title,organisation,advertisementNumber,category,experienceLevel,qualification,salary,location,"
                + "applicationStartDate,closingDate,description,applicationUrl\n"
                + "Software Engineer,Example Organisation,ADV-2026-01,Government IT,Entry level,Bachelor degree,"
                + "As per rules,India,2026-11-01,2026-12-01,Role description,https://example.gov.in/apply\n";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=careervault-jobs-template.csv")
                .contentType(new MediaType("text", "csv"))
                .body(template);
    }

    private boolean isGovernmentJob(Job job) {
        String category = job.getCategory().toLowerCase(java.util.Locale.ROOT);
        return category.contains("government") || category.contains("govt")
                || category.contains("banking") || category.contains("upsc")
                || category.contains("ssc") || category.contains("railway")
                || category.contains("psu");
    }
}
