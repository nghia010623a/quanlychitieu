package quanlychitieu.dto;

import lombok.Builder;
import lombok.Getter;
import quanlychitieu.enums.CategoryType;

@Getter
@Builder
public class CategoryDto {

    private Long categoryId;
    private String categoryName;
    private CategoryType categoryType;
    private Boolean isDefault;
}
