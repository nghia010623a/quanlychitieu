package quanlychitieu.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

import quanlychitieu.config.SecurityConfig;
import quanlychitieu.dto.BudgetDailyPointDto;
import quanlychitieu.dto.BudgetMilestoneDto;
import quanlychitieu.dto.BudgetPeriodFilterDto;
import quanlychitieu.dto.BudgetProgressResponse;
import quanlychitieu.dto.BudgetResponse;
import quanlychitieu.dto.BudgetTransactionDto;
import quanlychitieu.dto.CategoryDto;
import quanlychitieu.dto.WalletOptionDto;
import quanlychitieu.entity.User;
import quanlychitieu.enums.BudgetPeriod;
import quanlychitieu.enums.BudgetStatus;
import quanlychitieu.enums.CategoryType;
import quanlychitieu.enums.WalletType;
import quanlychitieu.exception.GlobalExceptionHandler;
import quanlychitieu.service.BudgetService;
import quanlychitieu.service.CategoryService;
import quanlychitieu.service.CurrentUserResolver;
import quanlychitieu.service.WalletService;

@WebMvcTest(controllers = {BudgetController.class, CategoryController.class, WalletController.class})
@Import({SecurityConfig.class, GlobalExceptionHandler.class})
class BudgetApiControllersTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private BudgetService budgetService;

    @MockitoBean
    private CategoryService categoryService;

    @MockitoBean
    private WalletService walletService;

    @MockitoBean
    private CurrentUserResolver currentUserResolver;

    private User sampleUser() {
        return User.builder().userId(1L).nickname("demo").fullName("Demo User").build();
    }

    private BudgetResponse sampleBudgetResponse() {
        return BudgetResponse.builder()
                .budgetId(10L)
                .walletId(2L)
                .walletIds(List.of(2L))
                .categoryId(5L)
                .categoryName("Ăn uống")
                .budgetName("Ăn uống")
                .amount(new BigDecimal("3000000.00"))
                .spentAmount(new BigDecimal("1800000.00"))
                .period(BudgetPeriod.MONTH)
                .startDate(LocalDate.of(2026, 11, 1))
                .endDate(LocalDate.of(2026, 11, 30))
                .alertPercent(new BigDecimal("80.00"))
                .status(BudgetStatus.ACTIVE)
                .repeatMonthly(true)
                .transactions(List.of(
                        BudgetTransactionDto.builder()
                                .transactionId(101L)
                                .title("Bún chả Hương Liên")
                                .walletId(2L)
                                .walletName("Ví tiền mặt")
                                .transactionTime(LocalDateTime.of(2026, 11, 15, 12, 30))
                                .amount(new BigDecimal("-85000.00"))
                                .build()))
                .build();
    }

    @Test
    void getPeriodFiltersReturnsFilters() throws Exception {
        when(currentUserResolver.resolveUser(null, 1L)).thenReturn(sampleUser());
        when(budgetService.getPeriodFilters(1L)).thenReturn(List.of(
                BudgetPeriodFilterDto.builder()
                        .id("2026-11")
                        .label("Tháng 11/2026")
                        .summaryHeading("Tổng chi tháng 11")
                        .startDate(LocalDate.of(2026, 11, 1))
                        .endDate(LocalDate.of(2026, 11, 30))
                        .build()));

        mockMvc.perform(get("/api/budgets/periods").header("X-User-Id", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value("2026-11"))
                .andExpect(jsonPath("$[0].label").value("Tháng 11/2026"));
    }

    @Test
    void getBudgetsAndDetailReturnExpectedPayload() throws Exception {
        when(currentUserResolver.resolveUser(1L, null)).thenReturn(sampleUser());
        when(budgetService.getBudgets(1L, "2026-11", null, null, 2L, null))
                .thenReturn(List.of(sampleBudgetResponse()));
        when(budgetService.getBudgetById(1L, 10L)).thenReturn(sampleBudgetResponse());

        mockMvc.perform(get("/api/budgets")
                        .param("userId", "1")
                        .param("periodFilterId", "2026-11")
                        .param("walletId", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].budgetId").value(10))
                .andExpect(jsonPath("$[0].categoryName").value("Ăn uống"))
                .andExpect(jsonPath("$[0].transactions[0].amount").value(-85000.0));

        mockMvc.perform(get("/api/budgets/10").param("userId", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.budgetId").value(10))
                .andExpect(jsonPath("$.walletIds[0]").value(2));
    }

    @Test
    void getBudgetProgressReturnsChartAndMilestones() throws Exception {
        when(currentUserResolver.resolveUser(null, null)).thenReturn(sampleUser());
        when(budgetService.getBudgetProgress(1L, 10L, LocalDate.of(2026, 11, 15)))
                .thenReturn(BudgetProgressResponse.builder()
                        .budgetId(10L)
                        .budgetName("Ăn uống")
                        .categoryName("Ăn uống")
                        .period(BudgetPeriod.MONTH)
                        .startDate(LocalDate.of(2026, 11, 1))
                        .endDate(LocalDate.of(2026, 11, 30))
                        .limitAmount(new BigDecimal("3000000.00"))
                        .spentAmount(new BigDecimal("1800000.00"))
                        .remainingAmount(new BigDecimal("1200000.00"))
                        .overLimitAmount(BigDecimal.ZERO)
                        .progressPercent(60)
                        .alertPercent(new BigDecimal("80.00"))
                        .healthStatus("ON_TRACK")
                        .totalDays(30)
                        .elapsedDays(14)
                        .remainingDays(16)
                        .dailyAverage(new BigDecimal("128571.43"))
                        .dailySuggested(new BigDecimal("75000.00"))
                        .dailySeries(List.of(BudgetDailyPointDto.builder()
                                .date(LocalDate.of(2026, 11, 1))
                                .dailyAmount(new BigDecimal("100000.00"))
                                .cumulativeAmount(new BigDecimal("100000.00"))
                                .build()))
                        .milestones(List.of(BudgetMilestoneDto.builder()
                                .percent(50)
                                .targetAmount(new BigDecimal("1500000.00"))
                                .achievedDate(LocalDate.of(2026, 11, 12))
                                .achieved(true)
                                .build()))
                        .build());

        mockMvc.perform(get("/api/budgets/10/progress").param("referenceDate", "2026-11-15"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.progressPercent").value(60))
                .andExpect(jsonPath("$.healthStatus").value("ON_TRACK"))
                .andExpect(jsonPath("$.milestones[0].achieved").value(true));
    }

    @Test
    void createUpdateAndDeleteBudgetHandleFrontendPayload() throws Exception {
        when(currentUserResolver.resolveUser(null, null)).thenReturn(sampleUser());
        when(budgetService.createBudget(any(User.class), any())).thenReturn(sampleBudgetResponse());
        when(budgetService.updateBudget(eq(1L), eq(10L), any())).thenReturn(sampleBudgetResponse());
        doNothing().when(budgetService).deleteBudget(1L, 10L);

        String frontendCreateJson = """
                {
                  "budgetId": "temp_1",
                  "walletId": "2",
                  "walletIds": ["2", "3"],
                  "categoryId": "5",
                  "budgetName": "Ăn uống",
                  "amount": 3000000,
                  "period": "MONTH",
                  "startDate": "2026-11-01",
                  "endDate": "2026-11-30",
                  "alertPercent": 80,
                  "status": "ACTIVE",
                  "repeatMonthly": true
                }
                """;

        mockMvc.perform(post("/api/budgets")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(frontendCreateJson))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.budgetId").value(10));

        mockMvc.perform(put("/api/budgets/10")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(frontendCreateJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.budgetId").value(10));

        mockMvc.perform(patch("/api/budgets/10")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"amount\": 3500000}"))
                .andExpect(status().isOk());

        mockMvc.perform(delete("/api/budgets/10"))
                .andExpect(status().isNoContent());
    }

    @Test
    void categoriesAndWalletsEndpointsReturnAvailableOptions() throws Exception {
        when(currentUserResolver.resolveUser(null, null)).thenReturn(sampleUser());
        when(categoryService.getAvailableCategories(1L, null)).thenReturn(List.of(
                CategoryDto.builder()
                        .categoryId(5L)
                        .categoryName("Ăn uống")
                        .categoryType(CategoryType.EXPENSE)
                        .isDefault(true)
                        .build()));
        when(walletService.getWallets(1L, null)).thenReturn(List.of(
                WalletOptionDto.builder()
                        .walletId(2L)
                        .walletName("Ví tiền mặt")
                        .balance(new BigDecimal("1200000.00"))
                        .currency("VND")
                        .walletType(WalletType.PERSONAL)
                        .build()));

        mockMvc.perform(get("/api/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].categoryId").value(5))
                .andExpect(jsonPath("$[0].categoryName").value("Ăn uống"));

        mockMvc.perform(get("/api/wallets"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].walletId").value(2))
                .andExpect(jsonPath("$[0].walletName").value("Ví tiền mặt"));
    }

    @Test
    void errorResponseIncludesReadableMessage() throws Exception {
        when(currentUserResolver.resolveUser(null, null)).thenReturn(sampleUser());
        doThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy ngân sách với ID: 999"))
                .when(budgetService).getBudgetById(1L, 999L);

        mockMvc.perform(get("/api/budgets/999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.message").value("Không tìm thấy ngân sách với ID: 999"));

        mockMvc.perform(get("/api/budgets/abc"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.message").exists());

        mockMvc.perform(post("/api/budgets")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{invalid-json"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.message").value("Dữ liệu JSON gửi lên không hợp lệ"));
    }
}
