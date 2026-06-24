import '../database/database_helper.dart';
import '../models/leads_model.dart';

class ReportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Fetch all leads with details
  Future<List<LeadsModel>> getLeadsWithDetails() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT l.*, w.nama_wilayah, s.nama_sumber
      FROM leads l
      JOIN wilayah w ON l.wilayah_id = w.id
      JOIN sumber_leads s ON l.sumber_id = s.id
      ORDER BY l.tanggal DESC, l.id DESC
    ''');
    return List.generate(maps.length, (i) => LeadsModel.fromMap(maps[i]));
  }

  // Fetch filtered leads
  Future<List<LeadsModel>> getFilteredLeads({
    String? startDate,
    String? endDate,
    int? wilayahId,
    int? sumberId,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += ' AND l.tanggal >= ?';
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      whereClause += ' AND l.tanggal <= ?';
      whereArgs.add(endDate);
    }
    if (wilayahId != null) {
      whereClause += ' AND l.wilayah_id = ?';
      whereArgs.add(wilayahId);
    }
    if (sumberId != null) {
      whereClause += ' AND l.sumber_id = ?';
      whereArgs.add(sumberId);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT l.*, w.nama_wilayah, s.nama_sumber
      FROM leads l
      JOIN wilayah w ON l.wilayah_id = w.id
      JOIN sumber_leads s ON l.sumber_id = s.id
      WHERE $whereClause
      ORDER BY l.tanggal DESC, l.id DESC
    ''', whereArgs);

    return List.generate(maps.length, (i) => LeadsModel.fromMap(maps[i]));
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final todayStr = _formatDate(now);
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}-%';
    final yearPrefix = '${now.year}-%';

    // Today's total
    final todayRes = await db.rawQuery('SELECT SUM(jumlah) as total FROM leads WHERE tanggal = ?', [todayStr]);
    final todayTotal = todayRes.first['total'] as int? ?? 0;

    // Month's total
    final monthRes = await db.rawQuery('SELECT SUM(jumlah) as total FROM leads WHERE tanggal LIKE ?', [monthPrefix]);
    final monthTotal = monthRes.first['total'] as int? ?? 0;

    // Year's total
    final yearRes = await db.rawQuery('SELECT SUM(jumlah) as total FROM leads WHERE tanggal LIKE ?', [yearPrefix]);
    final yearTotal = yearRes.first['total'] as int? ?? 0;

    // Best Wilayah
    final bestWilayahRes = await db.rawQuery('''
      SELECT w.nama_wilayah, SUM(l.jumlah) as total
      FROM leads l
      JOIN wilayah w ON l.wilayah_id = w.id
      GROUP BY l.wilayah_id
      ORDER BY total DESC LIMIT 1
    ''');
    final bestWilayah = bestWilayahRes.isNotEmpty ? bestWilayahRes.first['nama_wilayah'] as String : '-';

    // Best Sumber
    final bestSumberRes = await db.rawQuery('''
      SELECT s.nama_sumber, SUM(l.jumlah) as total
      FROM leads l
      JOIN sumber_leads s ON l.sumber_id = s.id
      GROUP BY l.sumber_id
      ORDER BY total DESC LIMIT 1
    ''');
    final bestSumber = bestSumberRes.isNotEmpty ? bestSumberRes.first['nama_sumber'] as String : '-';

    // Daily trend (last 7 days)
    List<String> dates = [];
    for (int i = 6; i >= 0; i--) {
      dates.add(_formatDate(now.subtract(Duration(days: i))));
    }

    List<Map<String, dynamic>> dailyTrend = [];
    for (final d in dates) {
      final res = await db.rawQuery('SELECT SUM(jumlah) as total FROM leads WHERE tanggal = ?', [d]);
      final total = res.first['total'] as int? ?? 0;
      final parts = d.split('-');
      final shortDate = '${parts[2]}/${parts[1]}';
      dailyTrend.add({
        'date': d,
        'label': shortDate,
        'total': total,
      });
    }

    // Top Wilayah (Bar Chart Data)
    final wilayahChartRes = await db.rawQuery('''
      SELECT w.nama_wilayah, SUM(l.jumlah) as total
      FROM leads l
      JOIN wilayah w ON l.wilayah_id = w.id
      GROUP BY l.wilayah_id
      ORDER BY total DESC
    ''');
    
    // Top Sumber (Pie Chart Data)
    final sumberChartRes = await db.rawQuery('''
      SELECT s.nama_sumber, SUM(l.jumlah) as total
      FROM leads l
      JOIN sumber_leads s ON l.sumber_id = s.id
      GROUP BY l.sumber_id
      ORDER BY total DESC
    ''');

    return {
      'today_total': todayTotal,
      'month_total': monthTotal,
      'year_total': yearTotal,
      'best_wilayah': bestWilayah,
      'best_sumber': bestSumber,
      'daily_trend': dailyTrend,
      'wilayah_chart': wilayahChartRes,
      'sumber_chart': sumberChartRes,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
