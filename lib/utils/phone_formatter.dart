import 'package:flutter/services.dart';

/// Formatter para máscara de telefone brasileiro
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove todos os caracteres não numéricos
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // Limita a 11 dígitos
    final limitedDigits = digitsOnly.length > 11 
        ? digitsOnly.substring(0, 11) 
        : digitsOnly;
    
    // Aplica a formatação
    String formatted = '';
    
    if (limitedDigits.isNotEmpty) {
      if (limitedDigits.length <= 2) {
        // Apenas DDD: (11
        formatted = '($limitedDigits';
      } else if (limitedDigits.length <= 6) {
        // DDD + início do número: (11) 9999
        formatted = '(${limitedDigits.substring(0, 2)}) ${limitedDigits.substring(2)}';
      } else if (limitedDigits.length <= 10) {
        // Telefone fixo: (11) 9999-9999
        formatted = '(${limitedDigits.substring(0, 2)}) ${limitedDigits.substring(2, 6)}-${limitedDigits.substring(6)}';
      } else {
        // Celular: (11) 99999-9999
        formatted = '(${limitedDigits.substring(0, 2)}) ${limitedDigits.substring(2, 7)}-${limitedDigits.substring(7)}';
      }
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
