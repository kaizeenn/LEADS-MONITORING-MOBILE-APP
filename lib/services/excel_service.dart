import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/leads_model.dart';
import 'package:intl/intl.dart';

class ExcelService {
  Future<String?> exportToExcel(
    List<LeadsModel> leads,
    Map<String, dynamic> summaryStats,
  ) async {
    try {
      var excel = Excel.createExcel();
      
      // Rename default sheet to 'Detail Leads' so it is the first tab the user sees
      String defaultSheet = 'Sheet1';
      excel.rename(defaultSheet, 'Detail Leads');
      
      // Colors definitions to match the screenshot
      final ExcelColor headerBg = ExcelColor.fromHexString('#F2F2F2');
      final ExcelColor blackText = ExcelColor.fromHexString('#000000');
      final ExcelColor darkText = ExcelColor.fromHexString('#333333');
      final ExcelColor borderGray = ExcelColor.fromHexString('#E0E0E0');
      final ExcelColor whiteBg = ExcelColor.fromHexString('#FFFFFF');
      final ExcelColor greyText = ExcelColor.fromHexString('#595959');

      // Subtle horizontal border
      final borderThin = Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: borderGray,
      );

      // Styles
      final CellStyle titleStyle = CellStyle(
        bold: true,
        fontSize: 13,
        fontColorHex: blackText,
      );

      final CellStyle metaStyle = CellStyle(
        italic: true,
        fontSize: 9,
        fontColorHex: greyText,
      );

      final CellStyle headerStyle = CellStyle(
        bold: true,
        fontColorHex: blackText,
        backgroundColorHex: headerBg,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: borderThin,
      );

      final CellStyle dataNormalStyle = CellStyle(
        fontColorHex: darkText,
        backgroundColorHex: whiteBg,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: borderThin,
      );

      final CellStyle dataBoldStyle = CellStyle(
        bold: true,
        fontColorHex: blackText,
        backgroundColorHex: whiteBg,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: borderThin,
      );

      final CellStyle totalRowStyle = CellStyle(
        bold: true,
        fontColorHex: blackText,
        backgroundColorHex: headerBg,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        topBorder: borderThin,
        bottomBorder: borderThin,
      );

      // Helper function to write cell with style
      void writeCell(Sheet sheet, int col, int row, CellValue value, CellStyle style) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.value = value;
        cell.cellStyle = style;
      }

      // Date formatter helper (e.g., formats '2026-06-23' to '23/06/26')
      String formatDate(String dateStr) {
        try {
          final parsed = DateTime.parse(dateStr);
          return DateFormat('dd/MM/yy').format(parsed);
        } catch (_) {
          return dateStr;
        }
      }

      // --- Sheet 1: Detail Leads (First Tab) ---
      Sheet detailSheet = excel['Detail Leads'];
      int dr = 0;
      
      // Headers (exactly matching the screenshot layout but without Sumber)
      final detailHeaders = ['Tanggal \u2193', 'Wilayah', 'Jumlah'];
      for (int c = 0; c < detailHeaders.length; c++) {
        writeCell(detailSheet, c, dr, TextCellValue(detailHeaders[c]), headerStyle);
      }
      dr++;
      
      // Data Rows
      int totalLeadsSum = 0;
      for (int i = 0; i < leads.length; i++) {
        final lead = leads[i];
        
        writeCell(detailSheet, 0, dr, TextCellValue(formatDate(lead.tanggal)), dataNormalStyle);
        writeCell(detailSheet, 1, dr, TextCellValue(lead.namaWilayah ?? '-'), dataNormalStyle);
        writeCell(detailSheet, 2, dr, IntCellValue(lead.jumlah), dataBoldStyle);
        totalLeadsSum += lead.jumlah;
        dr++;
      }

      // Add Total Row at the bottom of Detail Leads sheet
      writeCell(detailSheet, 0, dr, TextCellValue('Total'), totalRowStyle);
      writeCell(detailSheet, 1, dr, TextCellValue(''), totalRowStyle);
      writeCell(detailSheet, 2, dr, IntCellValue(totalLeadsSum), totalRowStyle);
      
      // --- Sheet 2: Laporan Menyamping (Second Tab) ---
      if (leads.isNotEmpty) {
        Sheet matrixSheet = excel['Laporan Menyamping'];
        int mr = 0;

        // Get unique sorted dates
        final List<String> sortedDates = leads.map((l) => l.tanggal).toSet().toList()..sort();
        
        // Get unique wilayah names
        final Set<String> wilayahNames = leads.map((l) => l.namaWilayah ?? 'Unknown').toSet();

        // Populate matrix map
        final Map<String, Map<String, int>> matrix = {};
        for (var w in wilayahNames) {
          matrix[w] = { for (var d in sortedDates) d : 0 };
        }
        for (var l in leads) {
          final wName = l.namaWilayah ?? 'Unknown';
          matrix[wName]?[l.tanggal] = (matrix[wName]?[l.tanggal] ?? 0) + l.jumlah;
        }

        // Title
        writeCell(matrixSheet, 0, mr, TextCellValue('LAPORAN HARIAN WILAYAH (MENYAMPING)'), titleStyle);
        mr++;
        writeCell(matrixSheet, 0, mr, TextCellValue('Tanggal Export: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'), metaStyle);
        mr += 2; // Blank row separator

        // Headers
        writeCell(matrixSheet, 0, mr, TextCellValue('Wilayah'), headerStyle);
        for (int c = 0; c < sortedDates.length; c++) {
          final date = sortedDates[c];
          writeCell(matrixSheet, c + 1, mr, TextCellValue(formatDate(date)), headerStyle);
        }
        writeCell(matrixSheet, sortedDates.length + 1, mr, TextCellValue('Total'), headerStyle);
        mr++;

        // Calculate totals
        final Map<String, int> columnTotals = { for (var d in sortedDates) d : 0 };
        int grandTotal = 0;

        for (final wName in matrix.keys) {
          writeCell(matrixSheet, 0, mr, TextCellValue(wName), dataNormalStyle);
          int rowTotal = 0;

          for (int c = 0; c < sortedDates.length; c++) {
            final date = sortedDates[c];
            final count = matrix[wName]?[date] ?? 0;
            writeCell(matrixSheet, c + 1, mr, IntCellValue(count), dataNormalStyle);
            rowTotal += count;
            columnTotals[date] = (columnTotals[date] ?? 0) + count;
          }

          writeCell(matrixSheet, sortedDates.length + 1, mr, IntCellValue(rowTotal), dataBoldStyle);
          grandTotal += rowTotal;
          mr++;
        }

        // Bottom Total Row
        writeCell(matrixSheet, 0, mr, TextCellValue('Total'), totalRowStyle);
        for (int c = 0; c < sortedDates.length; c++) {
          final date = sortedDates[c];
          writeCell(matrixSheet, c + 1, mr, IntCellValue(columnTotals[date] ?? 0), totalRowStyle);
        }
        writeCell(matrixSheet, sortedDates.length + 1, mr, IntCellValue(grandTotal), totalRowStyle);
      }

      // --- Sheet 3: Summary (Third Tab) ---
      Sheet summarySheet = excel['Summary'];
      int r = 0;
      
      // Title
      writeCell(summarySheet, 0, r, TextCellValue('LEADS MONITORING APP - SUMMARY REPORT'), titleStyle);
      r++;
      
      // Date
      writeCell(summarySheet, 0, r, TextCellValue('Tanggal Export: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}'), metaStyle);
      r += 2; // Blank row separator
      
      // Headers
      writeCell(summarySheet, 0, r, TextCellValue('Statistik'), headerStyle);
      writeCell(summarySheet, 1, r, TextCellValue('Nilai'), headerStyle);
      r++;
      
      // Removed 'bestSumber' from summary statistics as requested
      final statsData = [
        {'label': 'Total Leads', 'val': IntCellValue(summaryStats['totalLeads'] as int? ?? 0), 'isNum': true},
        {'label': 'Rata-rata Leads/Hari', 'val': DoubleCellValue(summaryStats['averageLeads'] as double? ?? 0.0), 'isNum': true},
        {'label': 'Total Hari Aktif', 'val': IntCellValue(summaryStats['totalActiveDays'] as int? ?? 0), 'isNum': true},
        {'label': 'Wilayah Terbaik', 'val': TextCellValue(summaryStats['bestWilayah'] as String? ?? '-'), 'isNum': false},
      ];

      for (int i = 0; i < statsData.length; i++) {
        final item = statsData[i];
        final valStyle = item['isNum'] as bool ? dataBoldStyle : dataNormalStyle;

        writeCell(summarySheet, 0, r, TextCellValue(item['label'] as String), dataNormalStyle);
        writeCell(summarySheet, 1, r, item['val'] as CellValue, valStyle);
        r++;
      }
      
      // Auto-fit column widths
      void autoFitColumns(Sheet sheet) {
        for (var col = 0; col < sheet.maxColumns; col++) {
          int maxLen = 0;
          for (var row = 0; row < sheet.maxRows; row++) {
            // Ignore Title and date rows for width calculation on col 0
            if (row < 2 && col == 0) continue;
            
            var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
            if (cell.value != null) {
              String valStr = cell.value.toString();
              if (valStr.length > maxLen) {
                maxLen = valStr.length;
              }
            }
          }
          double width = (maxLen + 4).toDouble();
          if (width < 12) width = 12;
          if (width > 40) width = 40;
          sheet.setColumnWidth(col, width);
        }
      }

      autoFitColumns(excel['Detail Leads']);
      if (leads.isNotEmpty) {
        autoFitColumns(excel['Laporan Menyamping']);
      }
      autoFitColumns(excel['Summary']);
      
      // Save excel
      List<int>? fileBytes = excel.save();
      if (fileBytes == null) return null;
      
      // Get output path
      Directory? directory;
      try {
        if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
          directory = await getDownloadsDirectory();
        }
      } catch (_) {}
      directory ??= await getApplicationDocumentsDirectory();

      String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
      String filePath = '${directory.path}/Leads_Report_$formattedDate.xlsx';
      
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
        
      return filePath;
    } catch (e) {
      print('Error exporting to Excel: $e');
      return null;
    }
  }
}
