// lib/core/services/google_drive_service.dart
import 'dart:convert';
import 'dart:io';

import 'google_auth_service.dart';

class GoogleDriveService {
  GoogleDriveService._();
  static final instance = GoogleDriveService._();

  final _client = HttpClient();

  Future<String?> _getAccessToken() async {
    return await GoogleAuthService.instance.getAccessToken();
  }

  /// Uploads or updates the file 'vaultix_backup.enc' in the appDataFolder.
  Future<bool> uploadBackup(String encryptedData) async {
    final token = await _getAccessToken();
    if (token == null) return false;

    try {
      final existingFileId = await _findBackupFileId(token);

      if (existingFileId != null) {
        final uri = Uri.parse('https://www.googleapis.com/upload/drive/v3/files/$existingFileId?uploadType=media');
        final request = await _client.patchUrl(uri);
        request.headers.set('Authorization', 'Bearer $token');
        request.headers.set('Content-Type', 'text/plain');
        request.write(encryptedData);
        final response = await request.close();
        if (response.statusCode != 200) {
          final body = await response.transform(utf8.decoder).join();
          print('GoogleDriveService update error: ${response.statusCode} - $body');
        }
        return response.statusCode == 200;
      }

      final boundary = 'vaultix_boundary_${DateTime.now().microsecondsSinceEpoch}';
      final uri = Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id',
      );
      final request = await _client.postUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'multipart/related; boundary=$boundary');

      final metadata = jsonEncode({
        'name': 'vaultix_backup.enc',
        'parents': ['appDataFolder'],
      });

      request.write('--$boundary\r\n');
      request.write('Content-Type: application/json; charset=UTF-8\r\n\r\n');
      request.write(metadata);
      request.write('\r\n--$boundary\r\n');
      request.write('Content-Type: text/plain\r\n\r\n');
      request.write(encryptedData);
      request.write('\r\n--$boundary--');

      final response = await request.close();
      if (response.statusCode != 200 && response.statusCode != 201) {
        final body = await response.transform(utf8.decoder).join();
        print('GoogleDriveService upload error: ${response.statusCode} - $body');
      }
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, st) {
      print('GoogleDriveService exception: $e\n$st');
      return false;
    }
  }

  /// Deletes the backup file from Google Drive if it exists
  Future<bool> deleteBackup() async {
    final token = await _getAccessToken();
    if (token == null) return false;
    
    try {
      final existingFileId = await _findBackupFileId(token);
      if (existingFileId == null) return true; // Already doesn't exist
      
      final uri = Uri.parse('https://www.googleapis.com/drive/v3/files/$existingFileId');
      final request = await _client.deleteUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      
      final response = await request.close();
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// Downloads the content of 'vaultix_backup.enc' from appDataFolder.
  Future<String?> downloadBackup() async {
    final token = await _getAccessToken();
    if (token == null) return null;

    try {
      final fileId = await _findBackupFileId(token);
      if (fileId == null) return null;

      final uri = Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media');
      final request = await _client.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      final response = await request.close();
      if (response.statusCode == 200) {
        return await response.transform(utf8.decoder).join();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _findBackupFileId(String token) async {
    try {
      final query = Uri.encodeComponent("name = 'vaultix_backup.enc' and 'appDataFolder' in parents and trashed = false");
      final uri = Uri.parse(
        'https://www.googleapis.com/drive/v3/files?spaces=appDataFolder&fields=files(id,name)&q=$query',
      );
      
      final request = await _client.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body);
        final files = json['files'] as List<dynamic>;
        if (files.isNotEmpty) {
          return files.first['id'] as String;
        }
      } else {
        final body = await response.transform(utf8.decoder).join();
        print('GoogleDriveService _findBackupFileId error: ${response.statusCode} - $body');
      }
    } catch (e, st) {
      print('GoogleDriveService _findBackupFileId exception: $e\n$st');
    }
    return null;
  }
}
