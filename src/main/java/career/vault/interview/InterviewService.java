package career.vault.interview;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class InterviewService {
    private final InterviewCategoryRepository categories;
    private final InterviewTopicRepository topics;

    public InterviewService(InterviewCategoryRepository categories, InterviewTopicRepository topics) {
        this.categories = categories;
        this.topics = topics;
    }

    @Transactional(readOnly = true)
    public List<InterviewViews.CategoryView> publicCategories() {
        return categories.findByPublishedTrueOrderByNameAsc().stream()
                .map(InterviewViews.CategoryView::from).toList();
    }

    @Transactional(readOnly = true)
    public List<InterviewViews.CategoryView> adminCategories() {
        return categories.findAllByOrderByNameAsc().stream()
                .map(InterviewViews.CategoryView::from).toList();
    }

    @Transactional
    public InterviewViews.CategoryView createCategory(InterviewCategoryInput input) {
        String slug = InterviewSlugs.from(input.name());
        if (categories.findBySlug(slug).isPresent()) {
            throw new IllegalArgumentException("An interview category with this URL already exists.");
        }
        InterviewCategory category = new InterviewCategory();
        category.initialize(input.name(), input.description(), input.published());
        return InterviewViews.CategoryView.from(categories.save(category));
    }

    @Transactional
    public InterviewViews.CategoryView updateCategory(long id, InterviewCategoryInput input) {
        InterviewCategory category = getCategory(id);
        String slug = InterviewSlugs.from(input.name());
        categories.findBySlug(slug).filter(existing -> !existing.getId().equals(id))
                .ifPresent(existing -> {
                    throw new IllegalArgumentException("An interview category with this URL already exists.");
                });
        category.update(input.name(), input.description(), input.published());
        return InterviewViews.CategoryView.from(categories.save(category));
    }

    @Transactional
    public void deleteCategory(long id) {
        InterviewCategory category = getCategory(id);
        if (topics.existsByCategoryId(id)) {
            throw new IllegalArgumentException("Delete or move this category's topics before deleting the category.");
        }
        categories.delete(category);
    }

    @Transactional(readOnly = true)
    public InterviewViews.PageView<InterviewViews.TopicView> publicTopics(
            String categorySlug, String search, String experienceLevel, int page, int size) {
        validatePaging(page, size);
        if (categorySlug != null && categories.findBySlug(categorySlug)
                .filter(InterviewCategory::isPublished).isEmpty()) {
            return InterviewViews.PageView.from(Page.empty(PageRequest.of(page, size)));
        }
        String level = normalizeExperienceLevel(experienceLevel);
        Page<InterviewTopic> result = topics.searchTopics(
                blankToNull(categorySlug), true, blankToNull(search), level,
                PageRequest.of(page, size,
                        Sort.by(Sort.Direction.DESC, "createdAt").and(Sort.by("id"))));
        return InterviewViews.PageView.from(result.map(InterviewViews.TopicView::from));
    }

    @Transactional(readOnly = true)
    public InterviewViews.PageView<InterviewViews.TopicView> adminTopics(
            Long categoryId, String search, String experienceLevel, int page, int size) {
        validatePaging(page, size);
        String categorySlug = categoryId == null ? null : getCategory(categoryId).getSlug();
        Page<InterviewTopic> result = topics.searchTopics(
                categorySlug, false, blankToNull(search), normalizeExperienceLevel(experienceLevel),
                PageRequest.of(page, size,
                        Sort.by(Sort.Direction.DESC, "createdAt").and(Sort.by("id"))));
        return InterviewViews.PageView.from(result.map(InterviewViews.TopicView::from));
    }

    @Transactional(readOnly = true)
    public InterviewViews.TopicView publicTopic(String categorySlug, String topicSlug) {
        return InterviewViews.TopicView.from(topics
                .findByCategorySlugAndSlugAndPublishedTrueAndCategoryPublishedTrue(categorySlug, topicSlug)
                .orElseThrow(() -> new InterviewNotFoundException(
                        "Published interview preparation article was not found.")));
    }

    @Transactional(readOnly = true)
    public InterviewViews.TopicView adminTopic(long id) {
        return InterviewViews.TopicView.from(getTopic(id));
    }

    @Transactional
    public InterviewViews.TopicView createTopic(InterviewTopicInput input) {
        InterviewCategory category = getCategory(input.categoryId());
        requirePublishedCategoryForPublishedTopic(category, input.published());
        String slug = InterviewSlugs.from(input.title());
        ensureTopicSlugAvailable(category.getId(), slug, null);
        InterviewTopic topic = new InterviewTopic();
        topic.initialize(category, input.title(), input.introduction(), input.article(),
                InterviewExperienceLevels.validate(input.experienceLevels()), input.published());
        return InterviewViews.TopicView.from(topics.save(topic));
    }

    @Transactional
    public InterviewViews.TopicView updateTopic(long id, InterviewTopicInput input) {
        InterviewTopic topic = getTopic(id);
        InterviewCategory category = getCategory(input.categoryId());
        requirePublishedCategoryForPublishedTopic(category, input.published());
        String slug = InterviewSlugs.from(input.title());
        ensureTopicSlugAvailable(category.getId(), slug, id);
        topic.setCategory(category);
        topic.update(input.title(), input.introduction(), input.article(),
                InterviewExperienceLevels.validate(input.experienceLevels()), input.published());
        return InterviewViews.TopicView.from(topics.save(topic));
    }

    @Transactional
    public void deleteTopic(long id) {
        topics.delete(getTopic(id));
    }

    @Transactional
    public InterviewViews.TopicView setTopicPublished(long id, boolean published) {
        InterviewTopic topic = getTopic(id);
        requirePublishedCategoryForPublishedTopic(topic.getCategory(), published);
        topic.setPublished(published);
        return InterviewViews.TopicView.from(topics.save(topic));
    }

    private InterviewCategory getCategory(long id) {
        return categories.findById(id).orElseThrow(() ->
                new InterviewNotFoundException("Interview category " + id + " was not found."));
    }

    private InterviewTopic getTopic(long id) {
        return topics.findWithCategoryById(id).orElseThrow(() ->
                new InterviewNotFoundException("Interview topic " + id + " was not found."));
    }

    private void ensureTopicSlugAvailable(Long categoryId, String slug, Long currentId) {
        boolean exists = currentId == null
                ? topics.existsByCategoryIdAndSlug(categoryId, slug)
                : topics.existsByCategoryIdAndSlugAndIdNot(categoryId, slug, currentId);
        if (exists) {
            throw new IllegalArgumentException("A topic with this URL already exists in the category.");
        }
    }

    private void requirePublishedCategoryForPublishedTopic(InterviewCategory category, boolean published) {
        if (published && !category.isPublished()) {
            throw new IllegalArgumentException("Publish the category before publishing its interview topics.");
        }
    }

    private String normalizeExperienceLevel(String level) {
        if (level == null || level.isBlank()) return null;
        String normalized = level.trim();
        if (!InterviewExperienceLevels.ALL.contains(normalized)) {
            throw new IllegalArgumentException("Select a supported interview experience level.");
        }
        return normalized;
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private void validatePaging(int page, int size) {
        if (page < 0 || size < 1 || size > 50) {
            throw new IllegalArgumentException("Page must be zero or greater and page size must be from 1 to 50.");
        }
    }
}
