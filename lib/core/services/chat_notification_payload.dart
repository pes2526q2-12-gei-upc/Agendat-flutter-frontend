class ChatNotificationPayload {
  const ChatNotificationPayload({
    required this.title,
    required this.body,
    this.actorProfileImage,
    this.chatImageUrl,
    this.actorName,
    this.chatId,
    this.messageId,
    this.conversationTitle,
  });

  final String title;
  final String body;
  final String? actorProfileImage;
  final String? chatImageUrl;
  final String? actorName;
  final String? chatId;
  final String? messageId;
  final String? conversationTitle;

  static ChatNotificationPayload? fromData(Map<String, dynamic> data) {
    final title = _stringValue(data['title']);
    final body = _stringValue(data['body']);
    if (title == null || body == null) return null;

    return ChatNotificationPayload(
      title: title,
      body: body,
      actorProfileImage: _firstStringValue(data, const [
        'actor_profile_image',
        'sender_profile_image',
        'sender_avatar',
        'sender_avatar_url',
        'actor_avatar',
        'actor_avatar_url',
        'profile_image',
        'avatar',
        'avatar_url',
      ]),
      chatImageUrl: _stringValue(data['chat_image_url']),
      actorName: _stringValue(data['actor_name']),
      chatId: _stringValue(data['chat_id']),
      messageId: _stringValue(data['message_id']),
      conversationTitle: _stringValue(data['conversation_title']),
    );
  }

  Map<String, dynamic> toNotificationPayload() {
    return <String, dynamic>{
      'title': title,
      'body': body,
      if (actorProfileImage != null) 'actor_profile_image': actorProfileImage,
      if (chatImageUrl != null) 'chat_image_url': chatImageUrl,
      if (actorName != null) 'actor_name': actorName,
      if (chatId != null) 'chat_id': chatId,
      if (messageId != null) 'message_id': messageId,
      if (conversationTitle != null) 'conversation_title': conversationTitle,
    };
  }

  static String? _stringValue(Object? value) {
    final string = value?.toString().trim();
    if (string == null || string.isEmpty) return null;
    return string;
  }

  static String? _firstStringValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = _stringValue(data[key]);
      if (value != null) return value;
    }
    return null;
  }
}
