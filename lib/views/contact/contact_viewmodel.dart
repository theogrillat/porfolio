import 'package:flutter/material.dart';
import 'package:portfolio/services/analytics.dart';
import 'package:portfolio/services/email.dart';
import 'package:stacked/stacked.dart';

// ============================================================================
// CONTACT VIEWMODEL
// ============================================================================

class ContactViewModel extends BaseViewModel {
  // ============================================================================
  // SERVICES
  // ============================================================================

  final AnalyticsService _anal = AnalyticsService.instance;

  // ============================================================================
  // CONTROLLERS
  // ============================================================================

  final TextEditingController _emailController = TextEditingController();
  TextEditingController get emailController => _emailController;

  final TextEditingController _firstNameController = TextEditingController();
  TextEditingController get firstNameController => _firstNameController;

  final TextEditingController _lastNameController = TextEditingController();
  TextEditingController get lastNameController => _lastNameController;

  final TextEditingController _messageController = TextEditingController();
  TextEditingController get messageController => _messageController;

  // ============================================================================
  // GETTERS
  // ============================================================================

  String get email => _emailController.text;
  String get firstName => _firstNameController.text;
  String get lastName => _lastNameController.text;
  String get message => _messageController.text;

  // ============================================================================
  // VALIDATORS
  // ============================================================================

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'adresse email est requise';
    }

    // Regex pattern for email validation
    final emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Veuillez entrer une adresse email valide';
    }

    return null;
  }

  String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prénom est requis';
    }

    if (value.trim().length < 2) {
      return 'Le prénom doit contenir au moins 2 caractères';
    }

    if (value.trim().length > 50) {
      return 'Le prénom doit contenir moins de 50 caractères';
    }

    // Optional: Only allow letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s'-]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Le prénom ne peut contenir que des lettres';
    }

    return null;
  }

  String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom est requis';
    }

    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }

    if (value.trim().length > 50) {
      return 'Le nom doit contenir moins de 50 caractères';
    }

    // Optional: Only allow letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s'-]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Le nom ne peut contenir que des lettres';
    }

    return null;
  }

  String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le message est requis';
    }

    if (value.trim().length < 10) {
      return 'Le message doit contenir au moins 10 caractères';
    }

    if (value.trim().length > 10000) {
      return 'Le message doit contenir moins de 10 000 caractères';
    }

    return null;
  }

  // Optional: Validate all fields at once
  bool validateForm() {
    return validateEmail(email) == null && validateFirstName(firstName) == null && validateLastName(lastName) == null && validateMessage(message) == null;
  }

  // ============================================================================
  // EVENTS
  // ============================================================================

  bool _sending = false;
  bool get sending => _sending;

  void send(Function(String) callback) async {
    if (_sending) return;

    _sending = true;
    notifyListeners();

    print('------------------------------');
    print('email: $email');
    print('first name: $firstName');
    print('last name: $lastName');
    print('message: $message');
    print('------------------------------');

    String? emailError = validateEmail(email);
    String? firstNameError = validateFirstName(firstName);
    String? lastNameError = validateLastName(lastName);
    String? messageError = validateMessage(message);

    if (emailError != null || firstNameError != null || lastNameError != null || messageError != null) {
      callback(emailError ?? firstNameError ?? lastNameError ?? messageError!);
      return;
    }

    callback('Envoi en cours...');

    // Send email
    final result = await EmailService.sendContactEmailWithDetails(
      firstName: firstName,
      lastName: lastName,
      senderEmail: email,
      message: message,
    );

    if (!result.success) {
      callback('Une erreur est survenue lors de l\'envoi de votre message');
      print('Error: ${result.error}');
      _sending = false;
      notifyListeners();
      _anal.logContactFormSubmit(false, message: result.error);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 200));

    _anal.logContactFormSubmit(true);

    callback('Votre message a bien été envoyé');

    // Reset form
    _emailController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _messageController.clear();
    _sending = false;

    notifyListeners();
  }

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  void onInit() {}

  void onDispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _messageController.dispose();
  }
}

class TestEmail {
  static String email = 'john.doe@google.com';
  static String firstName = 'John';
  static String lastName = 'doe';
  static String message = '''
  Voluptate qui do do Lorem magna sunt adipisicing. Incididunt occaecat qui amet culpa pariatur sit est ea cillum incididunt est. Ea esse nostrud enim ad ipsum fugiat do eu eiusmod qui ut. Veniam officia amet veniam deserunt. Sit ut eiusmod pariatur elit laboris amet deserunt occaecat qui aliqua deserunt do duis. Eu culpa non enim deserunt eu in voluptate reprehenderit excepteur aute exercitation anim laboris.

  Lorem consectetur eiusmod tempor fugiat et laborum qui ullamco. Cupidatat eiusmod sit culpa. Lorem incididunt non qui. Dolore commodo esse amet occaecat incididunt deserunt quis dolore non enim tempor. Eiusmod commodo nostrud ex ullamco et occaecat consequat culpa ad.

  Laboris quis sint sit magna nisi ipsum laborum proident irure eu cupidatat adipisicing. Enim magna aliquip irure mollit occaecat tempor ullamco ullamco eiusmod eu consequat do eu magna adipisicing. Nisi pariatur ullamco irure veniam. Fugiat et est cillum incididunt sit do fugiat cillum ea consectetur. Non anim ex fugiat Lorem labore esse proident et. Eu consequat pariatur ut veniam deserunt aliquip exercitation. Nisi aliquip non sunt deserunt adipisicing adipisicing.
  ''';
}
