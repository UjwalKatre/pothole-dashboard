import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/accident_zone_model.dart';
import '../models/geo_point.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyADmq5gQAaY6PyZMIRwjY0befndNJyWOPI';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static List<AccidentZone>? _cachedZones;
  static DateTime? _lastFetch;

  static Future<List<AccidentZone>> fetchAccidentBlackspots(String highway) async {
    if (_cachedZones != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < const Duration(hours: 6)) {
      return _cachedZones!;
    }

    const prompt = 'Return a JSON array of 8 real accident blackspot zones for highway '
        'NH-30 Chhattisgarh India. Each object must have exactly: id (string), '
        'lat (number), lng (number), accidentsPerYear (number 3-25), '
        'description (string), roadName (string). '
        'Use real coordinates near NH-30 between Raipur and Bilaspur. '
        'Return ONLY the JSON array, no markdown, no code fences, no extra text.';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 1024},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          String text =
              (candidates[0] as Map)['content']['parts'][0]['text'] as String? ?? '';
          text = text.replaceAll('```json', '').replaceAll('```', '').trim();
          final startIdx = text.indexOf('[');
          final endIdx = text.lastIndexOf(']');
          if (startIdx >= 0 && endIdx > startIdx) {
            text = text.substring(startIdx, endIdx + 1);
          }
          final list = jsonDecode(text) as List<dynamic>;
          _cachedZones = list
              .map((e) => AccidentZone.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          _lastFetch = DateTime.now();
          return _cachedZones!;
        }
      }
    } catch (_) {
      // Fall through to fallback
    }
    return _fallbackZones();
  }

  static List<AccidentZone> _fallbackZones() => [
        const AccidentZone(
          id: 'f1',
          location: GeoPoint(21.2514, 81.6296),
          accidentsPerYear: 15,
          description: 'Sharp bend - Raipur bypass',
          roadName: 'NH-30',
        ),
        const AccidentZone(
          id: 'f2',
          location: GeoPoint(21.19, 81.70),
          accidentsPerYear: 11,
          description: 'Pothole cluster - waterlogging zone',
          roadName: 'NH-30',
        ),
        const AccidentZone(
          id: 'f3',
          location: GeoPoint(21.50, 81.88),
          accidentsPerYear: 18,
          description: 'Median gap - Bhatapara',
          roadName: 'NH-30',
        ),
        const AccidentZone(
          id: 'f4',
          location: GeoPoint(21.70, 82.00),
          accidentsPerYear: 9,
          description: 'Dense fog zone near river bridge',
          roadName: 'NH-30',
        ),
        const AccidentZone(
          id: 'f5',
          location: GeoPoint(22.09, 82.15),
          accidentsPerYear: 22,
          description: 'High-speed overtaking zone',
          roadName: 'NH-30',
        ),
        const AccidentZone(
          id: 'f6',
          location: GeoPoint(21.90, 82.10),
          accidentsPerYear: 7,
          description: 'Narrow culvert section',
          roadName: 'NH-30',
        ),
        const AccidentZone(
          id: 'f7',
          location: GeoPoint(22.20, 82.35),
          accidentsPerYear: 14,
          description: 'Hilly gradient - Bilaspur approach',
          roadName: 'NH-30',
        ),
        const AccidentZone(
          id: 'f8',
          location: GeoPoint(22.00, 82.00),
          accidentsPerYear: 5,
          description: 'School zone - speed reduction needed',
          roadName: 'NH-30',
        ),
      ];
}
