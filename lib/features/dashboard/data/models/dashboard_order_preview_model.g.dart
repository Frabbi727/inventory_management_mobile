// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_order_preview_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardOrderPreviewModel _$DashboardOrderPreviewModelFromJson(
  Map<String, dynamic> json,
) => DashboardOrderPreviewModel(
  id: (json['id'] as num?)?.toInt(),
  orderNo: json['order_no'] as String?,
  status: DashboardOrderPreviewModel._statusFromJson(json['status'] as String?),
  orderDate: json['order_date'] as String?,
  intendedDeliveryAt: json['intended_delivery_at'] as String?,
  grandTotal: json['grand_total'] as num?,
  customer: json['customer'] == null
      ? null
      : DashboardCustomerModel.fromJson(
          json['customer'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$DashboardOrderPreviewModelToJson(
  DashboardOrderPreviewModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'order_no': instance.orderNo,
  'status': DashboardOrderPreviewModel._statusToJson(instance.status),
  'order_date': instance.orderDate,
  'intended_delivery_at': instance.intendedDeliveryAt,
  'grand_total': instance.grandTotal,
  'customer': instance.customer?.toJson(),
};
