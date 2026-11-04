package career.vault.courses;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public final class CourseViews {
    private CourseViews() {
    }

    public record CourseView(Long id, String name, String category, String description,
                             BigDecimal price, CourseStatus status, String imageUrl,
                             LocalDateTime createdAt, LocalDateTime updatedAt) {
        static CourseView from(Course course) {
            return from(course, false);
        }

        static CourseView from(Course course, boolean admin) {
            return new CourseView(course.getId(), course.getName(), course.getCategory(),
                    course.getDescription(), course.getPrice(), course.getStatus(),
                    course.getImageFileName() == null ? null
                            : (admin ? "/api/admin/courses/" : "/api/courses/")
                            + course.getId() + "/image",
                    course.getCreatedAt(), course.getUpdatedAt());
        }
    }
}
