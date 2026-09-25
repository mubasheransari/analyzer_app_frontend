class AnalysisNotification {
  final int id;
  final int analysisId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AnalysisNotification({
    required this.id, required this.analysisId, required this.message,
    required this.isRead, required this.createdAt,
  });

  factory AnalysisNotification.fromJson(Map<String, dynamic> j) =>
      AnalysisNotification(
        id: j['id'] as int,
        analysisId: j['analysis_id'] as int,
        message: j['message'] ?? '',
        isRead: j['is_read'] == true,
        createdAt: DateTime.parse(j['created_at']),
      );
}
