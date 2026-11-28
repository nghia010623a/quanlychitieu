package quanlychitieu.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;
import quanlychitieu.dto.BudgetPeriodFilterDto;
import quanlychitieu.dto.BudgetProgressResponse;
import quanlychitieu.dto.BudgetRequest;
import quanlychitieu.dto.BudgetResponse;
import quanlychitieu.entity.User;
import quanlychitieu.enums.BudgetStatus;
import quanlychitieu.service.BudgetService;
import quanlychitieu.service.CurrentUserResolver;

@RestController
@RequestMapping("/api/budgets")
@RequiredArgsConstructor
public class BudgetController {

    private final BudgetService budgetService;
    private final CurrentUserResolver currentUserResolver;

    @GetMapping("/periods")
    public ResponseEntity<List<BudgetPeriodFilterDto>> getPeriodFilters(
            @RequestParam(required = false) Long userId,
            @RequestHeader(value = "X-User-Id", required = false) Long headerUserId) {
        User user = currentUserResolver.resolveUser(userId, headerUserId);
        return ResponseEntity.ok(budgetService.getPeriodFilters(user.getUserId()));
    }

    @GetMapping
    public ResponseEntity<List<BudgetResponse>> getBudgets(
            @RequestParam(required = false) Long userId,
            @RequestHeader(value = "X-User-Id", required = false) Long headerUserId,
            @RequestParam(required = false) String periodFilterId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) Long walletId,
            @RequestParam(required = false) BudgetStatus status) {
        User user = currentUserResolver.resolveUser(userId, headerUserId);
        return ResponseEntity.ok(
                budgetService.getBudgets(user.getUserId(), periodFilterId, startDate, endDate, walletId, status));
    }

    @GetMapping("/{budgetId}")
    public ResponseEntity<BudgetResponse> getBudgetById(
            @PathVariable Long budgetId,
            @RequestParam(required = false) Long userId,
            @RequestHeader(value = "X-User-Id", required = false) Long headerUserId) {
        User user = currentUserResolver.resolveUser(userId, headerUserId);
        return ResponseEntity.ok(budgetService.getBudgetById(user.getUserId(), budgetId));
    }

    @GetMapping("/{budgetId}/progress")
    public ResponseEntity<BudgetProgressResponse> getBudgetProgress(
            @PathVariable Long budgetId,
            @RequestParam(required = false) Long userId,
            @RequestHeader(value = "X-User-Id", required = false) Long headerUserId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate referenceDate) {
        User user = currentUserResolver.resolveUser(userId, headerUserId);
        return ResponseEntity.ok(budgetService.getBudgetProgress(user.getUserId(), budgetId, referenceDate));
    }

    @PostMapping
    public ResponseEntity<BudgetResponse> createBudget(
            @RequestParam(required = false) Long userId,
            @RequestHeader(value = "X-User-Id", required = false) Long headerUserId,
            @RequestBody BudgetRequest request) {
        User user = currentUserResolver.resolveUser(userId, headerUserId);
        BudgetResponse created = budgetService.createBudget(user, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @RequestMapping(value = "/{budgetId}", method = {RequestMethod.PUT, RequestMethod.PATCH})
    public ResponseEntity<BudgetResponse> updateBudget(
            @PathVariable Long budgetId,
            @RequestParam(required = false) Long userId,
            @RequestHeader(value = "X-User-Id", required = false) Long headerUserId,
            @RequestBody BudgetRequest request) {
        User user = currentUserResolver.resolveUser(userId, headerUserId);
        return ResponseEntity.ok(budgetService.updateBudget(user.getUserId(), budgetId, request));
    }

    @DeleteMapping("/{budgetId}")
    public ResponseEntity<Void> deleteBudget(
            @PathVariable Long budgetId,
            @RequestParam(required = false) Long userId,
            @RequestHeader(value = "X-User-Id", required = false) Long headerUserId) {
        User user = currentUserResolver.resolveUser(userId, headerUserId);
        budgetService.deleteBudget(user.getUserId(), budgetId);
        return ResponseEntity.noContent().build();
    }
}
