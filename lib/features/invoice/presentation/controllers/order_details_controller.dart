import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../cart_orders/data/models/order_model.dart';
import '../../../cart_orders/data/repositories/order_repository.dart';

class OrderDetailsController extends GetxController {
  OrderDetailsController({required OrderRepository orderRepository})
    : _orderRepository = orderRepository;

  final OrderRepository _orderRepository;

  final order = Rxn<OrderModel>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  int? _orderId;

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    if (argument is int) {
      _orderId = argument;
      fetchOrderDetails();
    } else if (argument is OrderModel) {
      order.value = argument;
      _orderId = argument.id;
      if (_orderId != null) {
        fetchOrderDetails();
      }
    } else {
      errorMessage.value = 'Order details were not provided.';
    }
  }

  Future<void> fetchOrderDetails() async {
    final orderId = _orderId;
    if (orderId == null) {
      errorMessage.value = 'Order details were not provided.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _orderRepository.fetchOrderDetails(orderId);
      order.value = response.data;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to load order details right now.';
    } finally {
      isLoading.value = false;
    }
  }

  String formatCurrency(num? value) {
    if (value == null) {
      return '-';
    }

    return '৳${value.toStringAsFixed(2)}';
  }

  String paymentStatusLabel(String? value) {
    switch (value) {
      case 'paid':
        return 'Paid';
      case 'partial':
        return 'Partial';
      case 'not_paid':
        return 'Not paid';
      default:
        return '-';
    }
  }

  String formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    final normalized = value.split('T').first;
    final parts = normalized.split('-');
    if (parts.length != 3) {
      return normalized;
    }

    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  String formatDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) {
      return value;
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}, $hour:$minute';
  }
}
