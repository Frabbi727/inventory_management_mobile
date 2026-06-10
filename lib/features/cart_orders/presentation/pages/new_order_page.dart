import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/controllers/home_controller.dart';
import '../../../invoice/presentation/models/order_list_status_filter.dart';
import '../../data/models/create_order_response_model.dart';
import '../controllers/cart_controller.dart';
import '../controllers/new_order_page_controller.dart';
import '../widgets/order_flow_widgets.dart';

class NewOrderPage extends GetView<NewOrderPageController> {
  const NewOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartController = controller.cartController;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Obx(
          () => Column(
            children: [
              Text(
                cartController.hasSavedDraft ? 'Continue Draft' : 'Create Order',
              ),
              Text(
                'Step ${cartController.currentStep.value + 1} of '
                '${controller.steps.length} · '
                '${controller.stepTitles[cartController.currentStep.value]}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Obx(() {
            final draftNo = cartController.savedDraftOrder.value?.orderNo;
            if (draftNo == null) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFADC8E)),
                ),
                child: Text(
                  draftNo,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFD97706),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
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
      bottomNavigationBar: Obx(() {
        final step = cartController.currentStep.value;
        final isPaymentStep = step == CartController.paymentStep;
        final showRecap =
            step == CartController.productsStep && cartController.hasItems;

        return SummaryFooter(
          showTotals: false,
          recapText: showRecap
              ? '${cartController.items.length} item'
                    '${cartController.items.length == 1 ? '' : 's'} · '
                    '${cartController.totalUnits} units'
              : null,
          recapValue: showRecap
              ? cartController.formatCurrency(cartController.subtotal)
              : null,
          primaryLabel: controller.primaryLabel(step),
          tertiaryLabel: isPaymentStep
              ? (cartController.hasSavedDraft ? 'Update Draft' : 'Save Draft')
              : null,
          tertiaryHighlighted: isPaymentStep,
          onTertiaryPressed: isPaymentStep && cartController.canSaveDraft
              ? () async {
                  final shouldSave = await _showDraftConfirmDialog(context);
                  if (shouldSave == true) {
                    final response = await cartController.saveDraft();
                    await _handleOrderCompletion(response, status: 'draft');
                  }
                }
              : null,
          secondaryLabel: step == CartController.customerStep ? null : 'Back',
          onSecondaryPressed: step == CartController.customerStep
              ? null
              : cartController.previousStep,
          isLoading: cartController.isSubmitting.value,
          onPrimaryPressed: isPaymentStep
              ? (cartController.canConfirm
                    ? () async {
                        final shouldConfirm = await _showConfirmOrderDialog(
                          context,
                        );
                        if (shouldConfirm == true) {
                          final response = await cartController.confirmOrder();
                          await _handleOrderCompletion(
                            response,
                            status: 'confirmed',
                          );
                        }
                      }
                    : null)
              : (cartController.canContinueCurrentStep
                    ? cartController.nextStep
                    : null),
        );
      }),
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

  Future<bool?> _showDraftConfirmDialog(BuildContext context) {
    final cartController = controller.cartController;
    final title = cartController.hasSavedDraft ? 'Update Draft' : 'Save Draft';
    final message = cartController.hasSavedDraft
        ? 'Do you want to update this draft order? After saving, you will be taken to the draft list.'
        : 'Do you want to save this order as a draft? After saving, you will be taken to the draft list.';

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Yes, Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOrderCompletion(
    CreateOrderResponseModel? response, {
    required String status,
  }) async {
    if (response?.data == null) {
      return;
    }

    Get.until((route) => route.settings.name == AppRoutes.home);
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().openOrdersTab(
        statusFilter: status == 'confirmed'
            ? OrderListStatusFilter.confirmed
            : OrderListStatusFilter.draft,
      );
    }
  }
}
