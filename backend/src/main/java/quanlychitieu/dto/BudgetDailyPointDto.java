package quanlychitieu.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class BudgetDailyPointDto {

    private LocalDate date;
    private BigDecimal dailyAmount;
    private BigDecimal cumulativeAmount;
}
