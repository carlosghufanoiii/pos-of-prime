import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// Service for automatic uploads to Google Drive
class GoogleDriveService {
  static const String _targetFolderId = '1IFV7gV4PK2xgOIRh2ZmJ8Xy470Oh_Jzq';
  static const List<String> _driveScopes = [drive.DriveApi.driveFileScope];

  static GoogleDriveService? _instance;
  static GoogleDriveService get instance =>
      _instance ??= GoogleDriveService._();

  GoogleDriveService._();

  drive.DriveApi? _driveApi;
  GoogleSignIn? _googleSignIn;
  bool _isInitialized = false;

  /// Initialize Google Drive service
  Future<bool> initialize() async {
    try {
      Logger.info('🔧 Initializing Google Drive service', tag: 'GoogleDrive');

      _googleSignIn = GoogleSignIn(scopes: _driveScopes);

      _isInitialized = true;
      Logger.info('✅ Google Drive service initialized', tag: 'GoogleDrive');
      return true;
    } catch (e) {
      Logger.error(
        '❌ Failed to initialize Google Drive service',
        error: e,
        tag: 'GoogleDrive',
      );
      return false;
    }
  }

  /// Sign in and authenticate with Google Drive
  Future<bool> authenticate() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      Logger.info('🔐 Authenticating with Google Drive', tag: 'GoogleDrive');

      // Sign in with Google
      final account = await _googleSignIn!.signIn();
      if (account == null) {
        Logger.warning('❌ Google sign-in cancelled', tag: 'GoogleDrive');
        return false;
      }

      // Get authentication headers
      final authHeaders = await account.authHeaders;
      final authenticatedClient = AuthenticatedClient(
        http.Client(),
        authHeaders,
      );

      // Create Drive API client
      _driveApi = drive.DriveApi(authenticatedClient);

      Logger.info(
        '✅ Google Drive authentication successful',
        tag: 'GoogleDrive',
      );
      return true;
    } catch (e) {
      Logger.error(
        '❌ Google Drive authentication failed',
        error: e,
        tag: 'GoogleDrive',
      );
      return false;
    }
  }

  /// Check if authenticated and ready to upload
  bool get isAuthenticated => _driveApi != null;

  /// Upload Excel file to Google Drive
  Future<String?> uploadExcelFile(
    String filePath,
    String fileName, {
    String? description,
  }) async {
    try {
      if (!isAuthenticated) {
        final authenticated = await authenticate();
        if (!authenticated) {
          throw Exception('Failed to authenticate with Google Drive');
        }
      }

      Logger.info('📤 Uploading Excel file: $fileName', tag: 'GoogleDrive');

      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File not found: $filePath');
      }

      // Create Drive file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..description =
            description ??
            'Prime POS Excel Export - ${DateTime.now().toIso8601String()}'
        ..parents = [_targetFolderId]
        ..mimeType =
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      // Read file contents
      final fileContents = file.readAsBytesSync();
      final media = drive.Media(
        Stream.fromIterable([fileContents]),
        fileContents.length,
      );

      // Upload to Google Drive
      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      final fileId = uploadedFile.id;
      final driveUrl = 'https://drive.google.com/file/d/$fileId/view';

      Logger.info(
        '✅ Excel file uploaded successfully: $fileName',
        tag: 'GoogleDrive',
      );
      Logger.info('🔗 Drive URL: $driveUrl', tag: 'GoogleDrive');

      return driveUrl;
    } catch (e) {
      Logger.error(
        '❌ Failed to upload Excel file: $fileName',
        error: e,
        tag: 'GoogleDrive',
      );
      return null;
    }
  }

  /// Upload backup file to Google Drive
  Future<String?> uploadBackupFile(
    String filePath,
    String fileName, {
    String? description,
  }) async {
    try {
      if (!isAuthenticated) {
        final authenticated = await authenticate();
        if (!authenticated) {
          throw Exception('Failed to authenticate with Google Drive');
        }
      }

      Logger.info('📤 Uploading backup file: $fileName', tag: 'GoogleDrive');

      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File not found: $filePath');
      }

      // Create Drive file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..description =
            description ??
            'Prime POS Automatic Backup - ${DateTime.now().toIso8601String()}'
        ..parents = [_targetFolderId]
        ..mimeType = 'application/json';

      // Read file contents
      final fileContents = file.readAsBytesSync();
      final media = drive.Media(
        Stream.fromIterable([fileContents]),
        fileContents.length,
      );

      // Upload to Google Drive
      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      final fileId = uploadedFile.id;
      final driveUrl = 'https://drive.google.com/file/d/$fileId/view';

      Logger.info(
        '✅ Backup file uploaded successfully: $fileName',
        tag: 'GoogleDrive',
      );
      Logger.info('🔗 Drive URL: $driveUrl', tag: 'GoogleDrive');

      return driveUrl;
    } catch (e) {
      Logger.error(
        '❌ Failed to upload backup file: $fileName',
        error: e,
        tag: 'GoogleDrive',
      );
      return null;
    }
  }

  /// Upload CSV file to Google Drive
  Future<String?> uploadCSVFile(
    String filePath,
    String fileName, {
    String? description,
  }) async {
    try {
      if (!isAuthenticated) {
        final authenticated = await authenticate();
        if (!authenticated) {
          throw Exception('Failed to authenticate with Google Drive');
        }
      }

      Logger.info('📤 Uploading CSV file: $fileName', tag: 'GoogleDrive');

      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File not found: $filePath');
      }

      // Create Drive file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..description =
            description ??
            'Prime POS CSV Export - ${DateTime.now().toIso8601String()}'
        ..parents = [_targetFolderId]
        ..mimeType = 'text/csv';

      // Read file contents
      final fileContents = file.readAsBytesSync();
      final media = drive.Media(
        Stream.fromIterable([fileContents]),
        fileContents.length,
      );

      // Upload to Google Drive
      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      final fileId = uploadedFile.id;
      final driveUrl = 'https://drive.google.com/file/d/$fileId/view';

      Logger.info(
        '✅ CSV file uploaded successfully: $fileName',
        tag: 'GoogleDrive',
      );
      Logger.info('🔗 Drive URL: $driveUrl', tag: 'GoogleDrive');

      return driveUrl;
    } catch (e) {
      Logger.error(
        '❌ Failed to upload CSV file: $fileName',
        error: e,
        tag: 'GoogleDrive',
      );
      return null;
    }
  }

  /// Schedule automatic nightly backup upload
  Future<bool> scheduleNightlyBackup({
    required Future<String> Function() backupGenerator,
  }) async {
    try {
      Logger.info('⏰ Scheduling nightly backup upload', tag: 'GoogleDrive');

      // Calculate time until next 2 AM
      final now = DateTime.now();
      var nextBackup = DateTime(now.year, now.month, now.day, 2, 0, 0);

      // If it's past 2 AM today, schedule for tomorrow
      if (now.isAfter(nextBackup)) {
        nextBackup = nextBackup.add(const Duration(days: 1));
      }

      final timeUntilBackup = nextBackup.difference(now);

      Logger.info(
        '⏰ Next backup scheduled for: ${nextBackup.toLocal()}',
        tag: 'GoogleDrive',
      );
      Logger.info(
        '⏰ Time until backup: ${timeUntilBackup.inHours}h ${timeUntilBackup.inMinutes % 60}m',
        tag: 'GoogleDrive',
      );

      // Schedule the backup
      Future.delayed(timeUntilBackup, () async {
        await _performNightlyBackup(backupGenerator);

        // Schedule next backup (24 hours later)
        _scheduleNextBackup(backupGenerator);
      });

      return true;
    } catch (e) {
      Logger.error(
        '❌ Failed to schedule nightly backup',
        error: e,
        tag: 'GoogleDrive',
      );
      return false;
    }
  }

  /// Perform the actual nightly backup
  Future<void> _performNightlyBackup(
    Future<String> Function() backupGenerator,
  ) async {
    try {
      Logger.info('🌙 Performing nightly backup upload', tag: 'GoogleDrive');

      // Generate backup file
      final backupFilePath = await backupGenerator();
      final fileName = backupFilePath.split('/').last;

      // Upload to Google Drive
      final driveUrl = await uploadBackupFile(
        backupFilePath,
        fileName,
        description: 'Automated nightly backup - ${DateTime.now().toLocal()}',
      );

      if (driveUrl != null) {
        Logger.info(
          '✅ Nightly backup uploaded successfully',
          tag: 'GoogleDrive',
        );

        // Clean up local backup file to save space
        final file = File(backupFilePath);
        if (file.existsSync()) {
          await file.delete();
          Logger.info('🗑️ Local backup file cleaned up', tag: 'GoogleDrive');
        }
      } else {
        Logger.warning('⚠️ Nightly backup upload failed', tag: 'GoogleDrive');
      }
    } catch (e) {
      Logger.error(
        '❌ Nightly backup upload failed',
        error: e,
        tag: 'GoogleDrive',
      );
    }
  }

  /// Schedule the next backup (recursive scheduling)
  void _scheduleNextBackup(Future<String> Function() backupGenerator) {
    Future.delayed(const Duration(hours: 24), () async {
      await _performNightlyBackup(backupGenerator);
      _scheduleNextBackup(backupGenerator);
    });
  }

  /// List files in the target folder
  Future<List<drive.File>> listBackupFiles() async {
    try {
      if (!isAuthenticated) {
        final authenticated = await authenticate();
        if (!authenticated) {
          throw Exception('Failed to authenticate with Google Drive');
        }
      }

      Logger.info('📋 Listing backup files from Drive', tag: 'GoogleDrive');

      final response = await _driveApi!.files.list(
        q: "'$_targetFolderId' in parents and trashed=false",
        orderBy: 'createdTime desc',
        $fields: 'files(id,name,createdTime,size,mimeType,description)',
      );

      final files = response.files ?? [];

      Logger.info(
        '📋 Found ${files.length} files in backup folder',
        tag: 'GoogleDrive',
      );

      return files;
    } catch (e) {
      Logger.error(
        '❌ Failed to list backup files',
        error: e,
        tag: 'GoogleDrive',
      );
      return [];
    }
  }

  /// Clean up old backup files (keep only last 30 days)
  Future<bool> cleanupOldBackups() async {
    try {
      Logger.info('🧹 Cleaning up old backup files', tag: 'GoogleDrive');

      final files = await listBackupFiles();
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      int deletedCount = 0;

      for (final file in files) {
        final createdTime = file.createdTime;
        if (createdTime != null && createdTime.isBefore(thirtyDaysAgo)) {
          try {
            await _driveApi!.files.delete(file.id!);
            deletedCount++;
            Logger.info(
              '🗑️ Deleted old backup: ${file.name}',
              tag: 'GoogleDrive',
            );
          } catch (e) {
            Logger.warning(
              '⚠️ Failed to delete ${file.name}: $e',
              tag: 'GoogleDrive',
            );
          }
        }
      }

      Logger.info(
        '✅ Cleanup complete. Deleted $deletedCount old files',
        tag: 'GoogleDrive',
      );
      return true;
    } catch (e) {
      Logger.error(
        '❌ Failed to cleanup old backups',
        error: e,
        tag: 'GoogleDrive',
      );
      return false;
    }
  }

  /// Sign out from Google Drive
  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
      _driveApi = null;
      Logger.info('👋 Signed out from Google Drive', tag: 'GoogleDrive');
    } catch (e) {
      Logger.error(
        '❌ Error signing out from Google Drive',
        error: e,
        tag: 'GoogleDrive',
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _driveApi = null;
    _googleSignIn = null;
    _isInitialized = false;
  }
}

/// Authenticated HTTP client for Google APIs
class AuthenticatedClient extends http.BaseClient {
  final http.Client _client;
  final Map<String, String> _headers;

  AuthenticatedClient(this._client, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() => _client.close();
}
