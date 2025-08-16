import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import '../constants/appwrite_constants.dart';

class AppwritePingTest extends StatefulWidget {
  const AppwritePingTest({super.key});

  @override
  State<AppwritePingTest> createState() => _AppwritePingTestState();
}

class _AppwritePingTestState extends State<AppwritePingTest> {
  String _status = 'Ready to ping';
  bool _isLoading = false;
  Color _statusColor = Colors.grey;
  Client? _client;

  Future<void> _sendPing() async {
    setState(() {
      _isLoading = true;
      _status = 'Sending ping...';
      _statusColor = Colors.orange;
    });

    try {
      // Initialize Appwrite client
      _client = Client()
          .setEndpoint(AppwriteConstants.APPWRITE_PUBLIC_ENDPOINT)
          .setProject(AppwriteConstants.APPWRITE_PROJECT_ID);

      // Try to get account info (this will ping the server)
      final account = Account(_client!);
      
      try {
        // Try to get current session (will fail if not logged in, but proves connection)
        await account.get();
        setState(() {
          _status = '✅ Ping successful! Appwrite connected and user session found.';
          _statusColor = Colors.green;
          _isLoading = false;
        });
      } catch (e) {
        // If we get a 401 (unauthorized), it means connection works but no session
        if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
          setState(() {
            _status = '✅ Ping successful! Appwrite connected (no active session).';
            _statusColor = Colors.green;
            _isLoading = false;
          });
        } else {
          rethrow; // Re-throw other errors
        }
      }
    } catch (e) {
      setState(() {
        _status = '❌ Ping failed: ${e.toString()}';
        _statusColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearSession() async {
    if (_client == null) return;
    
    setState(() {
      _isLoading = true;
      _status = 'Clearing session...';
      _statusColor = Colors.orange;
    });

    try {
      final account = Account(_client!);
      await account.deleteSessions();
      setState(() {
        _status = '✅ Session cleared successfully!';
        _statusColor = Colors.blue;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '✅ Session cleared (or no session existed)';
        _statusColor = Colors.blue;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Appwrite Connection Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Project: ${AppwriteConstants.APPWRITE_PROJECT_ID}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Endpoint: ${AppwriteConstants.APPWRITE_PUBLIC_ENDPOINT}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                border: Border.all(color: _statusColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendPing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Send a ping',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _clearSession,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      'Clear Session',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}