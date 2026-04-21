import 'package:agendat/core/dto/event_list_dto.dart';
import 'package:agendat/core/models/event.dart';

extension EventListDtoMapper on EventListDto {
  Event toDomain() {
    return Event(
      code: code,
      title: denomination?.trim() ?? '',
      subtitle: subtitle,
      free: free ?? false,
      categories: categories.map((c) => c.name).toList(),
      provincia: provincia,
      comarca: comarca,
      municipi: municipi,
      startDate: _parseDate(startDate),
      endDate: _parseDate(endDate),
      latitude: latitude,
      longitude: longitude,
    );
  }
}

extension EventDtoMapper on EventDto {
  EventExtended toExtendedDomain() {
    return EventExtended(
      code: code,
      title: denomination?.trim() ?? '',
      subtitle: subtitle,
      free: free ?? false,
      categories: categories.map((c) => c.name).toList(),
      provincia: provincia,
      comarca: comarca,
      municipi: municipi,
      startDate: _parseDate(startDate),
      endDate: _parseDate(endDate),
      latitude: latitude,
      longitude: longitude,
      description: description,
      url_activity: url_activity,
      url_ticket: url_ticket,
      schedule: schedule,
      modality: modality,
      urls: urls,
      images: images,
      videos: videos,
      documents: documents,
      address: address,
      email: email,
      locality: locality,
      url_locality: url_locality,
      telephone_locality: telephone_locality,
    );
  }

  Event toDomain() {
    return toExtendedDomain();
  }
}

DateTime? _parseDate(String? raw) {
  if (raw == null) return null;
  final parsed = DateTime.tryParse(raw);
  return parsed?.toLocal();
}
