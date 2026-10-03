import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'admin_order_status.freezed.dart';

@freezed
abstract class AdminOrderStatus with _$AdminOrderStatus {
  const factory AdminOrderStatus.new_() = _New;
  const factory AdminOrderStatus.preparing() = _Preparing;
  const factory AdminOrderStatus.ready() = _Ready;
  const factory AdminOrderStatus.dispatched() = _Dispatched;
  const factory AdminOrderStatus.completed() = _Completed;
  const factory AdminOrderStatus.cancelled() = _Cancelled;
  const factory AdminOrderStatus.unknown() = _Unknown;
}

AdminOrderStatus _adminOrderStatusFromApi(String value) {
  return switch (value) {
    'new' => const AdminOrderStatus.new_(),
    'preparing' => const AdminOrderStatus.preparing(),
    'ready' => const AdminOrderStatus.ready(),
    'dispatched' => const AdminOrderStatus.dispatched(),
    'completed' => const AdminOrderStatus.completed(),
    'cancelled' => const AdminOrderStatus.cancelled(),
    _ => const AdminOrderStatus.unknown(),
  };
}

class AdminOrderStatusConverter implements JsonConverter<AdminOrderStatus, String> {
  const AdminOrderStatusConverter();

  @override
  AdminOrderStatus fromJson(String json) => _adminOrderStatusFromApi(json);

  @override
  String toJson(AdminOrderStatus object) => object.apiValue;
}

// All status values in order
const List<AdminOrderStatus> adminOrderStatusValues = [
  AdminOrderStatus.new_(),
  AdminOrderStatus.preparing(),
  AdminOrderStatus.ready(),
  AdminOrderStatus.dispatched(),
  AdminOrderStatus.completed(),
  AdminOrderStatus.cancelled(),
  AdminOrderStatus.unknown(),
];

// Status values for UI (excluding unknown)
const List<AdminOrderStatus> adminOrderStatusValuesForUI = [
  AdminOrderStatus.new_(),
  AdminOrderStatus.preparing(),
  AdminOrderStatus.ready(),
  AdminOrderStatus.dispatched(),
  AdminOrderStatus.completed(),
  AdminOrderStatus.cancelled(),
];

extension AdminOrderStatusApi on AdminOrderStatus {
  String get apiValue => when(
    new_: () => 'new',
    preparing: () => 'preparing',
    ready: () => 'ready',
    dispatched: () => 'dispatched',
    completed: () => 'completed',
    cancelled: () => 'cancelled',
    unknown: () => 'unknown',
  );
}

extension AdminOrderStatusTransitions on AdminOrderStatus {
  bool get isFinal => this == const AdminOrderStatus.completed() || this == const AdminOrderStatus.cancelled();

  List<AdminOrderStatus> validTransitions({required bool isDelivery}) {
    return when(
      new_: () => [const AdminOrderStatus.preparing(), const AdminOrderStatus.cancelled()],
      preparing: () => [const AdminOrderStatus.ready(), const AdminOrderStatus.cancelled()],
      ready: () => isDelivery
          ? [const AdminOrderStatus.dispatched(), const AdminOrderStatus.cancelled()]
          : [const AdminOrderStatus.completed(), const AdminOrderStatus.cancelled()],
      dispatched: () => [const AdminOrderStatus.completed(), const AdminOrderStatus.cancelled()],
      completed: () => [],
      cancelled: () => [],
      unknown: () => [],
    );
  }

  String get label => when(
    new_: () => 'Novo',
    preparing: () => 'Preparando',
    ready: () => 'Pronto',
    dispatched: () => 'Enviado',
    completed: () => 'Concluído',
    cancelled: () => 'Cancelado',
    unknown: () => 'Desconhecido',
  );

  int get sortOrder => when(
    new_: () => 0,
    preparing: () => 1,
    ready: () => 2,
    dispatched: () => 3,
    completed: () => 4,
    cancelled: () => 5,
    unknown: () => 99,
  );

  Color get color => when(
    new_: () => Colors.blue,
    preparing: () => Colors.orange,
    ready: () => Colors.purple,
    dispatched: () => Colors.teal,
    completed: () => Colors.green,
    cancelled: () => Colors.red,
    unknown: () => Colors.grey,
  );
}