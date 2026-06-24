import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/backup_service.dart';
import '../services/restore_service.dart';

class SettingsProvider extends ChangeNotifier {
  final BackupService _backupService = BackupService();
  final RestoreService _restoreService = RestoreService();

  bool _isOperating = false;
  bool get isOperating => _isOperating;

  Future<String?> runBackup() async {
    _isOperating = true;
    notifyListeners();

    try {
      final path = await _backupService.generateBackup();
      if (path != null) {
        await _backupService.shareBackupFile(path);
        return path;
      }
      return null;
    } catch (e) {
      print('Backup error: $e');
      return null;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // Choose JSON file and validate structure. Returns parsed map or throws an exception.
  Future<Map<String, dynamic>?> pickAndValidateBackup() async {
    _isOperating = true;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return null; // Cancelled by user
      }

      final path = result.files.single.path!;
      final validatedData = await _restoreService.parseAndValidateBackup(path);
      return validatedData;
    } catch (e) {
      print('Restore validation error: $e');
      rethrow;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  Future<bool> executeRestore(Map<String, dynamic> backupData) async {
    _isOperating = true;
    notifyListeners();

    try {
      await _restoreService.restoreBackup(backupData);
      return true;
    } catch (e) {
      print('Execute restore error: $e');
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }
}
