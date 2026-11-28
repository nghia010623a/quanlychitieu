package quanlychitieu.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;
import quanlychitieu.dto.CategoryDto;
import quanlychitieu.entity.User;
import quanlychitieu.enums.CategoryType;
import quanlychitieu.service.CategoryService;
import quanlychitieu.service.CurrentUserResolver;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
public class CategoryController {

    private final CategoryService categoryService;
    private final CurrentUserResolver currentUserResolver;

    @GetMapping
    public ResponseEntity<List<CategoryDto>> getAvailableCategories(
            @RequestParam(required = false) Long userId,
            @RequestHeader(value = "X-User-Id", required = false) Long headerUserId,
            @RequestParam(required = false) CategoryType type) {
        User user = currentUserResolver.resolveUser(userId, headerUserId);
        return ResponseEntity.ok(categoryService.getAvailableCategories(user.getUserId(), type));
    }
}
