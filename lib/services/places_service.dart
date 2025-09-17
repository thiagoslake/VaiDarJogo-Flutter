import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../config/google_places_config.dart';

class PlacesService {
  /// Configuração do Google Places para autocompletar
  static GooglePlaceAutoCompleteTextField getAutoCompleteTextField({
    required Function(Prediction) onPlaceSelected,
    required String hintText,
    required String labelText,
  }) {
    return GooglePlaceAutoCompleteTextField(
      textEditingController:
          TextEditingController(), // Será controlado pelo widget pai
      googleAPIKey: GooglePlacesConfig.apiKey,
      inputDecoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.location_on),
        suffixIcon: const Icon(Icons.search),
      ),
      debounceTime: 600, // Aguarda 600ms após parar de digitar
      countries: const ["br"], // Limita para Brasil
      isLatLngRequired: true, // Requer coordenadas
      getPlaceDetailWithLatLng: (Prediction prediction) {
        onPlaceSelected(prediction);
      },
      itemClick: (Prediction prediction) {
        onPlaceSelected(prediction);
      },
      seperatedBuilder: const Divider(),
      containerHorizontalPadding: 10,
      itemBuilder: (context, index, prediction) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.description ?? '',
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (prediction.structuredFormatting?.secondaryText != null)
                      Text(
                        prediction.structuredFormatting!.secondaryText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      isCrossBtnShown: true,
    );
  }

  /// Obtém detalhes completos de um lugar selecionado
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      // Aqui você implementaria a chamada para a API do Google Places
      // para obter detalhes completos do lugar
      // Por enquanto, retornamos null
      return null;
    } catch (e) {
      print('❌ Erro ao obter detalhes do lugar: $e');
      return null;
    }
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
