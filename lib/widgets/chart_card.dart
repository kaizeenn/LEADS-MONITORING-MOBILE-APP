import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final Widget chart;

  const ChartCard({
    super.key,
    required this.title,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: chart,
          ),
        ],
      ),
    );
  }
}

// 1. Daily Trend Line Chart
class DailyTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const DailyTrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Tidak ada data'));
    }

    final double maxVal = data.map((e) => (e['total'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
    final double maxY = maxVal > 0 ? maxVal * 1.2 : 10;

    final spots = List.generate(data.length, (i) {
      final val = (data[i]['total'] as num).toDouble();
      return FlSpot(i.toDouble(), val);
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color(0xFFE2E8F0),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < data.length) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      data[idx]['label'] as String,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4.5,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: AppColors.primary,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. Wilayah Bar Chart
class WilayahBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const WilayahBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Tidak ada data'));
    }

    // Limit to top 5
    final displayData = data.take(5).toList();

    final double maxVal = displayData.map((e) => (e['total'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
    final double maxY = maxVal > 0 ? maxVal * 1.2 : 10;

    final barGroups = List.generate(displayData.length, (i) {
      final val = (displayData[i]['total'] as num).toDouble();
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: val,
            gradient: const LinearGradient(
              colors: [AppColors.secondary, Color(0xFF289894)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: const Color(0xFFF1F5F9),
            ),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < displayData.length) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      displayData[idx]['nama_wilayah'] as String,
                      style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color(0xFFE2E8F0),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}

// 3. Sumber Pie Chart
class SumberPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const SumberPieChart({super.key, required this.data});

  static const List<Color> _chartColors = [
    Color(0xFF0F4C81),
    Color(0xFF3AAFA9),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
    Color(0xFF3F51B5),
    Color(0xFF00BCD4),
    Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Tidak ada data'));
    }

    final double totalSum = data.map((e) => (e['total'] as num).toDouble()).reduce((a, b) => a + b);
    final displayData = data.take(5).toList(); // Take top 5

    // Add "Lainnya" if more than 5
    if (data.length > 5) {
      final double otherSum = data.skip(5).map((e) => (e['total'] as num).toDouble()).reduce((a, b) => a + b);
      if (otherSum > 0) {
        displayData.add({'nama_sumber': 'Lainnya', 'total': otherSum});
      }
    }

    final List<PieChartSectionData> sections = List.generate(displayData.length, (i) {
      final val = (displayData[i]['total'] as num).toDouble();
      final double percentage = totalSum > 0 ? (val / totalSum) * 100 : 0;
      final color = _chartColors[i % _chartColors.length];

      return PieChartSectionData(
        color: color,
        value: val,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 26,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 36,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(displayData.length, (i) {
                final name = displayData[i]['nama_sumber'] as String;
                final val = displayData[i]['total'] as num;
                final color = _chartColors[i % _chartColors.length];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$name ($val)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
