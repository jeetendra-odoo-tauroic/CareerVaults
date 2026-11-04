package career.vault.jobs;

import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.mockito.ArgumentCaptor.forClass;

class JobBulkImportServiceTest {
    private static final String HEADERS = "title,organisation,advertisementNumber,category,experienceLevel,qualification,"
            + "salary,location,applicationStartDate,closingDate,description,applicationUrl\n";

    @Test
    void importsQuotedMultilineCsvRows() throws Exception {
        JobService jobService = mock(JobService.class);
        JobBulkImportService importer = new JobBulkImportService(jobService);
        String csv = HEADERS + "Developer,Example Corp,ADV-1,Private IT,Entry level,BS,As per policy,Remote,"
                + "2026-11-01,2026-12-01,\"Build systems,\nwrite documentation\",https://example.com/apply\n";

        var result = importer.importFile("jobs.csv",
                new ByteArrayInputStream(csv.getBytes(StandardCharsets.UTF_8)));

        assertEquals(1, result.imported());
        assertEquals(0, result.duplicates());
        assertEquals(0, result.errors().size());
        var input = forClass(JobInput.class);
        verify(jobService).create(input.capture());
        assertEquals("Build systems,\nwrite documentation", input.getValue().description());
    }

    @Test
    void reportsDuplicateRowsWithoutFailingTheImport() throws Exception {
        JobService jobService = mock(JobService.class);
        when(jobService.create(any())).thenThrow(new DuplicateJobException("Duplicate."));
        JobBulkImportService importer = new JobBulkImportService(jobService);
        String csv = HEADERS + "Developer,Example Corp,ADV-1,Private IT,Entry level,BS,As per policy,Remote,"
                + "2026-11-01,2026-12-01,Build systems,https://example.com/apply\n";

        var result = importer.importFile("jobs.csv",
                new ByteArrayInputStream(csv.getBytes(StandardCharsets.UTF_8)));

        assertEquals(0, result.imported());
        assertEquals(1, result.duplicates());
        assertEquals(0, result.errors().size());
    }
}
