package career.vault.jobs;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class JobBulkImportService {
    private static final List<String> HEADERS = List.of(
            "title", "organisation", "advertisementNumber", "category", "experienceLevel",
            "qualification", "salary", "location", "applicationStartDate", "closingDate",
            "description", "applicationUrl");
    private final JobService jobService;

    public JobBulkImportService(JobService jobService) {
        this.jobService = jobService;
    }

    public ImportResult importFile(String filename, InputStream input) throws IOException {
        List<List<String>> rows = filename.toLowerCase(Locale.ROOT).endsWith(".csv")
                ? readCsv(input) : readExcel(input);
        if (rows.isEmpty()) {
            throw new IllegalArgumentException("The uploaded file is empty.");
        }
        Map<String, Integer> columns = new HashMap<>();
        for (int index = 0; index < rows.get(0).size(); index++) {
            String header = rows.get(0).get(index).trim().replace("\uFEFF", "").toLowerCase(Locale.ROOT);
            columns.putIfAbsent(header, index);
        }
        List<String> missing = HEADERS.stream().filter(header -> !columns.containsKey(header.toLowerCase(Locale.ROOT))).toList();
        if (!missing.isEmpty()) {
            throw new IllegalArgumentException("Missing required template columns: " + String.join(", ", missing));
        }

        int imported = 0;
        int duplicates = 0;
        List<String> errors = new ArrayList<>();
        for (int rowIndex = 1; rowIndex < rows.size(); rowIndex++) {
            List<String> row = rows.get(rowIndex);
            if (row.stream().allMatch(String::isBlank)) {
                continue;
            }
            try {
                JobInput inputRow = toJobInput(row, columns);
                try {
                    jobService.create(inputRow);
                    imported++;
                } catch (DuplicateJobException duplicate) {
                    duplicates++;
                }
            } catch (RuntimeException error) {
                errors.add("Row " + (rowIndex + 1) + ": " + error.getMessage());
            }
        }
        return new ImportResult(imported, duplicates, errors);
    }

    private JobInput toJobInput(List<String> row, Map<String, Integer> columns) {
        return new JobInput(
                value(row, columns, "title"),
                value(row, columns, "organisation"),
                value(row, columns, "advertisementNumber"),
                value(row, columns, "category"),
                value(row, columns, "experienceLevel"),
                value(row, columns, "qualification"),
                value(row, columns, "salary"),
                value(row, columns, "location"),
                LocalDate.parse(value(row, columns, "applicationStartDate")),
                LocalDate.parse(value(row, columns, "closingDate")),
                value(row, columns, "description"),
                value(row, columns, "applicationUrl")
        );
    }

    private String value(List<String> row, Map<String, Integer> columns, String name) {
        int index = columns.get(name.toLowerCase(Locale.ROOT));
        return index < row.size() ? row.get(index).trim() : "";
    }

    private List<List<String>> readCsv(InputStream input) throws IOException {
        String content = new String(input.readAllBytes(), StandardCharsets.UTF_8);
        List<List<String>> rows = new ArrayList<>();
        List<String> fields = new ArrayList<>();
        StringBuilder field = new StringBuilder();
        boolean quoted = false;
        for (int index = 0; index < content.length(); index++) {
            char current = content.charAt(index);
            if (current == '"') {
                if (quoted && index + 1 < content.length() && content.charAt(index + 1) == '"') {
                    field.append('"');
                    index++;
                } else {
                    quoted = !quoted;
                }
            } else if (current == ',' && !quoted) {
                fields.add(field.toString());
                field.setLength(0);
            } else if ((current == '\n' || current == '\r') && !quoted) {
                fields.add(field.toString());
                field.setLength(0);
                rows.add(fields);
                fields = new ArrayList<>();
                if (current == '\r' && index + 1 < content.length() && content.charAt(index + 1) == '\n') {
                    index++;
                }
            } else {
                field.append(current);
            }
        }
        if (quoted) {
            throw new IllegalArgumentException("CSV contains an unclosed quoted field.");
        }
        fields.add(field.toString());
        if (fields.size() > 1 || !fields.get(0).isBlank()) {
            rows.add(fields);
        }
        return rows;
    }

    private List<List<String>> readExcel(InputStream input) throws IOException {
        List<List<String>> rows = new ArrayList<>();
        DataFormatter formatter = new DataFormatter();
        try (Workbook workbook = new XSSFWorkbook(input)) {
            var sheet = workbook.getSheetAt(0);
            for (Row row : sheet) {
                List<String> values = new ArrayList<>();
                int lastCell = Math.max(row.getLastCellNum(), 0);
                for (int cell = 0; cell < lastCell; cell++) {
                    Cell current = row.getCell(cell);
                    if (current != null && current.getCellType() == org.apache.poi.ss.usermodel.CellType.NUMERIC
                            && DateUtil.isCellDateFormatted(current)) {
                        values.add(current.getDateCellValue().toInstant()
                                .atZone(ZoneId.systemDefault()).toLocalDate().toString());
                    } else {
                        values.add(formatter.formatCellValue(current));
                    }
                }
                rows.add(values);
            }
        }
        return rows;
    }

    public record ImportResult(int imported, int duplicates, List<String> errors) {
    }
}
