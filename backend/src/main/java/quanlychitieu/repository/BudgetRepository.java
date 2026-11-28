package quanlychitieu.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import quanlychitieu.entity.Budget;
import quanlychitieu.enums.BudgetStatus;

@Repository
public interface BudgetRepository extends JpaRepository<Budget, Long> {

    @Query("""
            SELECT b FROM Budget b
            JOIN FETCH b.wallet w
            LEFT JOIN FETCH b.category c
            WHERE b.createdBy.userId = :userId
              AND b.status = :status
            ORDER BY b.createdAt DESC
            """)
    List<Budget> findActiveByUserId(
            @Param("userId") Long userId,
            @Param("status") BudgetStatus status);

    @Query("""
            SELECT b FROM Budget b
            JOIN FETCH b.wallet w
            LEFT JOIN FETCH b.category c
            WHERE b.budgetId = :budgetId
              AND b.createdBy.userId = :userId
            """)
    Optional<Budget> findByIdAndUserId(
            @Param("budgetId") Long budgetId,
            @Param("userId") Long userId);
}
