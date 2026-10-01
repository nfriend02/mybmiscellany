import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/appUser.dart';
import '../models/historyEntry.dart';
import 'firebaseBootstrap.dart';

class Collections {
  static const users = 'users';
  static const results = 'results';
  static const games = 'games';
  static const scores = 'scores';
  static const items = 'items';
  static const userItems = 'userItems';
  static const matches = 'matches';
}

class GameDraft {
  const GameDraft({
    required this.gameId,
    required this.name,
    required this.description,
    required this.icon,
    required this.createdBy,
  });

  final String gameId;
  final String name;
  final String description;
  final String icon;
  final String createdBy;
}

class ScoreDraft {
  const ScoreDraft({
    required this.gameId,
    required this.userId,
    required this.score,
    required this.rank,
  });

  final String gameId;
  final String userId;
  final int score;
  final int rank;
}

class ItemDraft {
  const ItemDraft({
    required this.gameId,
    required this.name,
    required this.type,
    required this.description,
  });

  final String gameId;
  final String name;
  final String type;
  final String description;
}

class UserItemDraft {
  const UserItemDraft({
    required this.userId,
    required this.gameId,
    required this.itemId,
  });

  final String userId;
  final String gameId;
  final String itemId;
}

class MatchDraft {
  const MatchDraft({
    required this.gameId,
    required this.players,
    required this.winnerId,
  });

  final String gameId;
  final List<String> players;
  final String winnerId;
}

class FirestoreGateway {
  const FirestoreGateway();

  Future<void> touchUser(AppUser user) async {
    if (!FirebaseBootstrap.ready) return;
    try {
      await FirebaseFirestore.instance
          .collection(Collections.users)
          .doc(user.userId)
          .set({
            'userId': user.userId,
            'displayName': user.displayName,
            'email': user.email,
            'avatarUrl': user.avatarUrl,
            'createdAt': Timestamp.fromDate(user.createdAt.toUtc()),
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<bool?> saveResult(HistoryEntry entry) async {
    if (!FirebaseBootstrap.ready) return null;
    try {
      await FirebaseFirestore.instance
          .collection(Collections.results)
          .doc(entry.resultId)
          .set({
            'resultId': entry.resultId,
            'userId': entry.userId,
            'featureType': entry.featureType,
            'input': _sanitize(entry.input),
            'output': _sanitize(entry.output),
            'createdAt': Timestamp.fromDate(entry.createdAt.toUtc()),
          });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteResult(String resultId) async {
    if (!FirebaseBootstrap.ready) return;
    try {
      await FirebaseFirestore.instance
          .collection(Collections.results)
          .doc(resultId)
          .delete();
    } catch (_) {}
  }

  Future<bool> saveScore({
    required GameDraft game,
    required ScoreDraft score,
  }) async {
    if (!FirebaseBootstrap.ready) return false;
    try {
      await _ensureGame(game);
      final scoreId = const Uuid().v4();
      await FirebaseFirestore.instance
          .collection(Collections.scores)
          .doc(scoreId)
          .set({
            'scoreId': scoreId,
            'gameId': score.gameId,
            'userId': score.userId,
            'score': score.score,
            'rank': score.rank,
            'createdAt': Timestamp.fromDate(DateTime.now().toUtc()),
          });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> saveItem(ItemDraft item) async {
    if (!FirebaseBootstrap.ready) return null;
    try {
      final itemId = const Uuid().v4();
      await FirebaseFirestore.instance
          .collection(Collections.items)
          .doc(itemId)
          .set({
            'itemId': itemId,
            'gameId': item.gameId,
            'name': item.name,
            'type': item.type,
            'description': item.description,
          });
      return itemId;
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveUserItem(UserItemDraft item) async {
    if (!FirebaseBootstrap.ready) return false;
    try {
      final userItemId = const Uuid().v4();
      await FirebaseFirestore.instance
          .collection(Collections.userItems)
          .doc(userItemId)
          .set({
            'userItemId': userItemId,
            'userId': item.userId,
            'gameId': item.gameId,
            'itemId': item.itemId,
            'acquiredAt': Timestamp.fromDate(DateTime.now().toUtc()),
          });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveMatch(MatchDraft match) async {
    if (!FirebaseBootstrap.ready) return false;
    try {
      final matchId = const Uuid().v4();
      await FirebaseFirestore.instance
          .collection(Collections.matches)
          .doc(matchId)
          .set({
            'matchId': matchId,
            'gameId': match.gameId,
            'players': match.players,
            'winnerId': match.winnerId,
            'createdAt': Timestamp.fromDate(DateTime.now().toUtc()),
          });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureGame(GameDraft game) async {
    final ref = FirebaseFirestore.instance
        .collection(Collections.games)
        .doc(game.gameId);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'gameId': game.gameId,
      'name': game.name,
      'description': game.description,
      'icon': game.icon,
      'createdBy': game.createdBy,
      'createdAt': Timestamp.fromDate(DateTime.now().toUtc()),
    });
  }
}

Map<String, dynamic> _sanitize(Map<String, dynamic> value) {
  return value.map((key, dynamic item) => MapEntry(key, _clean(item)));
}

dynamic _clean(dynamic item) {
  if (item == null || item is num || item is bool || item is String) {
    return item;
  }
  if (item is DateTime) return item.toIso8601String();
  if (item is Map) {
    return item.map(
      (dynamic key, dynamic value) => MapEntry(key.toString(), _clean(value)),
    );
  }
  if (item is Iterable) return item.map(_clean).toList();
  return item.toString();
}
