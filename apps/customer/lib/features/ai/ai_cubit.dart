import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';

part 'ai_state.dart';

class AiCubit extends Cubit<AiState> {
  final NestJSClient _api;

  AiCubit(this._api) : super(const AiState());

  /// Gọi khi HomeScreen load — lấy gợi ý sản phẩm cho user hiện tại.
  Future<void> loadRecommendations({String? customerId}) async {
    if (state.loadingRec) return;
    emit(state.copyWith(loadingRec: true));
    try {
      final res = await _api.post<dynamic>(
        '/ai/recommendations',
        data: {
          if (customerId != null) 'customerId': customerId,
          'limit': 8,
        },
      );
      final raw = res.data;
      final data = raw is Map ? raw['data'] ?? raw : raw;
      final products = data is Map ? data['products'] : data;
      emit(state.copyWith(
        loadingRec: false,
        recommendations: products is List
            ? products.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : [],
      ));
    } catch (_) {
      emit(state.copyWith(loadingRec: false));
    }
  }

  /// Gọi từ ProductDetailScreen — lấy sản phẩm tương tự.
  Future<void> loadSimilarProducts(String productId) async {
    if (state.loadingSimilar) return;
    emit(state.copyWith(loadingSimilar: true, similarProducts: []));
    try {
      final res = await _api.get<dynamic>(
        '/ai/recommendations/similar/$productId',
        queryParams: {'limit': '6'},
      );
      final raw = res.data;
      final data = raw is Map ? raw['data'] ?? raw : raw;
      final products = data is Map ? data['products'] : data;
      emit(state.copyWith(
        loadingSimilar: false,
        similarProducts: products is List
            ? products.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : [],
      ));
    } catch (_) {
      emit(state.copyWith(loadingSimilar: false));
    }
  }

  void clearSimilar() => emit(state.copyWith(similarProducts: []));
}
