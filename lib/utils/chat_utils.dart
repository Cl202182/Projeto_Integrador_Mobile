import 'package:flutter/foundation.dart';

/// Utilitários para chat - garantem consistência entre plataformas
class ChatUtils {
  /// Gera um chatId consistente entre dois usuários
  /// Usa ordenação alfabética dos IDs para garantir o mesmo resultado
  /// independente da ordem dos parâmetros
  static String generateChatId(String userId1, String userId2) {
    // Ordenação baseada em ASCII - SEMPRE a mesma em qualquer plataforma
    List<int> codes1 = userId1.codeUnits;
    List<int> codes2 = userId2.codeUnits;

    String first, second;

    // Comparar byte por byte
    bool userId1IsFirst = true;
    int minLength =
        codes1.length < codes2.length ? codes1.length : codes2.length;

    for (int i = 0; i < minLength; i++) {
      if (codes1[i] < codes2[i]) {
        userId1IsFirst = true;
        break;
      } else if (codes1[i] > codes2[i]) {
        userId1IsFirst = false;
        break;
      }
    }

    // Se todos os caracteres são iguais até agora, o menor string vem primeiro
    if (codes1.length != codes2.length) {
      userId1IsFirst = codes1.length < codes2.length;
    }

    if (userId1IsFirst) {
      first = userId1;
      second = userId2;
    } else {
      first = userId2;
      second = userId1;
    }

    String chatId = '${first}_${second}';

    // Debug DETALHADO
    print('🔗🔗🔗 CHAT DEBUG DETALHADO 🔗🔗🔗');
    print('🔗 Input 1: "$userId1"');
    print('🔗 Input 2: "$userId2"');
    print('🔗 ASCII codes 1: $codes1');
    print('🔗 ASCII codes 2: $codes2');
    print('🔗 userId1IsFirst: $userId1IsFirst');
    print('🔗 First: "$first"');
    print('🔗 Second: "$second"');
    print('🔗 ChatId final: "$chatId"');
    print('🔗 Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
    print('🔗🔗🔗 FIM DEBUG 🔗🔗🔗');

    return chatId;
  }

  /// Extrai os participantes de um chatId
  static List<String> getParticipantsFromChatId(String chatId) {
    return chatId.split('_');
  }

  /// Verifica se um usuário participa de um chat
  static bool isUserInChat(String chatId, String userId) {
    return chatId.contains(userId);
  }

  /// Obtém o ID do outro participante do chat
  static String getOtherParticipant(String chatId, String currentUserId) {
    List<String> participants = getParticipantsFromChatId(chatId);
    return participants.firstWhere((id) => id != currentUserId);
  }
}
