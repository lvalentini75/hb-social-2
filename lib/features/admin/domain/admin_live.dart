class AdminLiveRecord {
  final String id;
  final String title;
  final String status;
  final String hostName;
  final int viewerCount;
  final int peakViewers;
  final int totalViewers;
  final int messageCount;
  final DateTime? startedAt;
  final int durationSeconds;
  final String? outcome;

  const AdminLiveRecord({required this.id, required this.title, required this.status, required this.hostName, required this.viewerCount, required this.peakViewers, required this.totalViewers, required this.messageCount, this.startedAt, required this.durationSeconds, this.outcome});
  factory AdminLiveRecord.fromJson(Map<String, dynamic> json) { final host = json['host'] as Map?; return AdminLiveRecord(id: json['id'].toString(), title: json['title']?.toString() ?? '', status: json['status']?.toString() ?? '', hostName: host?['display_name']?.toString() ?? json['host_name']?.toString() ?? '', viewerCount: (json['viewer_count'] as num?)?.toInt() ?? 0, peakViewers: (json['peak_viewers'] as num?)?.toInt() ?? 0, totalViewers: (json['total_viewers'] as num?)?.toInt() ?? 0, messageCount: (json['message_count'] as num?)?.toInt() ?? 0, startedAt: DateTime.tryParse(json['started_at']?.toString() ?? '')?.toUtc(), durationSeconds: (json['duration_s'] as num?)?.toInt() ?? 0, outcome: json['outcome']?.toString()); }
}