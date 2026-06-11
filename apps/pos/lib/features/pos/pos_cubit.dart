import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String? thumbnail;
  int quantity;

  CartItem({
    required String id,
    required String name,
    required double price,
    this.thumbnail,
    int quantity = 1,
  })  : id = id,
        name = name,
        price = price,
        quantity = quantity;

  double get total => price * quantity;
}

class PosState {
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> categories;
  final List<CartItem> cart;
  final String? selectedCategory;
  final String searchQuery;
  final bool loading;
  final List<Map<String, dynamic>> basketSuggestions;
  final bool loadingBasket;

  const PosState({
    List<Map<String, dynamic>> products = const [],
    List<Map<String, dynamic>> categories = const [],
    List<CartItem> cart = const [],
    this.selectedCategory,
    String searchQuery = '',
    bool loading = true,
    List<Map<String, dynamic>> basketSuggestions = const [],
    bool loadingBasket = false,
  })  : products = products,
        categories = categories,
        cart = cart,
        searchQuery = searchQuery,
        loading = loading,
        basketSuggestions = basketSuggestions,
        loadingBasket = loadingBasket;

  double get cartTotal => cart.fold(0.0, (sum, item) => sum + item.total);
  int get cartItemCount => cart.fold(0, (sum, item) => sum + item.quantity);

  List<Map<String, dynamic>> get filteredProducts {
    var filtered = products;
    if (selectedCategory != null) {
      filtered = filtered
          .where((p) => _categoryIdOf(p) == selectedCategory)
          .toList();
    }
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery.toLowerCase());
      }).toList();
    }
    return filtered;
  }

  static String? _categoryIdOf(Map<String, dynamic> product) {
    final direct = product['category_id']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    final category = product['category'];
    if (category is Map) return category['id']?.toString();
    return null;
  }

  PosState copyWith({
    List<Map<String, dynamic>>? products,
    List<Map<String, dynamic>>? categories,
    List<CartItem>? cart,
    String? selectedCategory,
    String? searchQuery,
    bool? loading,
    bool clearCategory = false,
    List<Map<String, dynamic>>? basketSuggestions,
    bool? loadingBasket,
  }) {
    return PosState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      cart: cart ?? this.cart,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      loading: loading ?? this.loading,
      basketSuggestions: basketSuggestions ?? this.basketSuggestions,
      loadingBasket: loadingBasket ?? this.loadingBasket,
    );
  }
}

class PosCubit extends Cubit<PosState> {
  final NestJSClient _api;

  PosCubit(NestJSClient api) : _api = api, super(const PosState());

  NestJSClient get api => _api;

  String _mapPaymentMethod(String method) {
    final cleaned = method.toLowerCase().trim();
    if (cleaned == 'bank_transfer' || cleaned == 'bank' || cleaned == 'vietqr') {
      return 'bank'; 
    }
    if (cleaned == 'card' || cleaned == 'credit_card') {
      return 'credit_card';
    }
    if (cleaned == 'cash' || cleaned == 'tiền mặt') {
      return 'cash';
    }
    if (cleaned == 'momo') return 'momo';
    if (cleaned == 'vnpay') return 'vnpay';
    return 'cash'; 
  }

  Future<Map<String, dynamic>> checkout({
    required String method,
    required double paidAmount,
    String? customerId,
  }) async {
    if (state.cart.isEmpty) {
      throw Exception('Giỏ hàng trống');
    }

    final items = state.cart
        .map(
          (c) => {
            'product_id': c.id,
            'quantity': c.quantity,
            'unit_price': c.price,
          },
        )
        .toList();

    final String clientGeneratedOrderNumber = 'POS${DateTime.now().millisecondsSinceEpoch}';
    final String databaseMappedMethod = _mapPaymentMethod(method);

    // 1. Khởi tạo đơn hàng dạng nháp (Đường dẫn gốc tự động kết hợp BaseURL)
    final orderRes = await _api.post(
      '/orders',
      data: {
        'items': items,
        'source': 'pos',
        'order_number': clientGeneratedOrderNumber,
        'payment_method': databaseMappedMethod,
        if (customerId != null) 'customer_id': customerId,
      },
    );

    final orderData = orderRes.data?['data'];
    var order = orderData is Map
        ? Map<String, dynamic>.from(orderData)
        : <String, dynamic>{};
    final orderId = order['id']?.toString();
    if (orderId == null || orderId.isEmpty) {
      throw Exception('Không tạo được đơn hàng trên hệ thống');
    }

    // 2. Tự động duyệt đơn 
    try {
      final approveRes = await _api.post('/orders/$orderId/approve');
      final approveData = approveRes.data?['data'];
      if (approveData is Map) {
        order = Map<String, dynamic>.from(approveData);
      }
    } catch (e) {
      throw Exception('Xác nhận xuất kho sản phẩm thất bại hoặc hết hàng: $e');
    }

    // 3. Ghi nhận lịch sử giao dịch
    try {
      final payRes = await _api.post(
        '/orders/$orderId/payment',
        data: {
          'amount': paidAmount,
          'method': databaseMappedMethod,
          'note': 'POS Checkout Instant Payment',
        },
      );
      final payData = payRes.data?['data'];
      if (payData is Map && payData['order'] is Map) {
        order = Map<String, dynamic>.from(payData['order']);
      }
    } catch (e) {
      throw Exception('Lưu giữ lịch sử ghi nhận thanh toán thất bại: $e');
    }

    return order;
  }

  // 💡 Đã làm sạch bớt các cụm từ /api/v1 dư thừa để kích hoạt nhận diện dữ liệu chuẩn xác
  Future<void> loadProducts() async {
    try {
      final response = await _api.get(
        '/catalog/products',
        queryParams: {'limit': 100},
      );
      final data = response.data?['data'];
      final productList = data is Map ? data['data'] : data;
      final products = productList is List
          ? productList.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      List<Map<String, dynamic>> categories = [];
      try {
        final catResponse = await _api.get('/catalog/categories');
        final catData = catResponse.data?['data'];
        categories = catData is List
            ? catData.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [];
      } catch (_) {}

      emit(
        state.copyWith(
          products: products,
          categories: categories,
          loading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }

  void addToCart(Map<String, dynamic> product) {
    final cart = List<CartItem>.from(state.cart);
    final id = product['id'].toString();
    final existing = cart.indexWhere((item) => item.id == id);

    if (existing >= 0) {
      cart[existing].quantity++;
    } else {
      cart.add(
        CartItem(
          id: id,
          name: product['name'] ?? '',
          price: _priceOf(product),
          thumbnail: _thumbnailOf(product),
        ),
      );
    }
    emit(state.copyWith(cart: cart));
    loadBasketSuggestions();
  }

  Future<void> loadBasketSuggestions() async {
    if (state.cart.isEmpty) {
      emit(state.copyWith(basketSuggestions: []));
      return;
    }
    final productIds = state.cart.map((c) => c.id).toList();
    emit(state.copyWith(loadingBasket: true));
    try {
      final res = await _api.post<dynamic>(
        '/ai/recommendations/basket',
        data: {'productIds': productIds},
      );
      final raw = res.data;
      final data = raw is Map ? (raw['data'] ?? raw) : raw;
      final cartIds = state.cart.map((c) => c.id).toSet();
      final suggestions = <Map<String, dynamic>>[];
      if (data is List) {
        for (final rule in data.whereType<Map>()) {
          final consequents = rule['consequents'];
          if (consequents is List) {
            for (final cId in consequents) {
              final id = cId.toString();
              if (!cartIds.contains(id)) {
                final prod = state.products.firstWhere(
                  (p) => p['id'].toString() == id,
                  orElse: () => <String, dynamic>{},
                );
                if (prod.isNotEmpty) {
                  suggestions.add({
                    ...prod,
                    '_confidence': rule['confidence'],
                  });
                }
              }
            }
          }
        }
      }
      emit(state.copyWith(
        loadingBasket: false,
        basketSuggestions: suggestions.take(4).toList(),
      ));
    } catch (_) {
      emit(state.copyWith(loadingBasket: false, basketSuggestions: []));
    }
  }

  void removeFromCart(String id) {
    final cart = state.cart.where((item) => item.id != id).toList();
    emit(state.copyWith(cart: cart));
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeFromCart(id);
      return;
    }
    final cart = List<CartItem>.from(state.cart);
    final idx = cart.indexWhere((item) => item.id == id);
    if (idx >= 0) {
      cart[idx].quantity = quantity;
      emit(state.copyWith(cart: cart));
    }
  }

  void clearCart() {
    emit(state.copyWith(cart: [], basketSuggestions: []));
  }

  void setCategory(String? categoryId) {
    emit(
      state.copyWith(
        selectedCategory: categoryId,
        clearCategory: categoryId == null,
      ),
    );
  }

  void setSearch(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  double _priceOf(Map<String, dynamic> product) {
    return (product['base_price'] as num?)?.toDouble() ??
        (product['price'] as num?)?.toDouble() ??
        0;
  }

  String? _thumbnailOf(Map<String, dynamic> product) {
    final thumbnail = product['thumbnail'];
    if (thumbnail is String && thumbnail.isNotEmpty) return thumbnail;

    final images = product['images'];
    if (images is List && images.isNotEmpty && images.first is Map) {
      final first = images.first as Map;
      return (first['thumbnail_url'] ?? first['url'])?.toString();
    }
    return null;
  }
}