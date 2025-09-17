import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../config/google_places_config.dart';

class LocationAutocompleteField extends StatefulWidget {
  final String labelText;
  final String hintText;
  final String? initialValue;
  final Function(String location, String? address, double? lat, double? lng)
      onLocationSelected;
  final String? Function(String?)? validator;

  const LocationAutocompleteField({
    super.key,
    required this.labelText,
    required this.hintText,
    this.initialValue,
    required this.onLocationSelected,
    this.validator,
  });

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isApiKeyConfigured = false;

  @override
  void initState() {
    super.initState();
    _isApiKeyConfigured = GooglePlacesConfig.isConfigured;

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

  void _onPlaceSelected(Prediction prediction) {
    setState(() {
      _locationController.text = prediction.description ?? '';
      _addressController.text = prediction.description ?? '';
    });

    // Extrair coordenadas se disponíveis
    double? lat, lng;
    if (prediction.lat != null && prediction.lng != null) {
      lat = double.tryParse(prediction.lat.toString());
      lng = double.tryParse(prediction.lng.toString());
    }

    // Chamar callback com os dados selecionados
    widget.onLocationSelected(
      prediction.description ?? '',
      prediction.description,
      lat,
      lng,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isApiKeyConfigured) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_on),
            ),
            validator: widget.validator,
            onChanged: (value) {
              widget.onLocationSelected(value, null, null, null);
            },
          ),
          const SizedBox(height: 8),
          Container(
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
                  'Configure a chave da API do Google Places para ativar o autocompletar de endereços.',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de localização com autocompletar
        GooglePlaceAutoCompleteTextField(
          textEditingController: _locationController,
          googleAPIKey: GooglePlacesConfig.apiKey,
          inputDecoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: const Icon(Icons.search),
          ),
          debounceTime: 600,
          countries: const ["br"],
          isLatLngRequired: true,
          getPlaceDetailWithLatLng: _onPlaceSelected,
          itemClick: _onPlaceSelected,
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
                        if (prediction.structuredFormatting?.secondaryText !=
                            null)
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
        ),

        const SizedBox(height: 16),

        // Campo de endereço completo (preenchido automaticamente)
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
      ],
    );
  }
}
