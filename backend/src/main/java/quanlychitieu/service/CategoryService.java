package quanlychitieu.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import lombok.RequiredArgsConstructor;
import quanlychitieu.dto.CategoryDto;
import quanlychitieu.entity.Category;
import quanlychitieu.enums.CategoryType;
import quanlychitieu.repository.CategoryRepository;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;

    @Transactional(readOnly = true)
    public List<CategoryDto> getAvailableCategories(Long userId, CategoryType type) {
        CategoryType targetType = type != null ? type : CategoryType.EXPENSE;
        return categoryRepository.findAvailableCategories(userId, targetType)
                .stream()
                .map(this::toDto)
                .toList();
    }

    private CategoryDto toDto(Category category) {
        return CategoryDto.builder()
                .categoryId(category.getCategoryId())
                .categoryName(category.getCategoryName())
                .categoryType(category.getCategoryType())
                .isDefault(category.getIsDefault())
                .build();
    }
}
