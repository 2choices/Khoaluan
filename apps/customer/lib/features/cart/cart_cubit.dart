import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'cart_state.dart';

const _kCartStorageKey = 'omnigo_customer_cart_v1';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState()) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCartStorageKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw);
      if (list is! List) return;
      final items = list
          .whereType<Map>()
          .map((e) => CartItem(
                productId: e['productId']?.toString() ?? '',
                name: e['name']?.toString() ?? '',
                price: (e['price'] as num?)?.toDouble() ?? 0,
                quantity: (e['quantity'] as num?)?.toInt() ?? 1,
                thumbnail: e['thumbnail']?.toString(),
              ))
          .where((e) => e.productId.isNotEmpty)
          .toList();
      if (items.isEmpty) return;
      emit(state.copyWith(items: items));
    } catch (_) {
      // ignore corrupt cache
    }
  }

  Future<void> _persist(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(items
          .map((e) => {
                'productId': e.productId,
                'name': e.name,
                'price': e.price,
                'quantity': e.quantity,
                'thumbnail': e.thumbnail,
              })
          .toList());
      await prefs.setString(_kCartStorageKey, raw);
    } catch (_) {
      // ignore persistence error
    }
  }

  void addItem({
    required String productId,
    required String name,
    required double price,
    int quantity = 1,
    String? thumbnail,
  }) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere((e) => e.productId == productId);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + quantity);
    } else {
      items.add(CartItem(
        productId: productId,
        name: name,
        price: price,
        quantity: quantity,
        thumbnail: thumbnail,
      ));
    }
    emit(state.copyWith(items: items));
    _persist(items);
  }

  void removeItem(String productId) {
    final items = state.items.where((e) => e.productId != productId).toList();
    emit(state.copyWith(items: items));
    _persist(items);
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final items = state.items.map((e) {
      return e.productId == productId ? e.copyWith(quantity: quantity) : e;
    }).toList();
    emit(state.copyWith(items: items));
    _persist(items);
  }

  void clearCart() {
    emit(const CartState());
    _persist(const []);
  }
}
