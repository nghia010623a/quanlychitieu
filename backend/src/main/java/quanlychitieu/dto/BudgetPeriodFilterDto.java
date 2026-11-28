package quanlychitieu.dto;

import java.time.LocalDate;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class BudgetPeriodFilterDto {

    private String id;
    private String label;
    private String summaryHeading;
    private LocalDate startDate;
    private LocalDate endDate;
}
