import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/add_customer_controller.dart';

class AddCustomerPage extends GetView<AddCustomerController> {
  const AddCustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Customer')),
      body: SafeArea(
        child: Obx(
          () => Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PageHero(currentStep: controller.currentStep.value),
                      const SizedBox(height: 18),
                      Form(
                        key: controller.formKey,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: controller.currentStep.value == 0
                                  ? _BasicInfoStep(
                                      key: const ValueKey('basic-info'),
                                      controller: controller,
                                    )
                                  : _AddressInfoStep(
                                      key: const ValueKey('address-info'),
                                      controller: controller,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.errorMessage.value != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _ErrorBanner(message: controller.errorMessage.value!),
                ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.94),
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (controller.currentStep.value > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: controller.previousStep,
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Back'),
                          ),
                        ),
                      if (controller.currentStep.value > 0)
                        const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: controller.isSubmitting.value
                              ? null
                              : controller.currentStep.value == 0
                              ? controller.nextStep
                              : controller.submit,
                          icon: controller.isSubmitting.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  controller.currentStep.value == 0
                                      ? Icons.arrow_forward_rounded
                                      : Icons.check_circle_outline_rounded,
                                ),
                          label: Text(
                            controller.currentStep.value == 0
                                ? 'Continue'
                                : 'Create Customer',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHero extends StatelessWidget {
  const _PageHero({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New customer',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        _AddCustomerStepper(currentStep: currentStep),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  currentStep == 0
                      ? Icons.badge_outlined
                      : Icons.location_on_outlined,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStep == 0 ? 'Basic Info' : 'Address',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentStep == 0
                          ? 'Add the customer name and phone number.'
                          : 'Save address details for delivery and follow-up.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.84,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddCustomerStepper extends StatelessWidget {
  const _AddCustomerStepper({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const steps = ['Basic Info', 'Address'];

    return Row(
      children: List.generate(steps.length, (index) {
        final isCurrent = currentStep == index;
        final isCompleted = currentStep > index;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == steps.length - 1 ? 0 : 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCurrent
                  ? colorScheme.surface
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCurrent || isCompleted
                    ? colorScheme.primary.withValues(alpha: 0.45)
                    : colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: colorScheme.onPrimary,
                        )
                      : Text(
                          '${index + 1}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isCurrent
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[index],
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                      color: isCurrent || isCompleted
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _BasicInfoStep extends StatelessWidget {
  const _BasicInfoStep({super.key, required this.controller});

  final AddCustomerController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Basic Info',
          subtitle: 'Customer identity and primary contact details.',
        ),
        const SizedBox(height: 18),
        _PremiumField(
          controller: controller.nameController,
          label: 'Customer Name',
          hint: 'Enter customer name',
          textInputAction: TextInputAction.next,
          validator: (value) => controller.validateRequired(value, 'Name'),
        ),
        const SizedBox(height: 16),
        _PremiumField(
          controller: controller.phoneController,
          label: 'Phone Number',
          hint: 'Enter phone number',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          validator: (value) => controller.validateRequired(value, 'Phone'),
        ),
      ],
    );
  }
}

class _AddressInfoStep extends StatelessWidget {
  const _AddressInfoStep({super.key, required this.controller});

  final AddCustomerController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Address',
          subtitle: 'Delivery address and local area information.',
        ),
        const SizedBox(height: 18),
        _PremiumField(
          controller: controller.addressController,
          label: 'Address',
          hint: 'Enter full address',
          maxLines: 3,
          textInputAction: TextInputAction.next,
          validator: (value) => controller.validateRequired(value, 'Address'),
        ),
        const SizedBox(height: 16),
        _PremiumField(
          controller: controller.areaController,
          label: 'Area',
          hint: 'Optional',
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PremiumField extends StatelessWidget {
  const _PremiumField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textInputAction: textInputAction,
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest.withValues(alpha: 0.8),
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 18 : 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFB42318)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7A271A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
