class PollOption {
  final String id;
  final String label;
  final int sortOrder;
  final int voteCount;

  const PollOption({required this.id, required this.label, required this.sortOrder, required this.voteCount});

  factory PollOption.fromJson(Map<String, dynamic> json) => PollOption(
    id: json['id'] as String,
    label: json['label'] as String,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    voteCount: (json['vote_count'] as num?)?.toInt() ?? 0,
  );

  PollOption copyWith({int? voteCount}) => PollOption(id: id, label: label, sortOrder: sortOrder, voteCount: voteCount ?? this.voteCount);
}

class Poll {
  final String id;
  final String postId;
  final String question;
  final bool allowMultiple;
  final DateTime? endsAt;
  final int totalVotes;
  final List<PollOption> options;
  final Set<String> myOptionIds;

  const Poll({required this.id, required this.postId, required this.question, required this.allowMultiple, this.endsAt, required this.totalVotes, required this.options, this.myOptionIds = const {}});

  bool get isClosed => endsAt != null && endsAt!.isBefore(DateTime.now().toUtc());

  factory Poll.fromJson(Map<String, dynamic> json) {
    final options = ((json['options'] as List?) ?? (json['poll_options'] as List?) ?? const [])
        .map((item) => PollOption.fromJson(Map<String, dynamic>.from(item as Map))).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Poll(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      question: json['question'] as String? ?? '',
      allowMultiple: json['allow_multiple'] as bool? ?? false,
      endsAt: json['ends_at'] == null ? null : DateTime.parse(json['ends_at'] as String).toUtc(),
      totalVotes: (json['total_votes'] as num?)?.toInt() ?? 0,
      options: options,
      myOptionIds: Set<String>.from((json['my_option_ids'] as List?) ?? const []),
    );
  }

  Poll copyWith({int? totalVotes, List<PollOption>? options, Set<String>? myOptionIds}) => Poll(
    id: id,
    postId: postId,
    question: question,
    allowMultiple: allowMultiple,
    endsAt: endsAt,
    totalVotes: totalVotes ?? this.totalVotes,
    options: options ?? this.options,
    myOptionIds: myOptionIds ?? this.myOptionIds,
  );
}