import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/dto/event_list_dto.dart';
import 'package:agendat/core/mappers/event_mapper.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/services/events_response_parser.dart';

class EventsApi {
  static const String _path = '/api/events/';

  Future<EventExtended> fetchEventByCode(String eventCode) async {
    final code = eventCode.trim();
    if (code.isEmpty) {
      throw const FormatException(
        'El codi de l\'esdeveniment no pot ser buit.',
      );
    }
    final response = await ApiClient.get('$_path$code/');
    final decoded = ApiClient.decodeBody(response);
    final Map<String, dynamic> json = decoded is Map<String, dynamic>
        ? decoded
        : EventsResponseParser.parseSingleEventBody(response.body, code);
    return EventDto.fromJson(json).toExtendedDomain();
  }

  Future<List<EventListDto>> fetchEvents({EventFilters? filters}) async {
    final params = _buildQueryParams(filters);
    final response = await ApiClient.get(_path, queryParams: params);
    final jsonList = ApiClient.decodeListBody(response);
    return jsonList.map(EventListDto.fromJson).toList();
  }

  Map<String, String> _buildQueryParams(EventFilters? filters) {
    final now = DateTime.now();
    final defaultFrom = _subtractMonths(now, 6);

    final params = <String, String>{
      'date_from': _formatDate(filters?.dateFrom ?? defaultFrom),
    };

    if (filters != null) {
      final filterParams = filters.toQueryParams();
      // date_from already set above (with fallback); override if explicit
      if (filters.dateFrom != null) {
        params['date_from'] = filterParams['date_from']!;
      }
      filterParams.remove('date_from');
      params.addAll(filterParams);
    }

    return params;
  }

  static DateTime _subtractMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + (date.month - 1) - months;
    final year = totalMonths ~/ 12;
    final month = (totalMonths % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }

  static String _formatDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}
