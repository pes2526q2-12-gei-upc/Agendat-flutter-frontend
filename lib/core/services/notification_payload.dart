import 'dart:convert';

class NotificationPayload {
  const NotificationPayload({
    this.id,
    this.title,
    this.body,
    this.notificationType,
    this.actor,
    this.action,
    this.target,
    this.preview,
    this.data = const <String, dynamic>{},
    this.readAt,
    this.createdAt,
  });

  final String? id;
  final String? title;
  final String? body;
  final String? notificationType;
  final NotificationActor? actor;
  final NotificationAction? action;
  final NotificationTarget? target;
  final NotificationPreview? preview;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime? createdAt;

  static NotificationPayload? fromData(Map<String, dynamic> data) {
    final actor = NotificationActor.fromJson(_jsonMapValue(data['actor'])) ??
        _legacyActorFromData(data);
    final action = NotificationAction.fromJson(_jsonMapValue(data['action'])) ??
        _legacyActionFromData(data);
    final target = NotificationTarget.fromJson(_jsonMapValue(data['target'])) ??
        _legacyTargetFromData(data);
    final preview =
        NotificationPreview.fromJson(_jsonMapValue(data['preview'])) ??
            _legacyPreviewFromData(data);

    final title = _stringValue(data['title']);
    final body = _stringValue(data['body']);
    final notification = NotificationPayload(
      id: _stringValue(data['id']) ?? _stringValue(data['notification_id']),
      title: title,
      body: body,
      notificationType: _stringValue(data['notification_type']),
      actor: actor,
      action: action,
      target: target,
      preview: preview,
      data: Map<String, dynamic>.from(data),
      readAt: _dateTimeValue(data['read_at']),
      createdAt: _dateTimeValue(data['created_at']),
    );

    if (notification.hasStructuredDisplay || title != null || body != null) {
      return notification;
    }
    return null;
  }

  bool get hasStructuredDisplay => action?.key != null;

  Map<String, dynamic> toNotificationPayload() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (notificationType != null) 'notification_type': notificationType,
      if (actor != null) 'actor': actor!.toJson(),
      if (action != null) 'action': action!.toJson(),
      if (target != null) 'target': target!.toJson(),
      if (preview != null) 'preview': preview!.toJson(),
      if (data.isNotEmpty) 'data': data,
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

class NotificationActor {
  const NotificationActor({
    this.id,
    this.username,
    this.displayName,
    this.profileImage,
  });

  final String? id;
  final String? username;
  final String? displayName;
  final String? profileImage;

  static NotificationActor? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final actor = NotificationActor(
      id: _stringValue(json['id']),
      username: _stringValue(json['username']),
      displayName:
          _stringValue(json['display_name']) ?? _stringValue(json['name']),
      profileImage: _stringValue(json['profile_image']),
    );
    return actor.isEmpty ? null : actor;
  }

  bool get isEmpty =>
      id == null && username == null && displayName == null && profileImage == null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (profileImage != null) 'profile_image': profileImage,
    };
  }
}

class NotificationAction {
  const NotificationAction({this.key, this.label});

  final String? key;
  final String? label;

  static NotificationAction? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final action = NotificationAction(
      key: _stringValue(json['key']),
      label: _stringValue(json['label']),
    );
    return action.key == null && action.label == null ? null : action;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (key != null) 'key': key,
      if (label != null) 'label': label,
    };
  }
}

class NotificationTarget {
  const NotificationTarget({this.type, this.id, this.name, this.route});

  final String? type;
  final String? id;
  final String? name;
  final NotificationRoute? route;

  static NotificationTarget? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final target = NotificationTarget(
      type: _stringValue(json['type']),
      id: _stringValue(json['id']),
      name: _stringValue(json['name']),
      route: NotificationRoute.fromJson(_jsonMapValue(json['route'])),
    );
    return target.isEmpty ? null : target;
  }

  bool get isEmpty => type == null && id == null && name == null && route == null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (type != null) 'type': type,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (route != null) 'route': route!.toJson(),
    };
  }
}

class NotificationRoute {
  const NotificationRoute({required this.name, this.params = const {}});

  final String name;
  final Map<String, dynamic> params;

  static NotificationRoute? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final name = _stringValue(json['name']);
    if (name == null) return null;
    final rawParams = json['params'];
    return NotificationRoute(
      name: name,
      params: rawParams is Map
          ? rawParams.map((key, value) => MapEntry(key.toString(), value))
          : const <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'name': name, 'params': params};
  }
}

class NotificationPreview {
  const NotificationPreview({this.kind, this.text, this.imageUrl});

  final String? kind;
  final String? text;
  final String? imageUrl;

  static NotificationPreview? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final preview = NotificationPreview(
      kind: _stringValue(json['kind']),
      text: _stringValue(json['text']),
      imageUrl: _stringValue(json['image_url']),
    );
    return preview.kind == null && preview.text == null && preview.imageUrl == null
        ? null
        : preview;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (kind != null) 'kind': kind,
      if (text != null) 'text': text,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}

NotificationActor? _legacyActorFromData(Map<String, dynamic> data) {
  final displayName = _stringValue(data['actor_name']);
  final profileImage = _firstStringValue(data, const [
    'actor_profile_image',
    'sender_profile_image',
    'sender_avatar',
    'sender_avatar_url',
    'actor_avatar',
    'actor_avatar_url',
    'profile_image',
    'avatar',
    'avatar_url',
  ]);
  final id = _stringValue(data['user_id']) ?? _stringValue(data['actor_id']);

  if (displayName == null && profileImage == null && id == null) return null;
  return NotificationActor(
    id: id,
    displayName: displayName,
    profileImage: profileImage,
  );
}

NotificationAction? _legacyActionFromData(Map<String, dynamic> data) {
  final actionKey = _stringValue(data['action_key']);
  if (actionKey != null) return NotificationAction(key: actionKey);

  final type = _stringValue(data['notification_type']);
  if (type == 'chat_message' || _stringValue(data['chat_id']) != null) {
    return const NotificationAction(key: 'chat.message');
  }
  return null;
}

NotificationTarget? _legacyTargetFromData(Map<String, dynamic> data) {
  final chatId = _stringValue(data['chat_id']);
  if (chatId == null) return null;

  final messageId = _stringValue(data['message_id']);
  final userId = _stringValue(data['user_id']) ?? _stringValue(data['actor_id']);
  return NotificationTarget(
    type: 'chat',
    id: chatId,
    name: _stringValue(data['conversation_title']),
    route: NotificationRoute(
      name: 'chat_detail',
      params: <String, dynamic>{
        'chat_id': chatId,
        if (messageId != null) 'message_id': messageId,
        if (userId != null) 'user_id': userId,
      },
    ),
  );
}

NotificationPreview? _legacyPreviewFromData(Map<String, dynamic> data) {
  final body = _stringValue(data['body']);
  final imageUrl = _stringValue(data['chat_image_url']);
  if (body == null && imageUrl == null) return null;
  return NotificationPreview(
    kind: imageUrl == null ? null : 'image',
    text: body,
    imageUrl: imageUrl,
  );
}

Map<String, dynamic>? _jsonMapValue(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  if (value is! String) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {
    return null;
  }
  return null;
}

String? _stringValue(Object? value) {
  final string = value?.toString().trim();
  if (string == null || string.isEmpty) return null;
  return string;
}

DateTime? _dateTimeValue(Object? value) {
  final string = _stringValue(value);
  return string == null ? null : DateTime.tryParse(string);
}

String? _firstStringValue(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = _stringValue(data[key]);
    if (value != null) return value;
  }
  return null;
}
