import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../data/models/create_customer_request_model.dart';
import '../../data/repositories/customer_repository.dart';

class AddCustomerController extends GetxController {
  AddCustomerController({required CustomerRepository customerRepository})
    : _customerRepository = customerRepository;

  final CustomerRepository _customerRepository;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final areaController = TextEditingController();

  final isSubmitting = false.obs;
  final errorMessage = RxnString();
  final currentStep = 0.obs;

  String? validateRequired(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required.';
    }

    return null;
  }

  Future<void> submit() async {
    final currentState = formKey.currentState;
    if (currentState == null || !currentState.validate()) {
      return;
    }

    isSubmitting.value = true;
    errorMessage.value = null;

    try {
      final response = await _customerRepository.createCustomer(
        CreateCustomerRequestModel(
          name: nameController.text.trim(),
          phone: phoneController.text.trim(),
          address: addressController.text.trim(),
          area: areaController.text.trim().isEmpty
              ? null
              : areaController.text.trim(),
        ),
      );

      final customer = response.data;
      if (customer == null) {
        errorMessage.value = 'Customer response was incomplete.';
        return;
      }

      Get.back(result: customer);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to create customer right now.';
    } finally {
      isSubmitting.value = false;
    }
  }

  void nextStep() {
    if (currentStep.value == 0) {
      final nameError = validateRequired(nameController.text, 'Name');
      final phoneError = validateRequired(phoneController.text, 'Phone');
      if (nameError != null || phoneError != null) {
        errorMessage.value = nameError ?? phoneError;
        return;
      }
    }

    errorMessage.value = null;
    if (currentStep.value < 1) {
      currentStep.value += 1;
    }
  }

  void previousStep() {
    errorMessage.value = null;
    if (currentStep.value > 0) {
      currentStep.value -= 1;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    areaController.dispose();
    super.onClose();
  }
}
