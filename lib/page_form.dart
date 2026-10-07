import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Page na nagtitipon ng biodata at nagsa-save nito sa Firestore.
class FormPage extends StatefulWidget {
  /// Gumagawa ng biodata page.
  const FormPage({super.key});

  /// Gumagawa ng state para sa mga input at form actions.
  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _schoolController = TextEditingController();
  final _courseController = TextEditingController();
  final _sectionController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedGender;
  DateTime? _selectedBirthdate;
  bool _isSaving = false;

  /// Sinusuri ang biodata at sine-save ito sa `students` collection sa Firestore.
  Future<void> saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _firestore.collection('students').add({
        'name': _nameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _selectedGender,
        'birthdate': Timestamp.fromDate(_selectedBirthdate!),
        'streetAddress': _streetAddressController.text.trim(),
        'city': _cityController.text.trim(),
        'zipCode': _zipCodeController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'school': _schoolController.text.trim(),
        'course': _courseController.text.trim(),
        'section': _sectionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biodata saved successfully')),
      );
      _formKey.currentState!.reset();
      for (final controller in [
        _nameController,
        _nicknameController,
        _ageController,
        _streetAddressController,
        _cityController,
        _zipCodeController,
        _emailController,
        _phoneController,
        _schoolController,
        _courseController,
        _sectionController,
      ]) {
        controller.clear();
      }
      setState(() {
        _selectedGender = null;
        _selectedBirthdate = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hindi na-save ang biodata: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Gumagawa ng heading para malinaw ang mga pangkat ng biodata fields.
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Gumagawa ng text field na may icon at validation para sa kinakailangang sagot.
  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? extraValidator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Pakilagay ang $label';
          }
          return extraValidator?.call(value);
        },
      ),
    );
  }

  /// Nagpapakita ng date picker at nagva-validate ng napiling birthday.
  Widget _birthdateField() {
    return FormField<DateTime>(
      validator: (value) => value == null ? 'Pumili ng birthdate' : null,
      builder: (field) {
        final date = field.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedBirthdate ?? DateTime(now.year - 18),
                firstDate: DateTime(1900),
                lastDate: now,
              );
              if (picked != null) {
                setState(() => _selectedBirthdate = picked);
                field.didChange(picked);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Birthdate',
                prefixIcon: const Icon(Icons.calendar_month),
                border: const OutlineInputBorder(),
                errorText: field.errorText,
              ),
              child: Text(
                date == null
                    ? 'Tap to select'
                    : '${date.month}/${date.day}/${date.year}',
              ),
            ),
          ),
        );
      },
    );
  }

  /// Isinasara ang lahat ng text controllers kapag inalis na ang page.
  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _ageController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _schoolController.dispose();
    _courseController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  /// Binubuo ang scrollable biodata form na nakaayos ayon sa screenshot.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biodata Form')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  margin: const EdgeInsets.only(top: 16, bottom: 4),
                  color: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.person,
                    size: 76,
                    color: Colors.white,
                  ),
                ),
                _sectionTitle('Basic Information'),
                _textField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                ),
                _textField(
                  controller: _nicknameController,
                  label: 'Nickname',
                  icon: Icons.badge,
                ),
                _textField(
                  controller: _ageController,
                  label: 'Age',
                  icon: Icons.cake,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  extraValidator: (value) {
                    final age = int.tryParse(value!.trim());
                    if (age == null || age < 1 || age > 150) {
                      return 'Maglagay ng valid na edad';
                    }
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_selectedGender),
                    initialValue: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.wc),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(
                        value: 'Prefer not to say',
                        child: Text('Prefer not to say'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedGender = value),
                    validator: (value) =>
                        value == null ? 'Pumili ng gender' : null,
                  ),
                ),
                _birthdateField(),
                _sectionTitle('Address'),
                _textField(
                  controller: _streetAddressController,
                  label: 'Street Address',
                  icon: Icons.home,
                ),
                _textField(
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_city,
                ),
                _textField(
                  controller: _zipCodeController,
                  label: 'Zip Code',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                _sectionTitle('Contact'),
                _textField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  extraValidator: (value) {
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value!.trim())) {
                      return 'Maglagay ng valid na email address';
                    }
                    return null;
                  },
                ),
                _textField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                _sectionTitle('School Details'),
                _textField(
                  controller: _schoolController,
                  label: 'School Name',
                  icon: Icons.school,
                ),
                _textField(
                  controller: _courseController,
                  label: 'Course',
                  icon: Icons.menu_book,
                ),
                _textField(
                  controller: _sectionController,
                  label: 'Section',
                  icon: Icons.groups,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : saveData,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Sine-save...' : 'Save Biodata'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
