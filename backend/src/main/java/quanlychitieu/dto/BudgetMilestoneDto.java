package quanlychitieu.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class BudgetMilestoneDto {

    private int percent;
    private BigDecimal targetAmount;
    private LocalDate achievedDate;
    private LocalDate projectedDate;
    private boolean achieved;
}
