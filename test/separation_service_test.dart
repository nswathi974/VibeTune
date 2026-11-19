import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibetune/models/separation_job_model.dart';
import 'package:vibetune/services/separation_service.dart';
import 'package:vibetune/config/api_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SeparationJobModel Serialization Tests', () {
    test('parses completed separation job JSON correctly', () {
      final json = {
        'jobId': 'sep_test_123',
        'songId': 'stream_ka_01',
        'songTitle': 'Bhagyada Lakshmi Baramma',
        'status': 'completed',
        'progress': 100,
        'instrumentalUrl': '/media/separated/sep_test_123_instrumental.mp3',
        'cached': true,
        'executionTimeMs': 12400,
        'completedAt': '2026-11-03T10:00:00.000Z',
      };

      final job = SeparationJobModel.fromJson(json);
      expect(job.jobId, 'sep_test_123');
      expect(job.songId, 'stream_ka_01');
      expect(job.status, 'completed');
      expect(job.isCompleted, isTrue);
      expect(job.isProcessing, isFalse);
      expect(job.isFailed, isFalse);
      expect(job.progress, 100);
      expect(job.instrumentalUrl, '/media/separated/sep_test_123_instrumental.mp3');
      expect(job.cached, isTrue);
      expect(job.executionTimeMs, 12400);
      expect(job.completedAt, isNotNull);
    });

    test('parses processing job JSON correctly', () {
      final json = {
        'jobId': 'sep_test_456',
        'songId': 'stream_te_02',
        'songTitle': 'Ksheerabdhi Kanyaka',
        'status': 'processing',
        'progress': 40,
        'cached': false,
      };

      final job = SeparationJobModel.fromJson(json);
      expect(job.isCompleted, isFalse);
      expect(job.isProcessing, isTrue);
      expect(job.isFailed, isFalse);
      expect(job.progress, 40);
      expect(job.instrumentalUrl, isNull);
    });

    test('parses failed job JSON correctly with error message', () {
      final json = {
        'jobId': 'sep_test_789',
        'songId': 'hi_01',
        'songTitle': 'Kesariya',
        'status': 'failed',
        'progress': 0,
        'errorMessage': 'Commercial film tracks are protected by copyright.',
      };

      final job = SeparationJobModel.fromJson(json);
      expect(job.isCompleted, isFalse);
      expect(job.isProcessing, isFalse);
      expect(job.isFailed, isTrue);
      expect(job.errorMessage, contains('Commercial film tracks'));
    });
  });

  group('SeparationService State Management Tests', () {
    test('initializes with idle state', () {
      final service = SeparationService();
      expect(service.status, SeparationStatus.idle);
      expect(service.isProcessing, isFalse);
      expect(service.currentJob, isNull);
      expect(service.errorMessage, isNull);
      expect(service.progress, 0);
      service.dispose();
    });

    test('reset clears timers and returns to idle', () {
      final service = SeparationService();
      service.reset();
      expect(service.status, SeparationStatus.idle);
      expect(service.currentJob, isNull);
      expect(service.errorMessage, isNull);
      expect(service.progress, 0);
      service.dispose();
    });

    test('ApiConfig baseUrl correctly configures host and ports', () {
      expect(ApiConfig.port, 5000);
      expect(ApiConfig.baseUrl.contains('5000'), isTrue);
      expect(ApiConfig.baseUrl.startsWith('http://'), isTrue);
      expect(ApiConfig.healthUrl, '${ApiConfig.baseUrl}/api/health');
    });
  });
}
