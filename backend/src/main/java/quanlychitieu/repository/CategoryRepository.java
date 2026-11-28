package quanlychitieu.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import quanlychitieu.entity.Category;
import quanlychitieu.enums.CategoryType;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {

    @Query("""
            SELECT c FROM Category c
            WHERE c.categoryType = :categoryType
              AND (c.isDefault = true OR c.user.userId = :userId)
            ORDER BY c.isDefault DESC, c.categoryId ASC
            """)
    List<Category> findAvailableCategories(
            @Param("userId") Long userId,
            @Param("categoryType") CategoryType categoryType);

    @Query("""
            SELECT c FROM Category c
            WHERE c.categoryId = :categoryId
              AND (c.isDefault = true OR c.user.userId = :userId)
            """)
    Optional<Category> findAccessibleCategoryById(
            @Param("categoryId") Long categoryId,
            @Param("userId") Long userId);
}
