import 'package:flutter/material.dart';

class AppColors {
  // Cores principais
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFF81C784);
  
  // Cores secundárias
  static const Color secondary = Color(0xFF2196F3);
  static const Color secondaryDark = Color(0xFF1976D2);
  static const Color secondaryLight = Color(0xFF64B5F6);
  
  // Cores de status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Cores neutras
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyDark = Color(0xFF616161);
  
  // Cores de fundo
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  
  // Cores de texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  
  // Cores de botões
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = secondary;
  static const Color buttonDisabled = grey;
  
  // Cores de notificação
  static const Color notificationSuccess = success;
  static const Color notificationWarning = warning;
  static const Color notificationError = error;
  static const Color notificationInfo = info;
  
  // Cores de jogo
  static const Color gameActive = success;
  static const Color gameInactive = grey;
  static const Color gamePending = warning;
  static const Color gameCancelled = error;
  
  // Cores de jogador
  static const Color playerActive = success;
  static const Color playerInactive = grey;
  static const Color playerPending = warning;
  static const Color playerSuspended = error;
  
  // Cores de posição
  static const Color positionGoalkeeper = Color(0xFF9C27B0);
  static const Color positionDefender = Color(0xFF2196F3);
  static const Color positionMidfielder = Color(0xFF4CAF50);
  static const Color positionForward = Color(0xFFFF9800);
  
  // Cores adicionais para compatibilidade
  static const Color alert = Color(0xFFFF5722);
  static const Color iconInactive = Color(0xFFBDBDBD);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color dividerLight = Color(0xFFE0E0E0);
}
