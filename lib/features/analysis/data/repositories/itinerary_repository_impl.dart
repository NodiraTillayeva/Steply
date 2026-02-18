import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:steply/features/analysis/domain/entities/itinerary.dart';
import 'package:steply/features/analysis/domain/repositories/itinerary_repository.dart';

class ItineraryRepositoryImpl implements ItineraryRepository {
  static const _key = 'saved_itineraries';

  @override
  Future<void> createItinerary(Itinerary itinerary) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _loadList(prefs);
    list.add(_itineraryToMap(itinerary));
    await prefs.setString(_key, jsonEncode(list));
  }

  @override
  Future<List<Itinerary>> getItineraries() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _loadList(prefs);
    return list.map((m) => _itineraryFromMap(m)).toList();
  }

  @override
  Future<void> deleteItinerary(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _loadList(prefs);
    list.removeWhere((m) => m['id'] == id);
    await prefs.setString(_key, jsonEncode(list));
  }

  List<Map<String, dynamic>> _loadList(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Map<String, dynamic> _itineraryToMap(Itinerary it) => {
        'id': it.id,
        'name': it.name,
        'totalDurationMs': it.totalDuration.inMilliseconds,
        'startDate': it.startDate?.toIso8601String(),
        'endDate': it.endDate?.toIso8601String(),
        'stops': it.stops
            .map((s) => {
                  'name': s.name,
                  'latitude': s.latitude,
                  'longitude': s.longitude,
                  'durationMs': s.duration.inMilliseconds,
                  'visitTime': s.visitTime?.toIso8601String(),
                })
            .toList(),
      };

  Itinerary _itineraryFromMap(Map<String, dynamic> m) => Itinerary(
        id: m['id'] as String,
        name: m['name'] as String,
        totalDuration: Duration(milliseconds: m['totalDurationMs'] as int),
        startDate: m['startDate'] != null
            ? DateTime.parse(m['startDate'] as String)
            : null,
        endDate: m['endDate'] != null
            ? DateTime.parse(m['endDate'] as String)
            : null,
        stops: (m['stops'] as List)
            .map((s) => ItineraryStop(
                  name: s['name'] as String,
                  latitude: (s['latitude'] as num).toDouble(),
                  longitude: (s['longitude'] as num).toDouble(),
                  duration: Duration(milliseconds: s['durationMs'] as int),
                  visitTime: s['visitTime'] != null
                      ? DateTime.parse(s['visitTime'] as String)
                      : null,
                ))
            .toList(),
      );
}
