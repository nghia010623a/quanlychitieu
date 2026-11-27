import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_date_time.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/budget.dart';

/// Chart card for UI-08.6 supporting both `Tích lũy` (cumulative) and `Theo ngày` (daily).
class BudgetProgressChartCard extends StatelessWidget {
  const BudgetProgressChartCard({
    required this.budget,
    required this.isDailyMode,
    super.key,
  });

  final BudgetEntity budget;
  final bool isDailyMode;

  @override
  Widget build(BuildContext context) {
    final series = budget.buildDailySeries();
    final periodLabel = budget.periodSummaryLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.cardBorder,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${budget.category.name} · $periodLabel',
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: 2),
          Text(
            'Đã chi ${CurrencyFormatter.formatVnd(budget.spentAmount)} / ${CurrencyFormatter.formatVnd(budget.limitAmount)}',
            style: AppTypography.captionSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 175,
            width: double.infinity,
            child: CustomPaint(
              painter: isDailyMode
                  ? _DailyBarChartPainter(budget: budget, series: series)
                  : _CumulativeLineChartPainter(budget: budget, series: series),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildAxisDates(),
          const SizedBox(height: AppSpacing.md),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildAxisDates() {
    final total = budget.totalDays;
    final ticks = <DateTime>[
      budget.startDate,
      budget.startDate.add(Duration(days: (total * 0.25).round())),
      budget.startDate.add(Duration(days: (total * 0.48).round())),
      budget.startDate.add(Duration(days: (total * 0.72).round())),
      budget.endDate,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ticks
          .map(
            (date) => Text(
              AppDateTime.formatShortDayMonth(date),
              style: AppTypography.captionSmall,
            ),
          )
          .toList(),
    );
  }

  Widget _buildLegend() {
    if (isDailyMode) {
      return const Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          _LegendItem(color: Color(0xFF3A8FDC), label: 'Chi trong ngày'),
          _LegendItem(color: AppColors.warning, label: 'Vượt gợi ý'),
          _LegendItem(color: AppColors.dangerBright, label: 'Gợi ý/ngày'),
        ],
      );
    }

    return const Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        _LegendItem(color: Color(0xFF3A8FDC), label: 'Thực tế'),
        _LegendItem(color: AppColors.warning, label: 'Dự kiến'),
        _LegendItem(color: AppColors.dangerBright, label: 'Hạn mức'),
        _LegendItem(color: AppColors.placeholder, label: 'Chi đều'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTypography.captionSmall,
        ),
      ],
    );
  }
}

class _CumulativeLineChartPainter extends CustomPainter {
  _CumulativeLineChartPainter({
    required this.budget,
    required this.series,
  });

  final BudgetEntity budget;
  final List<BudgetDailyPoint> series;

  @override
  void paint(Canvas canvas, Size size) {
    const topPadding = 24.0;
    const bottomPadding = 6.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final totalDays = math.max(budget.totalDays - 1, 1);

    final projectedFinal = budget.dailyAverage * budget.totalDays;
    final maxY = math.max(
      budget.limitAmount * 1.18,
      math.max(projectedFinal * 1.05, budget.spentAmount * 1.15),
    );

    double yFor(double value) {
      final ratio = (value / maxY).clamp(0.0, 1.0);
      return topPadding + chartHeight * (1 - ratio);
    }

    double xForDayIndex(int dayIndex) {
      return (dayIndex / totalDays).clamp(0.0, 1.0) * size.width;
    }

    // 1. Limit horizontal dashed red line + label.
    final limitY = yFor(budget.limitAmount);
    _drawDashedLine(
      canvas,
      Offset(0, limitY),
      Offset(size.width, limitY),
      Paint()
        ..color = AppColors.dangerBright
        ..strokeWidth = 1.4,
      dashWidth: 4,
      dashSpace: 4,
    );

    final limitPainter = TextPainter(
      text: TextSpan(
        text: 'Hạn mức ${CurrencyFormatter.formatVnd(budget.limitAmount)}',
        style: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppColors.dangerBright,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    limitPainter.paint(canvas, Offset(0, math.max(0, limitY - 17)));

    // 2. Even pace dashed grey line from 0 to limitAmount at end of period.
    _drawDashedLine(
      canvas,
      Offset(0, yFor(0)),
      Offset(size.width, limitY),
      Paint()
        ..color = AppColors.disabledSurface
        ..strokeWidth = 1.5,
      dashWidth: 4,
      dashSpace: 4,
    );

    // 3. Actual cumulative curve up to today.
    final actualPath = Path();
    final fillPath = Path();
    Offset lastPoint = Offset(0, yFor(0));

    for (var i = 0; i < series.length; i++) {
      final x = xForDayIndex(i);
      final y = yFor(series[i].cumulativeAmount);
      final pt = Offset(x, y);
      if (i == 0) {
        actualPath.moveTo(0, yFor(0));
        actualPath.lineTo(pt.dx, pt.dy);
        fillPath.moveTo(0, yFor(0));
        fillPath.lineTo(pt.dx, pt.dy);
      } else {
        actualPath.lineTo(pt.dx, pt.dy);
        fillPath.lineTo(pt.dx, pt.dy);
      }
      lastPoint = pt;
    }

    fillPath.lineTo(lastPoint.dx, topPadding + chartHeight);
    fillPath.lineTo(0, topPadding + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.28),
          AppColors.primary.withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Subtle vertical guide at today.
    _drawDashedLine(
      canvas,
      Offset(lastPoint.dx, lastPoint.dy),
      Offset(lastPoint.dx, topPadding + chartHeight),
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.5)
        ..strokeWidth = 1,
      dashWidth: 3,
      dashSpace: 3,
    );

    // 4. Projected dashed amber curve from today to end of period.
    final endProjectedY = yFor(projectedFinal);
    _drawDashedLine(
      canvas,
      lastPoint,
      Offset(size.width, endProjectedY),
      Paint()
        ..color = AppColors.warning
        ..strokeWidth = 2.2,
      dashWidth: 4,
      dashSpace: 4,
    );

    // Actual blue line drawn on top.
    canvas.drawPath(
      actualPath,
      Paint()
        ..color = const Color(0xFF2B7FD4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Today dot + label.
    canvas.drawCircle(
      lastPoint,
      5.5,
      Paint()..color = AppColors.white,
    );
    canvas.drawCircle(
      lastPoint,
      5.5,
      Paint()
        ..color = const Color(0xFF2B7FD4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final todayLabel = TextPainter(
      text: const TextSpan(
        text: 'Hôm nay',
        style: TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3A8FDC),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelX = (lastPoint.dx - todayLabel.width / 2)
        .clamp(0.0, size.width - todayLabel.width);
    final labelY = math.min(lastPoint.dy + 16, topPadding + chartHeight - 16);
    todayLabel.paint(canvas, Offset(labelX, labelY));
  }

  @override
  bool shouldRepaint(covariant _CumulativeLineChartPainter oldDelegate) {
    return oldDelegate.budget.id != budget.id ||
        oldDelegate.budget.spentAmount != budget.spentAmount ||
        oldDelegate.budget.limitAmount != budget.limitAmount;
  }
}

class _DailyBarChartPainter extends CustomPainter {
  _DailyBarChartPainter({
    required this.budget,
    required this.series,
  });

  final BudgetEntity budget;
  final List<BudgetDailyPoint> series;

  @override
  void paint(Canvas canvas, Size size) {
    const topPadding = 22.0;
    const bottomPadding = 6.0;
    final chartHeight = size.height - topPadding - bottomPadding;

    final dailyCap = budget.dailySuggested > 0
        ? budget.dailySuggested
        : (budget.limitAmount / math.max(budget.totalDays, 1));
    final maxDaily = series.fold<double>(
      dailyCap * 1.25,
      (prev, p) => math.max(prev, p.dailyAmount * 1.15),
    );

    double yFor(double value) {
      final ratio = (value / maxDaily).clamp(0.0, 1.0);
      return topPadding + chartHeight * (1 - ratio);
    }

    final slotWidth = size.width / math.max(budget.totalDays, 1);
    final barWidth = math.max(4.0, slotWidth * 0.55);

    for (var i = 0; i < series.length; i++) {
      final value = series[i].dailyAmount;
      final top = yFor(value);
      final bottom = topPadding + chartHeight;
      final left = i * slotWidth + (slotWidth - barWidth) / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, top, left + barWidth, bottom),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      final color = value > dailyCap
          ? AppColors.warning
          : const Color(0xFF3A8FDC);
      canvas.drawRRect(rect, Paint()..color = color);
    }

    final guideY = yFor(dailyCap);
    _drawDashedLine(
      canvas,
      Offset(0, guideY),
      Offset(size.width, guideY),
      Paint()
        ..color = AppColors.dangerBright
        ..strokeWidth = 1.4,
      dashWidth: 4,
      dashSpace: 4,
    );

    final guideText = TextPainter(
      text: TextSpan(
        text: 'Gợi ý ${CurrencyFormatter.formatVnd(dailyCap)}/ngày',
        style: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppColors.dangerBright,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    guideText.paint(canvas, Offset(0, math.max(0, guideY - 17)));
  }

  @override
  bool shouldRepaint(covariant _DailyBarChartPainter oldDelegate) {
    return oldDelegate.budget.id != budget.id ||
        oldDelegate.series.length != series.length;
  }
}

void _drawDashedLine(
  Canvas canvas,
  Offset start,
  Offset end,
  Paint paint, {
  double dashWidth = 5,
  double dashSpace = 4,
}) {
  final dx = end.dx - start.dx;
  final dy = end.dy - start.dy;
  final distance = math.sqrt(dx * dx + dy * dy);
  if (distance <= 0) return;

  final ux = dx / distance;
  final uy = dy / distance;
  var progress = 0.0;
  while (progress < distance) {
    final next = math.min(progress + dashWidth, distance);
    canvas.drawLine(
      Offset(start.dx + ux * progress, start.dy + uy * progress),
      Offset(start.dx + ux * next, start.dy + uy * next),
      paint,
    );
    progress += dashWidth + dashSpace;
  }
}
