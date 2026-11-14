import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/separation_job_model.dart';

class SeparationService extends ChangeNotifier {
  SeparationStatus _status = SeparationStatus.idle;
  SeparationJobModel? _currentJob;
  String? _errorMessage;
  int _progress = 0;
  Timer? _pollTimer;

  SeparationStatus get status => _status;
  SeparationJobModel? get currentJob => _currentJob;
  String? get errorMessage => _errorMessage;
  int get progress => _progress;
  bool get isProcessing => _status == SeparationStatus.processing || _status == SeparationStatus.submitting;

  void reset() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _status = SeparationStatus.idle;
    _currentJob = null;
    _errorMessage = null;
    _progress = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Map<String, String> _buildHeaders(String? authToken, bool isGuest) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null && authToken.isNotEmpty && authToken != 'guest_session') {
      headers['Authorization'] = 'Bearer $authToken';
    } else {
      headers['x-guest-mode'] = 'true';
    }
    return headers;
  }

  /// Check if an AI separated instrumental is already available or processing for a song
  Future<SeparationJobModel?> checkSongStatus(String songId, {String? authToken, bool isGuest = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/separation/status/song/$songId');
      final res = await http.get(url, headers: _buildHeaders(authToken, isGuest));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['job'] != null) {
          final job = SeparationJobModel.fromJson(data['job']);
          _currentJob = job;
          if (job.isCompleted) {
            _status = SeparationStatus.completed;
            _progress = 100;
          } else if (job.isProcessing) {
            _status = SeparationStatus.processing;
            _progress = job.progress;
          }
          notifyListeners();
          return job;
        }
      }
    } catch (e) {
      debugPrint('Error checking song separation status: $e');
    }
    return null;
  }

  /// Submit a request for AI vocal separation
  Future<SeparationJobModel?> requestSeparation(
    String songId, {
    String? authToken,
    bool isGuest = true,
    void Function(SeparationJobModel)? onCompleted,
  }) async {
    _pollTimer?.cancel();
    _status = SeparationStatus.submitting;
    _errorMessage = null;
    _progress = 10;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/separation/jobs');
      final res = await http.post(
        url,
        headers: _buildHeaders(authToken, isGuest),
        body: jsonEncode({'songId': songId}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 202) {
        if (data['success'] == true && data['job'] != null) {
          final job = SeparationJobModel.fromJson(data['job']);
          _currentJob = job;

          if (job.isCompleted) {
            _status = SeparationStatus.completed;
            _progress = 100;
            notifyListeners();
            onCompleted?.call(job);
            return job;
          }

          // Otherwise start polling for completion
          _status = SeparationStatus.processing;
          _progress = job.progress > 0 ? job.progress : 25;
          notifyListeners();
          _startPolling(job.jobId, authToken: authToken, isGuest: isGuest, onCompleted: onCompleted);
          return job;
        }
      }

      // Handle server error or validation rejection
      _status = SeparationStatus.failed;
      _errorMessage = data['message'] ?? 'Failed to submit separation job (${res.statusCode})';
      notifyListeners();
      return null;
    } catch (e) {
      _status = SeparationStatus.failed;
      _errorMessage = 'Connection error: $e';
      notifyListeners();
      return null;
    }
  }

  void _startPolling(
    String jobId, {
    String? authToken,
    bool isGuest = true,
    void Function(SeparationJobModel)? onCompleted,
  }) {
    _pollTimer?.cancel();
    int elapsedSeconds = 0;
    const interval = Duration(seconds: 2);

    _pollTimer = Timer.periodic(interval, (timer) async {
      elapsedSeconds += 2;
      if (elapsedSeconds > 180) {
        // 3 minute timeout
        timer.cancel();
        _status = SeparationStatus.failed;
        _errorMessage = 'AI separation job timed out after 3 minutes';
        notifyListeners();
        return;
      }

      try {
        final url = Uri.parse('${ApiConfig.baseUrl}/api/separation/jobs/$jobId');
        final res = await http.get(url, headers: _buildHeaders(authToken, isGuest));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['success'] == true && data['job'] != null) {
            final job = SeparationJobModel.fromJson(data['job']);
            _currentJob = job;
            _progress = job.progress;

            if (job.isCompleted) {
              timer.cancel();
              _status = SeparationStatus.completed;
              _progress = 100;
              notifyListeners();
              onCompleted?.call(job);
            } else if (job.isFailed) {
              timer.cancel();
              _status = SeparationStatus.failed;
              _errorMessage = job.errorMessage ?? 'Vocal separation failed';
              notifyListeners();
            } else {
              notifyListeners();
            }
          }
        }
      } catch (e) {
        debugPrint('Poll error for separation job $jobId: $e');
      }
    });
  }
}
