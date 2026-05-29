import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  DashboardService(this._client);

  final SupabaseClient _client;

  Future<int> getDailyStreak() async {
    final result = await _client.rpc<int>('get_daily_streak');
    return result;
  }

  Future<bool> hasCompletedActivityToday() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final startOfDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ).toUtc().toIso8601String();

    final rows = await _client
        .from('activity_completions')
        .select('id')
        .eq('parent_id', user.id)
        .gte('completed_at', startOfDay)
        .limit(1);

    return rows.isNotEmpty;
  }
}
