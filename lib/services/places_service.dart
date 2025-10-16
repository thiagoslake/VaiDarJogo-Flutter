import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/google_places_config.dart';

class PlacesService {
  /// Busca sugestões de lugares usando a nova API do Google Places
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (!GooglePlacesConfig.isConfigured || query.trim().isEmpty) {
      return [];
    }

    try {
      final url = Uri.parse(
        'https://places.googleapis.com/v1/places:autocomplete',
      );

      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': GooglePlacesConfig.apiKey,
        'X-Goog-FieldMask':
            'places.displayName,places.formattedAddress,places.location',
      };

      final body = json.encode({
        'input': query,
        'languageCode': 'pt-BR',
        'regionCode': 'BR',
        'includedRegionCodes': ['BR'],
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['suggestions'] != null) {
          return (data['suggestions'] as List)
              .map((suggestion) => suggestion['place'] as Map<String, dynamic>)
              .toList();
        }
      } else {
        print('❌ Erro na API Places: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro ao buscar lugares: $e');
    }

    return [];
  }

  /// Obtém detalhes de um lugar específico
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (!GooglePlacesConfig.isConfigured) {
      return null;
    }

    try {
      final url = Uri.parse(
        'https://places.googleapis.com/v1/places/$placeId',
      );

      final headers = {
        'X-Goog-Api-Key': GooglePlacesConfig.apiKey,
        'X-Goog-FieldMask':
            'displayName,formattedAddress,location,addressComponents',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('❌ Erro ao obter detalhes do lugar: $e');
    }

    return null;
  }

  /// Valida se a chave da API está configurada
  static bool isApiKeyConfigured() {
    return GooglePlacesConfig.isConfigured;
  }

  /// Retorna instruções para configurar a chave da API
  static String getApiKeyInstructions() {
    return GooglePlacesConfig.setupInstructions;
  }
}
