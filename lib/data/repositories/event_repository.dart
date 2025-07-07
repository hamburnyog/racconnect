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

      final birthdayResponse = await pb
          .collection('profiles')
          .getFullList(
            fields: 'lastName,firstName,middleName,birthdate',
            sort: '+birthdate',
          );

      for (var profile in birthdayResponse) {
        final birthdateRaw = profile.data['birthdate'];
        if (birthdateRaw == null) continue;

        final birthdate = DateTime.tryParse(birthdateRaw);
        if (birthdate == null) continue;

        final todayYear = DateTime.now().year;
        final adjustedBirthdate = DateTime(
          todayYear,
          birthdate.month,
          birthdate.day,
        );
        final date = adjustedBirthdate.toIso8601String().split('T')[0];

        final lastName = profile.data['lastName'] ?? '';
        final firstName = profile.data['firstName'] ?? '';
        final middleName = profile.data['middleName'] ?? '';
        final middleInitial = middleName.isNotEmpty ? '${middleName[0]}.' : '';

        final fullName = '$lastName, $firstName $middleInitial';
        final birthdayEntry = '$fullName,T=Birthday';

        groupedEvents.putIfAbsent(date, () => []);

        if (!groupedEvents[date]!.contains(birthdayEntry)) {
          groupedEvents[date]!.add(birthdayEntry);
        }
      }

      return groupedEvents;
    } catch (e) {
      rethrow;
    }
  }
}
