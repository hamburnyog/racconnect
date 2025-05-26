import 'package:racconnect/data/models/event_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class EventRepository {
  final pb = PocketBaseClient.instance;

  Future<Map<String, List>> getAllEvents() async {
    try {
      final response = await pb
          .collection('holidays')
          .getFullList(fields: 'name,date', sort: '+date');
      final events =
          response.map((e) => EventModel.fromJson(e.toString())).toList();
      final groupedEvents = <String, List>{};
      for (var event in events) {
        final date = event.date.toIso8601String().split('T')[0];
        if (groupedEvents.containsKey(date)) {
          groupedEvents[date]!.add('${event.name},T=Holiday');
        } else {
          groupedEvents[date] = ['${event.name},T=Holiday'];
        }
      }

      // groupedEvents['2025-05-01']!.add('Ponce, W.,T=Birthday');

      return groupedEvents;
    } catch (e) {
      rethrow;
    }
  }
}
