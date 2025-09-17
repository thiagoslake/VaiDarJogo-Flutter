import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/google_places_config.dart';

class SimpleLocationField extends StatefulWidget {
  final String labelText;
  final String hintText;
  final String? initialValue;
  final Function(String location, String? address, double? lat, double? lng)
      onLocationSelected;
  final String? Function(String?)? validator;

  const SimpleLocationField({
    super.key,
    required this.labelText,
    required this.hintText,
    this.initialValue,
    required this.onLocationSelected,
    this.validator,
  });

  @override
  State<SimpleLocationField> createState() => _SimpleLocationFieldState();
}

class _SimpleLocationFieldState extends State<SimpleLocationField> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _locationController.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    if (!GooglePlacesConfig.isConfigured) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Usar a nova API do Google Places
      final url =
          Uri.parse('https://places.googleapis.com/v1/places:autocomplete');

      final body = {
        'input': query,
        'languageCode': 'pt-BR',
        'regionCode': 'BR',
        'includedRegionCodes': ['BR'],
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': GooglePlacesConfig.apiKey,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['suggestions'] != null) {
          setState(() {
            _suggestions = List<Map<String, dynamic>>.from(data['suggestions']);
            _showSuggestions = true;
          });
        } else {
          print('❌ Erro na API: ${data['error'] ?? 'Erro desconhecido'}');
        }
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro ao buscar lugares: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    if (!GooglePlacesConfig.isConfigured) {
      return;
    }

    try {
      // Usar a nova API do Google Places
      final url = Uri.parse('https://places.googleapis.com/v1/places/$placeId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': GooglePlacesConfig.apiKey,
          'X-Goog-FieldMask': 'displayName,formattedAddress,location',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['displayName'] != null &&
            data['displayName']['text'] != null) {
          final location = data['displayName']['text'] as String;
          final address = data['formattedAddress'] as String? ?? '';
          final locationData = data['location'] as Map<String, dynamic>?;

          double? lat, lng;
          if (locationData != null) {
            lat = locationData['latitude'] as double?;
            lng = locationData['longitude'] as double?;
          }

          setState(() {
            _locationController.text = location;
            _addressController.text = address;
            _showSuggestions = false;
            _suggestions = [];
          });

          widget.onLocationSelected(location, address, lat, lng);
        } else {
          print('❌ Dados de detalhes inválidos: $data');
        }
      } else {
        print('❌ Erro HTTP ao obter detalhes: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro ao obter detalhes do lugar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de localização
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search),
          ),
          validator: widget.validator,
          onChanged: (value) {
            _searchPlaces(value);
          },
          onTap: () {
            if (_suggestions.isNotEmpty) {
              setState(() {
                _showSuggestions = true;
              });
            }
          },
        ),

        // Lista de sugestões
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _suggestions.take(5).map((suggestion) {
                final placePrediction =
                    suggestion['placePrediction'] as Map<String, dynamic>?;
                if (placePrediction == null) return const SizedBox.shrink();

                String title = 'Local';
                String? subtitle;

                // Tentar obter o título
                if (placePrediction['text'] != null &&
                    placePrediction['text']['text'] != null) {
                  final textData = placePrediction['text']['text'];
                  if (textData is String) {
                    title = textData;
                  } else if (textData is Map && textData['text'] != null) {
                    title = textData['text'] as String;
                  }
                } else if (placePrediction['structuredFormat'] != null &&
                    placePrediction['structuredFormat']['mainText'] != null) {
                  final mainText =
                      placePrediction['structuredFormat']['mainText'];
                  if (mainText is String) {
                    title = mainText;
                  } else if (mainText is Map && mainText['text'] != null) {
                    title = mainText['text'] as String;
                  }
                }

                // Tentar obter o subtítulo
                if (placePrediction['structuredFormat'] != null &&
                    placePrediction['structuredFormat']['secondaryText'] !=
                        null) {
                  final secondaryText =
                      placePrediction['structuredFormat']['secondaryText'];
                  if (secondaryText is String) {
                    subtitle = secondaryText;
                  } else if (secondaryText is Map &&
                      secondaryText['text'] != null) {
                    subtitle = secondaryText['text'] as String;
                  }
                }

                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.grey),
                  title: Text(
                    title,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: subtitle != null
                      ? Text(
                          subtitle,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () {
                    final placeId = placePrediction['placeId'] as String?;
                    if (placeId != null) {
                      _getPlaceDetails(placeId);
                    }
                  },
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 16),

        // Campo de endereço completo
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Endereço Completo',
            hintText: 'Endereço será preenchido automaticamente',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home),
          ),
          readOnly: true,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),

        // Aviso se API não configurada
        if (!GooglePlacesConfig.isConfigured)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange.shade600, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Autocompletar desabilitado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure a chave da API do Google Places para ativar o autocompletar.',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
