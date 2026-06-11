enum OrderStatus {
  draft,
  confirmed,
  processing,
  completed,
  cancelled,
  returned;

  static OrderStatus fromJson(String value) =>
      OrderStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => OrderStatus.draft,
      );

  String toJson() => name;
}

enum PaymentStatus {
  unpaid,
  partial,
  paid,
  refunded;

  static PaymentStatus fromJson(String value) =>
      PaymentStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PaymentStatus.unpaid,
      );

  String toJson() => name;
}

enum PaymentMethod {
  cash,
  bankTransfer,
  momo,
  zalopay,
  vnpay,
  card,
  other;

  static PaymentMethod fromJson(String value) =>
      PaymentMethod.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PaymentMethod.cash,
      );

  String toJson() => name;
}

enum OrderSource {
  pos,
  online,
  app,
  marketplace,
  other;

  static OrderSource fromJson(String value) =>
      OrderSource.values.firstWhere(
        (e) => e.name == value,
        orElse: () => OrderSource.pos,
      );

  String toJson() => name;
}

enum LoyaltyTier {
  none,
  bronze,
  silver,
  gold,
  platinum,
  diamond;

  static LoyaltyTier fromJson(String value) =>
      LoyaltyTier.values.firstWhere(
        (e) => e.name == value,
        orElse: () => LoyaltyTier.none,
      );

  String toJson() => name;
}

enum UserStatus {
  active,
  inactive,
  suspended,
  pending;

  static UserStatus fromJson(String value) =>
      UserStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => UserStatus.active,
      );

  String toJson() => name;
}

enum ShiftStatus {
  open,
  closed,
  suspended;

  static ShiftStatus fromJson(String value) =>
      ShiftStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ShiftStatus.open,
      );

  String toJson() => name;
}

enum VoucherType {
  percentage,
  fixedAmount,
  freeShipping,
  buyXGetY;

  static VoucherType fromJson(String value) =>
      VoucherType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => VoucherType.percentage,
      );

  String toJson() => name;
}

enum VoucherStatus {
  active,
  inactive,
  expired,
  used;

  static VoucherStatus fromJson(String value) =>
      VoucherStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => VoucherStatus.active,
      );

  String toJson() => name;
}
