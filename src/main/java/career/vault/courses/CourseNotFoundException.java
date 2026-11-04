package career.vault.courses;

public class CourseNotFoundException extends RuntimeException {
    public CourseNotFoundException(long id) {
        super("Course " + id + " was not found.");
    }
}
