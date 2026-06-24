import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/leads_model.dart';

class PdfService {
  // Helper to build a polished, professional report header
  pw.Widget _buildHeader(String title, String periodText) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1E3A8A),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Periode: $periodText',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'LEADS MONITORING APP',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Tanggal Cetak: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to build modern dashboard stats cards
  pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      height: 52,
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
            ),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
        ],
      ),
    );
  }

  // Helper to build a styled horizontal progress bar chart row
  pw.Widget _buildBarChartRow(String label, int value, double percent, PdfColor barColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Container(
            width: 250,
            height: 12,
            alignment: pw.Alignment.centerLeft,
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF1F5F9),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Container(
              width: 250 * (percent > 0.0 ? percent : 0.001),
              height: 12,
              decoration: pw.BoxDecoration(
                color: barColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              alignment: pw.Alignment.centerRight,
              padding: const pw.EdgeInsets.only(right: 6),
              child: percent > 0.12
                  ? pw.Text(
                      '$value',
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    )
                  : null,
            ),
          ),
          if (percent <= 0.12) ...[
            pw.SizedBox(width: 6),
            pw.Text(
              '$value',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
            ),
          ],
        ],
      ),
    );
  }

  // Helper to build left-bordered section titles
  pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 3),
        ),
      ),
      padding: const pw.EdgeInsets.only(left: 6, top: 1, bottom: 1),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
          color: const PdfColor.fromInt(0xFF1E3A8A),
        ),
      ),
    );
  }

  Future<String?> exportToPdf(
    List<LeadsModel> leads,
    Map<String, dynamic> summaryStats,
    String periodText,
  ) async {
    try {
      final pdf = pw.Document();

      // Prepare Wilayah data for chart (Top 5)
      final Map<String, int> wilayahData = {};
      for (var lead in leads) {
        final name = lead.namaWilayah ?? 'Unknown';
        wilayahData[name] = (wilayahData[name] ?? 0) + lead.jumlah;
      }
      final sortedWilayah = wilayahData.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final int maxWilayahVal = sortedWilayah.isNotEmpty ? sortedWilayah.first.value : 1;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36), // Margins: 0.5 inch / 36pt
          build: (pw.Context context) {
            // Calculate total leads for detail table bottom row
            final totalLeadsSum = leads.fold<int>(0, (sum, l) => sum + l.jumlah);

            return [
              // Header
              _buildHeader('LEADS MONITORING APP - REPORT', periodText),
              pw.SizedBox(height: 15),

              // Statistics Section
              _buildSectionHeader('STATISTIK RINGKASAN'),
              pw.SizedBox(height: 8),
              
              // Statistics Cards (4 columns now as Sumber is removed)
              pw.Row(
                children: [
                  pw.Expanded(child: _buildStatCard('Total Leads', '${summaryStats['totalLeads']}', const PdfColor.fromInt(0xFF1E3A8A))),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: _buildStatCard('Rata-rata/Hari', (summaryStats['averageLeads'] as double).toStringAsFixed(1), const PdfColor.fromInt(0xFF2563EB))),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: _buildStatCard('Hari Aktif', '${summaryStats['totalActiveDays']}', const PdfColor.fromInt(0xFF0D9488))),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: _buildStatCard('Top Wilayah', '${summaryStats['bestWilayah']}', const PdfColor.fromInt(0xFF0F766E))),
                ],
              ),
              pw.SizedBox(height: 20),

              // Horizontal Bar Chart for Wilayah
              _buildSectionHeader('GRAFIK LEADS BERDASARKAN WILAYAH (Top 5)'),
              pw.SizedBox(height: 8),
              ...sortedWilayah.take(5).map((e) {
                final double percent = e.value / maxWilayahVal;
                return _buildBarChartRow(e.key, e.value, percent, const PdfColor.fromInt(0xFF2563EB));
              }),
              pw.SizedBox(height: 20),

              // Detail Table
              _buildSectionHeader('DETAIL DATA LEADS'),
              pw.SizedBox(height: 8),
              pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.5),
                ),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A8A)),
                    children: ['Tanggal', 'Wilayah', 'Jumlah'].map((h) {
                      final isJumlah = h == 'Jumlah';
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            fontSize: 9,
                          ),
                          textAlign: isJumlah ? pw.TextAlign.right : pw.TextAlign.left,
                        ),
                      );
                    }).toList(),
                  ),
                  // Data rows
                  ...List.generate(leads.length, (index) {
                    final l = leads[index];
                    final isOdd = index % 2 == 1;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isOdd ? const PdfColor.fromInt(0xFFF8FAFC) : PdfColors.white,
                      ),
                      children: [
                        l.tanggal,
                        l.namaWilayah ?? '-',
                        l.jumlah.toString(),
                      ].asMap().entries.map((entry) {
                        final colIdx = entry.key;
                        final val = entry.value;
                        final isJumlah = colIdx == 2;
                        return pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: pw.Text(
                            val,
                            style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900),
                            textAlign: isJumlah ? pw.TextAlign.right : pw.TextAlign.left,
                          ),
                        );
                      }).toList(),
                    );
                  }),
                  // Bottom Total row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEF2F6)),
                    children: [
                      'Total',
                      '',
                      totalLeadsSum.toString(),
                    ].asMap().entries.map((entry) {
                      final colIdx = entry.key;
                      final val = entry.value;
                      final isJumlah = colIdx == 2;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: pw.Text(
                          val,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF1E3A8A),
                          ),
                          textAlign: isJumlah ? pw.TextAlign.right : pw.TextAlign.left,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      // If we have leads, add a second page in landscape format specifically for the matrix
      if (leads.isNotEmpty) {
        final List<String> sortedDates = leads.map((l) => l.tanggal).toSet().toList()..sort();
        final Set<String> wilayahNames = leads.map((l) => l.namaWilayah ?? 'Unknown').toSet();

        final Map<String, Map<String, int>> matrix = {};
        for (var w in wilayahNames) {
          matrix[w] = { for (var d in sortedDates) d : 0 };
        }
        for (var l in leads) {
          final wName = l.namaWilayah ?? 'Unknown';
          matrix[wName]?[l.tanggal] = (matrix[wName]?[l.tanggal] ?? 0) + l.jumlah;
        }

        final List<String> pdfHeaders = ['Wilayah'];
        for (final date in sortedDates) {
          final parts = date.split('-');
          final shortDate = parts.length > 2 ? '${parts[2]}/${parts[1]}' : date;
          pdfHeaders.add(shortDate);
        }
        pdfHeaders.add('Total');

        final Map<String, int> columnTotals = { for (var d in sortedDates) d : 0 };
        int grandTotal = 0;

        for (final wName in matrix.keys) {
          for (final date in sortedDates) {
            final count = matrix[wName]?[date] ?? 0;
            columnTotals[date] = (columnTotals[date] ?? 0) + count;
          }
          int rowTotal = matrix[wName]?.values.fold<int>(0, (int sum, int val) => sum + val) ?? 0;
          grandTotal += rowTotal;
        }

        // Determine dynamic font size based on number of columns to prevent text wrap issues
        double matrixFontSize = 8;
        if (pdfHeaders.length > 15) {
          matrixFontSize = 7;
        }
        if (pdfHeaders.length > 25) {
          matrixFontSize = 5.5;
        }
        if (pdfHeaders.length > 35) {
          matrixFontSize = 4.5;
        }

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(36),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeader('LAPORAN HARIAN WILAYAH (MENYAMPING)', periodText),
                  pw.SizedBox(height: 15),
                  pw.Table(
                    border: const pw.TableBorder(
                      horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.5),
                    ),
                    children: [
                      // Header Row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A8A)),
                        children: pdfHeaders.map((header) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                            child: pw.Text(
                              header,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: matrixFontSize,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          );
                        }).toList(),
                      ),
                      // Data Rows
                      ...List.generate(matrix.keys.length, (index) {
                        final wName = matrix.keys.elementAt(index);
                        final isOdd = index % 2 == 1;
                        final List<String> rowData = [wName];
                        int rowTotal = 0;
                        for (final date in sortedDates) {
                          final count = matrix[wName]?[date] ?? 0;
                          rowData.add('$count');
                          rowTotal += count;
                        }
                        rowData.add('$rowTotal');

                        return pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: isOdd ? const PdfColor.fromInt(0xFFF8FAFC) : PdfColors.white,
                          ),
                          children: List.generate(rowData.length, (colIdx) {
                            final val = rowData[colIdx];
                            final isFirst = colIdx == 0;
                            final isLast = colIdx == rowData.length - 1;
                            return pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: pw.Text(
                                val,
                                style: pw.TextStyle(
                                  fontSize: matrixFontSize,
                                  fontWeight: isLast ? pw.FontWeight.bold : pw.FontWeight.normal,
                                  color: isLast ? const PdfColor.fromInt(0xFF1E3A8A) : PdfColors.black,
                                ),
                                textAlign: isFirst ? pw.TextAlign.left : pw.TextAlign.center,
                              ),
                            );
                          }),
                        );
                      }),
                      // Total Row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEF2F6)),
                        children: List.generate(pdfHeaders.length, (colIdx) {
                          final isFirst = colIdx == 0;
                          final isLast = colIdx == pdfHeaders.length - 1;
                          String val = '';
                          if (isFirst) {
                            val = 'Total';
                          } else if (isLast) {
                            val = '$grandTotal';
                          } else {
                            final date = sortedDates[colIdx - 1];
                            val = '${columnTotals[date] ?? 0}';
                          }

                          return pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                            child: pw.Text(
                              val,
                              style: pw.TextStyle(
                                fontSize: matrixFontSize,
                                fontWeight: pw.FontWeight.bold,
                                color: const PdfColor.fromInt(0xFF1E3A8A),
                              ),
                              textAlign: isFirst ? pw.TextAlign.left : pw.TextAlign.center,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      Directory? directory;
      try {
        if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
          directory = await getDownloadsDirectory();
        }
      } catch (_) {}
      directory ??= await getApplicationDocumentsDirectory();

      String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
      String filePath = '${directory.path}/Leads_Report_$formattedDate.pdf';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      print('Error exporting to PDF: $e');
      return null;
    }
  }
}
