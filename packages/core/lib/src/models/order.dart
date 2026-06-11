import 'package:equatable/equatable.dart';

import 'enums.dart';

class Order extends Equatable {
  final String id;
  final String tenantId;
  final String? branchId;
  final String? customerId;
  final String? shiftId;
  final String orderNumber;
  final OrderSource source;
  final OrderStatus status;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double shippingFee;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String? note;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.tenantId,
    this.branchId,
    this.customerId,
    this.shiftId,
    required this.orderNumber,
    this.source = OrderSource.pos,
    this.status = OrderStatus.draft,
    this.subtotal = 0.0,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.shippingFee = 0.0,
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    this.changeAmount = 0.0,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentMethod = PaymentMethod.cash,
    this.note,
    this.isSynced = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String?,
      customerId: json['customer_id'] as String?,
      shiftId: json['shift_id'] as String?,
      orderNumber: json['order_number'] as String,
      source: json['source'] != null
          ? OrderSource.fromJson(json['source'] as String)
          : OrderSource.pos,
      status: json['status'] != null
          ? OrderStatus.fromJson(json['status'] as String)
          : OrderStatus.draft,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount:
          (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shipping_fee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      changeAmount:
          (json['change_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'] != null
          ? PaymentStatus.fromJson(json['payment_status'] as String)
          : PaymentStatus.unpaid,
      paymentMethod: json['payment_method'] != null
          ? PaymentMethod.fromJson(json['payment_method'] as String)
          : PaymentMethod.cash,
      note: json['note'] as String?,
      isSynced: json['is_synced'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'customer_id': customerId,
      'shift_id': shiftId,
      'order_number': orderNumber,
      'source': source.toJson(),
      'status': status.toJson(),
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'shipping_fee': shippingFee,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'payment_status': paymentStatus.toJson(),
      'payment_method': paymentMethod.toJson(),
      'note': note,
      'is_synced': isSynced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Order copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? customerId,
    String? shiftId,
    String? orderNumber,
    OrderSource? source,
    OrderStatus? status,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? shippingFee,
    double? totalAmount,
    double? paidAmount,
    double? changeAmount,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? note,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      customerId: customerId ?? this.customerId,
      shiftId: shiftId ?? this.shiftId,
      orderNumber: orderNumber ?? this.orderNumber,
      source: source ?? this.source,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      shippingFee: shippingFee ?? this.shippingFee,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        branchId,
        customerId,
        shiftId,
        orderNumber,
        source,
        status,
        subtotal,
        discountAmount,
        taxAmount,
        shippingFee,
        totalAmount,
        paidAmount,
        changeAmount,
        paymentStatus,
        paymentMethod,
        note,
        isSynced,
        createdAt,
        updatedAt,
      ];
}
