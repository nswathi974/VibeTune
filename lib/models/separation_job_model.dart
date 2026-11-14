enum SeparationStatus {
  idle,
  checking,
  submitting,
  processing,
  completed,
  failed,
}

class SeparationJobModel {
  final String jobId;
  final String songId;
  final String songTitle;
  final String status;
  final int progress;
  final String? instrumentalUrl;
  final String? errorMessage;
  final int? executionTimeMs;
  final bool cached;
  final DateTime? completedAt;

  const SeparationJobModel({
    required this.jobId,
    required this.songId,
    required this.songTitle,
    required this.status,
    required this.progress,
    this.instrumentalUrl,
    this.errorMessage,
    this.executionTimeMs,
    this.cached = false,
    this.completedAt,
  });

  bool get isCompleted => status.toLowerCase() == 'completed' && instrumentalUrl != null;
  bool get isProcessing => status.toLowerCase() == 'processing' || status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';

  factory SeparationJobModel.fromJson(Map<String, dynamic> json) {
    return SeparationJobModel(
      jobId: json['jobId'] as String? ?? '',
      songId: json['songId'] as String? ?? '',
      songTitle: json['songTitle'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      instrumentalUrl: json['instrumentalUrl'] as String?,
      errorMessage: json['errorMessage'] as String?,
      executionTimeMs: (json['executionTimeMs'] as num?)?.toInt(),
      cached: json['cached'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}

