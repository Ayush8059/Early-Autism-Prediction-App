import 'package:supabase_flutter/supabase_flutter.dart';

class ChildService {
  ChildService(this._client);

  final SupabaseClient _client;

  Future<String> getOrCreateDefaultChildId() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Please sign in first.');
    }

    final existing = await _client
        .from('children')
        .select('id')
        .eq('parent_id', user.id)
        .order('created_at')
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final created = await _client
        .from('children')
        .insert({
          'parent_id': user.id,
          'name': 'My Child',
        })
        .select('id')
        .single();

    return created['id'] as String;
  }
}
