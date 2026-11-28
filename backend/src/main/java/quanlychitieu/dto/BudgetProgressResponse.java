package quanlychitieu.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import lombok.Builder;
import lombok.Getter;
import quanlychitieu.enums.BudgetPeriod;

@Getter
@Builder
public class BudgetProgressResponse {

    private Long budgetId;
    private String budgetName;
    private String categoryName;
    private BudgetPeriod period;
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal limitAmount;
    private BigDecimal spentAmount;
    private BigDecimal remainingAmount;
    private BigDecimal overLimitAmount;
    private int progressPercent;
    private BigDecimal alertPercent;
    private String healthStatus;
    private long totalDays;
    private long elapsedDays;
    private long remainingDays;
    private BigDecimal dailyAverage;
    private BigDecimal dailySuggested;
    private LocalDate projectedExhaustionDate;
    private List<BudgetDailyPointDto> dailySeries;
    private List<BudgetMilestoneDto> milestones;
}
