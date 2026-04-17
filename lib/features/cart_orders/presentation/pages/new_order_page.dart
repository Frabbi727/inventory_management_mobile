import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/cart_controller.dart';
import '../controllers/new_order_page_controller.dart';
import '../widgets/order_flow_widgets.dart';

class NewOrderPage extends GetView<NewOrderPageController> {
  const NewOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = controller.cartController;

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
                      steps: controller.stepTitles,
                      currentStep: cartController.currentStep.value,
                      onStepTap: cartController.goToStep,
                    ),
                    if (cartController.infoMessage.value != null) ...[
                      const SizedBox(height: 12),
                      InlineInfoBanner(
                        message: cartController.infoMessage.value!,
                      ),
                    ],
                    if (cartController.errorMessage.value != null) ...[
                      const SizedBox(height: 12),
                      InlineWarningBanner(
                        message: cartController.errorMessage.value!,
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Padding(
                    key: ValueKey(cartController.currentStep.value),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: controller.steps[cartController.currentStep.value]
                        .builder(context),
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
          primaryLabel: controller.primaryLabel(
            cartController.currentStep.value,
          ),
          tertiaryLabel:
              cartController.currentStep.value == CartController.confirmStep
              ? (cartController.hasSavedDraft ? 'Update Draft' : 'Save Draft')
              : null,
          onTertiaryPressed:
              cartController.currentStep.value == CartController.confirmStep &&
                  cartController.canSaveDraft
              ? () async {
                  await cartController.saveDraft();
                }
              : null,
          secondaryLabel:
              cartController.currentStep.value == CartController.customerStep
              ? null
              : 'Back',
          onSecondaryPressed:
              cartController.currentStep.value == CartController.customerStep
              ? null
              : cartController.previousStep,
          isLoading: cartController.isSubmitting.value,
          onPrimaryPressed:
              cartController.currentStep.value == CartController.confirmStep
              ? (cartController.canConfirm
                    ? () async {
                        final shouldConfirm = await _showConfirmOrderDialog(
                          context,
                        );
                        if (shouldConfirm == true) {
                          await cartController.confirmOrder();
                        }
                      }
                    : null)
              : (cartController.canContinueCurrentStep
                    ? cartController.nextStep
                    : null),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmOrderDialog(BuildContext context) {
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
