import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationBadgeState {
  final int unread;
  final bool loading;
  const NotificationBadgeState({this.unread = 0, this.loading = false});

  NotificationBadgeState copyWith({int? unread, bool? loading}) =>
      NotificationBadgeState(
        unread: unread ?? this.unread,
        loading: loading ?? this.loading,
      );
}

class NotificationBadgeCubit extends Cubit<NotificationBadgeState> {
  final NestJSClient api;
  Timer? _timer;

  NotificationBadgeCubit(this.api) : super(const NotificationBadgeState());

  Future<void> refresh() async {
    if (state.loading) return;
    emit(state.copyWith(loading: true));
    try {
      final res = await api.get<dynamic>('/notifications/unread-count');
      final raw = res.data;
      Map data = {};
      if (raw is Map && raw['data'] != null) {
        data = raw['data'] is Map ? raw['data'] as Map : {};
      } else if (raw is Map) {
        data = raw;
      }
      final count = (data['count'] as num?)?.toInt() ?? 0;
      emit(state.copyWith(unread: count, loading: false));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }

  /// Decrement locally (after marking 1 as read) without re-querying
  void decrement([int by = 1]) {
    final n = state.unread - by;
    emit(state.copyWith(unread: n < 0 ? 0 : n));
  }

  void clear() => emit(state.copyWith(unread: 0));

  void startAutoRefresh({Duration interval = const Duration(seconds: 60)}) {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
