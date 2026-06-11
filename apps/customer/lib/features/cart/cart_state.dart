part of 'cart_cubit.dart';

class CartItem {
  final String productId;
  final String name;
  final double price;
  int quantity;
  final String? thumbnail;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.thumbnail,
  });

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        name: name,
        price: price,
        quantity: quantity ?? this.quantity,
        thumbnail: thumbnail,
      );

  double get total => price * quantity;
}

class CartState {
  final List<CartItem> items;

  const CartState({this.items = const []});

  CartState copyWith({List<CartItem>? items}) => CartState(items: items ?? this.items);

  int get totalQuantity => items.fold(0, (sum, e) => sum + e.quantity);
  double get totalAmount => items.fold(0.0, (sum, e) => sum + e.total);
  bool get isEmpty => items.isEmpty;
}
