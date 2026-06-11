part of 'ai_cubit.dart';

class AiState {
  final List<Map<String, dynamic>> recommendations;
  final List<Map<String, dynamic>> similarProducts;
  final bool loadingRec;
  final bool loadingSimilar;

  const AiState({
    this.recommendations = const [],
    this.similarProducts = const [],
    this.loadingRec = false,
    this.loadingSimilar = false,
  });

  AiState copyWith({
    List<Map<String, dynamic>>? recommendations,
    List<Map<String, dynamic>>? similarProducts,
    bool? loadingRec,
    bool? loadingSimilar,
  }) {
    return AiState(
      recommendations: recommendations ?? this.recommendations,
      similarProducts: similarProducts ?? this.similarProducts,
      loadingRec: loadingRec ?? this.loadingRec,
      loadingSimilar: loadingSimilar ?? this.loadingSimilar,
    );
  }
}
