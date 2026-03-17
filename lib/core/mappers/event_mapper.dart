import 'package:agendat/core/dto/event_list_dto.dart';
import 'package:agendat/core/models/event.dart';

extension EventMapper on EventListDto {
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
      startDate: startDate != null ? DateTime.tryParse(startDate!) : null,
      endDate: endDate != null ? DateTime.tryParse(endDate!) : null,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
