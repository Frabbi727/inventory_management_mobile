import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/cart_controller.dart';
import '../models/order_flow_step.dart';
import '../pages/new_order/order_cart_step_page.dart';
import '../pages/new_order/order_confirm_step_page.dart';
import '../pages/new_order/order_customer_step_page.dart';
import '../pages/new_order/order_products_step_page.dart';
import '../widgets/order_flow_widgets.dart';

class NewOrderPage extends StatefulWidget {
  const NewOrderPage({super.key});

  @override
  State<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends State<NewOrderPage> {
  late final CartController controller;
  late final List<OrderFlowStep> steps;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CartController>();
    steps = <OrderFlowStep>[
      OrderFlowStep(
        index: CartController.customerStep,
        title: 'Customer',
        builder: (_) => const OrderCustomerStepPage(),
      ),
      OrderFlowStep(
        index: CartController.productsStep,
        title: 'Products',
        builder: (_) => const OrderProductsStepPage(),
      ),
      OrderFlowStep(
        index: CartController.cartStep,
        title: 'Cart',
        builder: (_) => const OrderCartStepPage(),
      ),
      OrderFlowStep(
        index: CartController.confirmStep,
        title: 'Confirm',
        builder: (_) => const OrderConfirmStepPage(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('New Order')),
      body: SafeArea(
        bottom: false,
        child: Obx(
          () => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StepperWidget(
                      steps: steps
                          .map((step) => step.title)
                          .toList(growable: false),
                      currentStep: controller.currentStep.value,
                      onStepTap: controller.goToStep,
                    ),
                    if (controller.infoMessage.value != null) ...[
                      const SizedBox(height: 12),
                      InlineInfoBanner(message: controller.infoMessage.value!),
                    ],
                    if (controller.errorMessage.value != null) ...[
                      const SizedBox(height: 12),
                      InlineWarningBanner(
                        message: controller.errorMessage.value!,
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Padding(
                    key: ValueKey(controller.currentStep.value),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: steps[controller.currentStep.value].builder(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => SummaryFooter(
          showTotals: false,
          primaryLabel: _primaryLabel(controller.currentStep.value),
          tertiaryLabel:
              controller.currentStep.value == CartController.confirmStep
              ? (controller.hasSavedDraft ? 'Update Draft' : 'Save Draft')
              : null,
          onTertiaryPressed:
              controller.currentStep.value == CartController.confirmStep &&
                  controller.canSaveDraft
              ? () async {
                  await controller.saveDraft();
                }
              : null,
          secondaryLabel:
              controller.currentStep.value == CartController.customerStep
              ? null
              : 'Back',
          onSecondaryPressed:
              controller.currentStep.value == CartController.customerStep
              ? null
              : controller.previousStep,
          isLoading: controller.isSubmitting.value,
          onPrimaryPressed:
              controller.currentStep.value == CartController.confirmStep
              ? (controller.canConfirm
                    ? () async {
                        final shouldConfirm = await _showConfirmOrderDialog();
                        if (shouldConfirm == true) {
                          await controller.confirmOrder();
                        }
                      }
                    : null)
              : (controller.canContinueCurrentStep
                    ? controller.nextStep
                    : null),
        ),
      ),
    );
  }

  String _primaryLabel(int step) {
    if (step == CartController.confirmStep && !controller.canConfirm) {
      return 'Resolve Stock Warnings';
    }

    return controller.submitButtonLabel();
  }

  Future<bool?> _showConfirmOrderDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Order'),
        content: const Text(
          'Are you sure you want to confirm this order? You can still save it as a draft if you need more changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
