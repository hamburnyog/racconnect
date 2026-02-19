import 'package:racconnect/data/models/forum_attendee.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class ForumRepository {
  final pb = PocketBaseClient.instance;

  Future<List<ForumAttendee>> getAttendees() async {
    try {
      final response = await pb
          .collection('forumAttendees')
          .getFullList();
      return response.map((e) => ForumAttendee.fromRecord(e)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching forum attendees: $e');
      rethrow;
    }
  }

  Future<ForumAttendee> addAttendee(ForumAttendee attendee) async {
    try {
      final body = attendee.toMap();
      final response = await pb.collection('forumAttendees').create(body: body);
      return ForumAttendee.fromRecord(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAttendee(String id) async {
    try {
      await pb.collection('forumAttendees').delete(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<ForumAttendee> updateAttendee(String id, ForumAttendee attendee) async {
    try {
      final body = attendee.toMap();
      final response =
          await pb.collection('forumAttendees').update(id, body: body);
      return ForumAttendee.fromRecord(response);
    } catch (e) {
      rethrow;
    }
  }
}
