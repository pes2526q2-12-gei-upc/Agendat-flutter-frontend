import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/dto/chat_dto.dart';
import 'package:agendat/core/dto/message_dto.dart';

/// Tipus de missatge suportats pel backend.
enum ChatMessageType { text, image, file }

extension on ChatMessageType {
  String get apiValue {
    switch (this) {
      case ChatMessageType.text:
        return 'text';
      case ChatMessageType.image:
        return 'image';
      case ChatMessageType.file:
        return 'file';
    }
  }
}

/// Payload per enviar un missatge al backend.
class SendMessageRequest {
  const SendMessageRequest({
    required this.content,
    this.type = ChatMessageType.text,
    this.fileUrl,
  });

  final String content;
  final ChatMessageType type;
  final String? fileUrl;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'content': content,
      'type': type.apiValue,
      if (fileUrl != null && fileUrl!.trim().isNotEmpty) 'file_url': fileUrl,
    };
  }
}

/// API HTTP per xats i missatges.
///
/// Notes de sincronització backend:
/// - Chat PK: `id_chat`
/// - Message PK: `id_message`
/// - Message type: `text | image | file`
class ChatsApi {
  static const String _chatsPath = '/api/chats/';

  /// Llista de xats de l'usuari autenticat.
  Future<List<ChatDto>> fetchChats() async {
    final response = await ApiClient.get(_chatsPath);
    final jsonList = ApiClient.decodeListBody(response);
    final chats = jsonList.map(ChatDto.fromJson);
    // Els xats amb «jo he bloquejat l’altre» no es mostren (com eliminats).
    // Si l’altre m’ha bloquejat, el xat es manté però ve inactiu (igual que sense amistat).
    return chats.where((chat) => !chat.blockedByMe).toList();
  }

  /// Detall d'un xat concret.
  Future<ChatDto> fetchChat(int chatId) async {
    final response = await ApiClient.get('$_chatsPath$chatId/');
    final decoded = ApiClient.decodeBody(response);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected API response format');
    }
    return ChatDto.fromJson(decoded);
  }

  /// Missatges del xat.
  Future<List<MessageDto>> fetchMessages(int chatId) async {
    final response = await ApiClient.get('$_chatsPath$chatId/messages/');
    final jsonList = ApiClient.decodeListBody(response);
    return jsonList.map(MessageDto.fromJson).toList();
  }

  /// Marca com a llegits els missatges rebuts pendents del xat.
  Future<void> markRead(int chatId) async {
    await ApiClient.postJson(
      '$_chatsPath$chatId/mark-read/',
      body: const <String, dynamic>{},
      acceptedStatusCodes: const {200, 204},
    );
  }

  /// Envia un missatge al xat.
  Future<MessageDto> sendMessage(int chatId, SendMessageRequest request) async {
    final response = await ApiClient.postJson(
      '$_chatsPath$chatId/messages/',
      body: request.toJson(),
      expectedStatusCode: 201,
    );
    final decoded = ApiClient.decodeBody(response);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected API response format');
    }
    return MessageDto.fromJson(decoded);
  }
}
