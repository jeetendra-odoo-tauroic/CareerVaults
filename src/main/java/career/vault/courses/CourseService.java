package career.vault.courses;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class CourseService {
    private final CourseRepository repository;

    public CourseService(CourseRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public List<CourseViews.CourseView> adminCourses() {
        return repository.findAllByOrderByCreatedAtDesc().stream()
                .map(course -> CourseViews.CourseView.from(course, true)).toList();
    }

    @Transactional(readOnly = true)
    public List<CourseViews.CourseView> publicCourses() {
        return repository.findByStatusOrderByCreatedAtDesc(CourseStatus.PUBLISHED).stream()
                .map(CourseViews.CourseView::from).toList();
    }

    @Transactional(readOnly = true)
    public CourseViews.CourseView publicCourse(long id) {
        Course course = get(id);
        if (course.getStatus() != CourseStatus.PUBLISHED) {
            throw new CourseNotFoundException(id);
        }
        return CourseViews.CourseView.from(course);
    }

    @Transactional(readOnly = true)
    public Course adminCourse(long id) {
        return get(id);
    }

    @Transactional
    public CourseViews.CourseView create(CourseInput input) {
        Course course = new Course();
        course.initialize(input);
        return CourseViews.CourseView.from(repository.save(course), true);
    }

    @Transactional
    public CourseViews.CourseView update(long id, CourseInput input) {
        Course course = get(id);
        course.apply(input);
        return CourseViews.CourseView.from(repository.save(course), true);
    }

    @Transactional
    public CourseViews.CourseView setStatus(long id, CourseStatus status) {
        Course course = get(id);
        course.setStatus(status);
        return CourseViews.CourseView.from(repository.save(course), true);
    }

    @Transactional
    public void delete(long id) {
        repository.delete(get(id));
    }

    @Transactional
    public Course save(Course course) {
        return repository.save(course);
    }

    private Course get(long id) {
        return repository.findById(id).orElseThrow(() -> new CourseNotFoundException(id));
    }
}
