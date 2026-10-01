enum CloudSync { local, synced, failed }

class HistoryEntry {
  const HistoryEntry({
    required this.resultId,
    required this.userId,
    required this.featureType,
    required this.title,
    required this.preview,
    required this.input,
    required this.output,
    required this.createdAt,
    required this.sync,
  });

  final String resultId;
  final String userId;
  final String featureType;
  final String title;
  final String preview;
  final Map<String, dynamic> input;
  final Map<String, dynamic> output;
  final DateTime createdAt;
  final CloudSync sync;

  HistoryEntry copyWith({CloudSync? sync}) {
    return HistoryEntry(
      resultId: resultId,
      userId: userId,
      featureType: featureType,
      title: title,
      preview: preview,
      input: input,
      output: output,
      createdAt: createdAt,
      sync: sync ?? this.sync,
    );
  }
}
