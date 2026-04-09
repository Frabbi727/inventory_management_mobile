import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/add_customer_controller.dart';

class AddCustomerPage extends GetView<AddCustomerController> {
  const AddCustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Customer')),
      body: SafeArea(
        child: Obx(
          () => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _AddCustomerHeader(
                  currentStep: controller.currentStep.value,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: controller.formKey,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
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
                ),
              ),
              if (controller.errorMessage.value != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    controller.errorMessage.value!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      if (controller.currentStep.value > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controller.previousStep,
                            child: const Text('Back'),
                          ),
                        ),
                      if (controller.currentStep.value > 0)
                        const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: controller.isSubmitting.value
                              ? null
                              : controller.currentStep.value == 0
                              ? controller.nextStep
                              : controller.submit,
                          child: controller.isSubmitting.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
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

class _AddCustomerHeader extends StatelessWidget {
  const _AddCustomerHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final steps = ['Basic Info', 'Address'];

    return Row(
      children: List.generate(steps.length, (index) {
        final selected = currentStep == index;
        final completed = currentStep > index;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == steps.length - 1 ? 0 : 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: completed || selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  child: Icon(
                    completed ? Icons.check : Icons.circle,
                    size: 14,
                    color: completed || selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text('${index + 1}. ${steps[index]}')),
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
        Text(
          'Basic Information',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.nameController,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: (value) => controller.validateRequired(value, 'Name'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone'),
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
        Text(
          'Address',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.addressController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Address'),
          validator: (value) => controller.validateRequired(value, 'Address'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.areaController,
          decoration: const InputDecoration(labelText: 'Area (optional)'),
        ),
      ],
    );
  }
}
