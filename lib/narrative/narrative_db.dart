import 'dart:convert';

import '../services/storage_service_prefs.dart';
import 'cards.dart';

class NarrativeDB {
  static String _kCardsKey(String projectId) => 'rpov_cards_$projectId';

  static Future<List<CardBase>> loadCards(String projectId) async {
    final prefs = StorageServicePrefs.prefs;
    final raw = prefs.getString(_kCardsKey(projectId));
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((m) => CardBase.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCards(String projectId, List<CardBase> cards) async {
    final prefs = StorageServicePrefs.prefs;
    final raw = jsonEncode(cards.map((c) => c.toJson()).toList());
    await prefs.setString(_kCardsKey(projectId), raw);
  }

  static Future<void> upsertCard(String projectId, CardBase card) async {
    final list = await loadCards(projectId);
    final idx = list.indexWhere((c) => c.id == card.id && c.type == card.type);

    if (idx >= 0) {
      list[idx] = card;
    } else {
      list.add(card);
    }
    await saveCards(projectId, list);
  }
}

