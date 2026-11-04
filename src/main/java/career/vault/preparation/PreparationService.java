package career.vault.preparation;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
public class PreparationService {
    private final PreparationCategoryRepository categories;
    private final PreparationTopicRepository topics;
    private final PreparationSubtopicRepository subtopics;
    private final PreparationResourceRepository resources;
    private final Path resourceDirectory;

    public PreparationService(PreparationCategoryRepository categories,
                              PreparationTopicRepository topics,
                              PreparationSubtopicRepository subtopics,
                              PreparationResourceRepository resources,
                              @org.springframework.beans.factory.annotation.Value("${careervault.preparation-resource-dir}")
                              String resourceDirectory) {
        this.categories = categories;
        this.topics = topics;
        this.subtopics = subtopics;
        this.resources = resources;
        this.resourceDirectory = Path.of(resourceDirectory).toAbsolutePath().normalize();
    }

    @Transactional(readOnly = true)
    public List<PreparationViews.CategoryView> publicCategories() {
        return categories.findByPublishedTrueOrderByNameAsc().stream()
                .map(PreparationViews.CategoryView::from).toList();
    }

    @Transactional(readOnly = true)
    public List<PreparationViews.CategoryView> adminCategories() {
        return categories.findAllByOrderByNameAsc().stream()
                .map(PreparationViews.CategoryView::from).toList();
    }

    @Transactional
    public PreparationViews.CategoryView createCategory(PreparationCategoryInput input) {
        PreparationCategory category = new PreparationCategory();
        category.initialize(input.name(), input.description(), input.published());
        ensureCategorySlugAvailable(category.getSlug(), null);
        return PreparationViews.CategoryView.from(categories.save(category));
    }

    @Transactional
    public PreparationViews.CategoryView updateCategory(long id, PreparationCategoryInput input) {
        PreparationCategory category = getCategory(id);
        String slug = PreparationSlugs.from(input.name());
        ensureCategorySlugAvailable(slug, id);
        category.update(input.name(), input.description(), input.published());
        return PreparationViews.CategoryView.from(categories.save(category));
    }

    @Transactional
    public void deleteCategory(long id) {
        PreparationCategory category = getCategory(id);
        if (topics.searchTopics(category.getSlug(), false, null, PageRequest.of(0, 1)).hasContent()) {
            throw new IllegalArgumentException("Delete or move this category's topics before deleting the category.");
        }
        categories.delete(category);
    }

    @Transactional(readOnly = true)
    public PreparationViews.PageView<PreparationViews.TopicView> publicTopics(
            String categorySlug, String search, int page, int size) {
        validatePaging(page, size);
        if (categorySlug != null && categories.findBySlug(categorySlug)
                .filter(PreparationCategory::isPublished).isEmpty()) {
            return PreparationViews.PageView.from(Page.empty(PageRequest.of(page, size)));
        }
        Page<PreparationTopic> result = topics.searchTopics(
                blankToNull(categorySlug), true, blankToNull(search),
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt").and(Sort.by("id"))));
        return PreparationViews.PageView.from(result.map(PreparationViews.TopicView::from));
    }

    @Transactional(readOnly = true)
    public PreparationViews.PageView<PreparationViews.TopicView> adminTopics(
            Long categoryId, String search, int page, int size) {
        validatePaging(page, size);
        String categorySlug = categoryId == null ? null : getCategory(categoryId).getSlug();
        Page<PreparationTopic> result = topics.searchTopics(categorySlug, false, blankToNull(search),
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt").and(Sort.by("id"))));
        return PreparationViews.PageView.from(result.map(PreparationViews.TopicView::from));
    }

    @Transactional(readOnly = true)
    public PreparationViews.TopicView publicTopic(String categorySlug, String topicSlug) {
        return PreparationViews.TopicView.from(topics
                .findByCategorySlugAndSlugAndPublishedTrueAndCategoryPublishedTrue(categorySlug, topicSlug)
                .orElseThrow(() -> new PreparationNotFoundException("Published preparation topic was not found.")));
    }

    @Transactional(readOnly = true)
    public PreparationViews.TopicView adminTopic(long id) {
        return PreparationViews.TopicView.from(getTopic(id));
    }

    @Transactional
    public PreparationViews.TopicView createTopic(PreparationTopicInput input) {
        PreparationCategory category = getCategory(input.categoryId());
        ensurePublicationAllowed(category, input.published());
        String slug = PreparationSlugs.from(input.title());
        ensureTopicSlugAvailable(category.getId(), slug, null);
        PreparationTopic topic = new PreparationTopic();
        topic.initialize(category, input.title(), input.introduction(), input.explanation(),
                input.codeExamples(), input.practicalExamples(), input.referenceLinks(), input.published());
        addInitialSubtopics(topic, input.subtopics());
        return PreparationViews.TopicView.from(topics.save(topic));
    }

    @Transactional
    public PreparationViews.TopicView updateTopic(long id, PreparationTopicInput input) {
        PreparationTopic topic = getTopic(id);
        PreparationCategory category = getCategory(input.categoryId());
        ensurePublicationAllowed(category, input.published());
        String slug = PreparationSlugs.from(input.title());
        ensureTopicSlugAvailable(category.getId(), slug, id);
        topic.setCategory(category);
        topic.update(input.title(), input.introduction(), input.explanation(), input.codeExamples(),
                input.practicalExamples(), input.referenceLinks(), input.published());
        if (input.subtopics() != null) {
            replaceSubtopics(topic, input.subtopics());
        }
        return PreparationViews.TopicView.from(topics.save(topic));
    }

    @Transactional
    public void deleteTopic(long id) throws IOException {
        PreparationTopic topic = getTopic(id);
        List<String> storedFiles = topic.getResources().stream()
                .map(PreparationResource::getStorageName).toList();
        topics.delete(topic);
        for (String filename : storedFiles) {
            Files.deleteIfExists(resolveResource(filename));
        }
    }

    @Transactional
    public PreparationViews.TopicView setTopicPublished(long id, boolean published) {
        PreparationTopic topic = getTopic(id);
        if (published && !topic.getCategory().isPublished()) {
            throw new IllegalArgumentException("Publish the category before publishing its topics.");
        }
        topic.setPublished(published);
        return PreparationViews.TopicView.from(topics.save(topic));
    }

    @Transactional
    public PreparationViews.SubtopicView createSubtopic(long topicId, PreparationSubtopicInput input) {
        PreparationTopic topic = getTopic(topicId);
        PreparationSubtopic subtopic = new PreparationSubtopic();
        subtopic.initialize(input.title(), input.content(), input.sortOrder());
        topic.addSubtopic(subtopic);
        topics.save(topic);
        return PreparationViews.SubtopicView.from(subtopic);
    }

    @Transactional
    public PreparationViews.SubtopicView updateSubtopic(long topicId, long subtopicId,
                                                         PreparationSubtopicInput input) {
        PreparationTopic topic = getTopic(topicId);
        PreparationSubtopic subtopic = topic.getSubtopics().stream()
                .filter(value -> value.getId().equals(subtopicId))
                .findFirst().orElseThrow(() -> new PreparationNotFoundException(
                        "Subtopic " + subtopicId + " was not found on topic " + topicId + "."));
        subtopic.update(input.title(), input.content(), input.sortOrder());
        topics.save(topic);
        return PreparationViews.SubtopicView.from(subtopic);
    }

    @Transactional
    public void deleteSubtopic(long topicId, long subtopicId) {
        PreparationTopic topic = getTopic(topicId);
        PreparationSubtopic subtopic = topic.getSubtopics().stream()
                .filter(value -> value.getId().equals(subtopicId))
                .findFirst().orElseThrow(() -> new PreparationNotFoundException(
                        "Subtopic " + subtopicId + " was not found on topic " + topicId + "."));
        topic.removeSubtopic(subtopic);
        topics.save(topic);
    }

    @Transactional
    public PreparationViews.ResourceView uploadResource(long topicId, MultipartFile file, String kind)
            throws IOException {
        if (file.isEmpty() || file.getSize() > 15 * 1024 * 1024) {
            throw new IllegalArgumentException("Choose a non-empty image or resource smaller than 15 MB.");
        }
        if (safeOriginalName(file.getOriginalFilename()).length() > 255) {
            throw new IllegalArgumentException("The selected filename must be 255 characters or fewer.");
        }
        byte[] bytes = file.getBytes();
        String contentType = file.getContentType();
        validateResource(file.getOriginalFilename(), contentType, bytes);
        if ("IMAGE".equals(kind) && !contentType.toLowerCase(Locale.ROOT).startsWith("image/")) {
            throw new IllegalArgumentException("Image resources must be PNG, JPEG or WebP images.");
        }
        PreparationTopic topic = getTopic(topicId);
        Files.createDirectories(resourceDirectory);
        String extension = extension(file.getOriginalFilename());
        String storageName = UUID.randomUUID() + extension;
        Files.write(resolveResource(storageName), bytes);
        PreparationResource resource = new PreparationResource();
        resource.initialize(safeOriginalName(file.getOriginalFilename()), storageName,
                contentType, kind);
        topic.addResource(resource);
        topics.save(topic);
        return PreparationViews.ResourceView.from(resource);
    }

    @Transactional(readOnly = true)
    public ResourceFile publicResource(long id) throws IOException {
        PreparationResource resource = resources.findById(id)
                .orElseThrow(() -> new PreparationNotFoundException("Learning resource was not found."));
        PreparationTopic topic = getTopic(resourceTopicId(resource));
        if (!topic.isPublished() || !topic.getCategory().isPublished()) {
            throw new PreparationNotFoundException("Published learning resource was not found.");
        }
        Path path = resolveResource(resource.getStorageName());
        return new ResourceFile(resource.getOriginalName(), resource.getContentType(), Files.readAllBytes(path));
    }

    @Transactional
    public void deleteResource(long topicId, long resourceId) throws IOException {
        PreparationTopic topic = getTopic(topicId);
        PreparationResource resource = topic.getResources().stream()
                .filter(value -> value.getId().equals(resourceId))
                .findFirst().orElseThrow(() -> new PreparationNotFoundException(
                        "Resource " + resourceId + " was not found on topic " + topicId + "."));
        String storedName = resource.getStorageName();
        topic.removeResource(resource);
        topics.save(topic);
        Files.deleteIfExists(resolveResource(storedName));
    }

    private long resourceTopicId(PreparationResource resource) {
        return resource.getTopicId();
    }

    private void replaceSubtopics(PreparationTopic topic, List<PreparationSubtopicInput> values) {
        topic.getSubtopics().clear();
        addInitialSubtopics(topic, values);
    }

    private void addInitialSubtopics(PreparationTopic topic, List<PreparationSubtopicInput> values) {
        if (values == null) return;
        for (PreparationSubtopicInput input : values) {
            PreparationSubtopic subtopic = new PreparationSubtopic();
            subtopic.initialize(input.title(), input.content(), input.sortOrder());
            topic.addSubtopic(subtopic);
        }
    }

    private void ensureCategorySlugAvailable(String slug, Long currentId) {
        categories.findBySlug(slug).filter(category -> !category.getId().equals(currentId))
                .ifPresent(category -> {
                    throw new IllegalArgumentException("A preparation category with this URL already exists.");
                });
    }

    private void ensureTopicSlugAvailable(Long categoryId, String slug, Long currentId) {
        boolean exists = currentId == null
                ? topics.existsByCategoryIdAndSlug(categoryId, slug)
                : topics.existsByCategoryIdAndSlugAndIdNot(categoryId, slug, currentId);
        if (exists) throw new IllegalArgumentException("A topic with this URL already exists in the category.");
    }

    private void ensurePublicationAllowed(PreparationCategory category, boolean published) {
        if (published && !category.isPublished()) {
            throw new IllegalArgumentException("Publish the category before publishing its topics.");
        }
    }

    private PreparationCategory getCategory(long id) {
        return categories.findById(id)
                .orElseThrow(() -> new PreparationNotFoundException("Preparation category " + id + " was not found."));
    }

    private PreparationTopic getTopic(long id) {
        return topics.findWithDetailsById(id)
                .orElseThrow(() -> new PreparationNotFoundException("Preparation topic " + id + " was not found."));
    }

    private void validatePaging(int page, int size) {
        if (page < 0 || size < 1 || size > 50) {
            throw new IllegalArgumentException("Page must be zero or greater and page size must be from 1 to 50.");
        }
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private void validateResource(String filename, String contentType, byte[] bytes) {
        if (filename == null || contentType == null || bytes.length == 0) {
            throw new IllegalArgumentException("The selected resource is invalid.");
        }
        String extension = extension(filename).toLowerCase();
        boolean validPdf = ".pdf".equals(extension) && "application/pdf".equalsIgnoreCase(contentType)
                && startsWith(bytes, "%PDF-".getBytes(java.nio.charset.StandardCharsets.US_ASCII));
        boolean validPng = ".png".equals(extension) && "image/png".equalsIgnoreCase(contentType)
                && startsWith(bytes, new byte[]{(byte) 0x89, 'P', 'N', 'G', 13, 10, 26, 10});
        boolean validJpeg = (".jpg".equals(extension) || ".jpeg".equals(extension))
                && "image/jpeg".equalsIgnoreCase(contentType)
                && bytes.length > 3 && (bytes[0] & 0xff) == 0xff && (bytes[1] & 0xff) == 0xd8
                && (bytes[2] & 0xff) == 0xff;
        boolean validWebp = ".webp".equals(extension) && "image/webp".equalsIgnoreCase(contentType)
                && bytes.length > 12 && ascii(bytes, 0, "RIFF") && ascii(bytes, 8, "WEBP");
        boolean validText = (".txt".equals(extension) || ".md".equals(extension))
                && ("text/plain".equalsIgnoreCase(contentType) || "text/markdown".equalsIgnoreCase(contentType))
                && !containsBinaryControl(bytes);
        if (!(validPdf || validPng || validJpeg || validWebp || validText)) {
            throw new IllegalArgumentException("Only valid PDF, PNG, JPEG, WebP, TXT or Markdown resources are supported.");
        }
    }

    private boolean startsWith(byte[] value, byte[] prefix) {
        if (value.length < prefix.length) return false;
        for (int i = 0; i < prefix.length; i++) if (value[i] != prefix[i]) return false;
        return true;
    }

    private boolean ascii(byte[] bytes, int offset, String value) {
        for (int i = 0; i < value.length(); i++) if (bytes[offset + i] != value.charAt(i)) return false;
        return true;
    }

    private boolean containsBinaryControl(byte[] bytes) {
        for (byte value : bytes) {
            int current = value & 0xff;
            if (current < 9 || (current > 13 && current < 32)) return true;
        }
        return false;
    }

    private String extension(String filename) {
        if (filename == null) return "";
        int dot = filename.lastIndexOf('.');
        return dot < 0 ? "" : filename.substring(dot).toLowerCase();
    }

    private String safeOriginalName(String filename) {
        if (filename == null) return "";
        Path name = Path.of(filename.replace('\\', '/')).getFileName();
        return name == null ? "" : name.toString();
    }

    private Path resolveResource(String filename) {
        Path path = resourceDirectory.resolve(filename).normalize();
        if (!path.startsWith(resourceDirectory)) {
            throw new IllegalArgumentException("Invalid resource path.");
        }
        return path;
    }

    public record ResourceFile(String filename, String contentType, byte[] content) {
    }
}
