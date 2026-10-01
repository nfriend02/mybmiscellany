import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../firebase/firestoreGateway.dart';
import '../models/appUser.dart';
import '../models/historyEntry.dart';

class HistoryRepository extends ChangeNotifier {
  HistoryRepository({FirestoreGateway? gateway})
    : _gateway = gateway ?? const FirestoreGateway();

  final FirestoreGateway _gateway;
  final List<HistoryEntry> entries = [];

  List<HistoryEntry> forFeature(String featureType) {
    return entries.where((entry) => entry.featureType == featureType).toList();
  }

  Future<HistoryEntry> add({
    required AppUser user,
    required String featureType,
    required String title,
    required String preview,
    required Map<String, dynamic> input,
    required Map<String, dynamic> output,
  }) async {
    final entry = HistoryEntry(
      resultId: const Uuid().v4(),
      userId: user.userId,
      featureType: featureType,
      title: title,
      preview: preview,
      input: input,
      output: output,
      createdAt: DateTime.now(),
      sync: CloudSync.local,
    );
    entries.insert(0, entry);
    notifyListeners();
    final synced = await _gateway.saveResult(entry);
    final sync = switch (synced) {
      true => CloudSync.synced,
      false => CloudSync.failed,
      null => CloudSync.local,
    };
    final updated = entry.copyWith(sync: sync);
    _replace(updated);
    return updated;
  }

  Future<void> delete(String resultId) async {
    entries.removeWhere((entry) => entry.resultId == resultId);
    notifyListeners();
    await _gateway.deleteResult(resultId);
  }

  void _replace(HistoryEntry entry) {
    final index = entries.indexWhere((item) => item.resultId == entry.resultId);
    if (index < 0) return;
    entries[index] = entry;
    notifyListeners();
  }
}
