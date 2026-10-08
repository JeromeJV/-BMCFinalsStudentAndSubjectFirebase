import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _registrationFormKey = GlobalKey<FormState>();
  final _subjectsFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _courseController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<_SubjectEntry> _subjects = [_SubjectEntry(), _SubjectEntry()];

  int _step = 0;
  bool _isSaving = false;

  void _next() {
    final isValid = switch (_step) {
      0 => _registrationFormKey.currentState!.validate(),
      1 => _subjectsFormKey.currentState!.validate(),
      _ => true,
    };
    if (isValid) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _selectTime(
    _SubjectEntry subject, {
    required bool isStart,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? subject.startTime : subject.endTime) ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        subject.startTime = picked;
        subject.startTimeController.text = picked.format(context);
      } else {
        subject.endTime = picked;
        subject.endTimeController.text = picked.format(context);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _firestore.collection('ACTIVITY3').add({
        'name': _nameController.text.trim(),
        'section': _sectionController.text.trim(),
        'course': _courseController.text.trim(),
        'subjects': _subjects
            .map(
              (subject) => {
                'name': subject.nameController.text.trim(),
                'startTime': subject.startTimeController.text.trim(),
                'endTime': subject.endTimeController.text.trim(),
              },
            )
            .toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration saved successfully')),
      );
      _nameController.clear();
      _sectionController.clear();
      _courseController.clear();
      for (final subject in _subjects) {
        subject.dispose();
      }
      setState(() {
        _subjects
          ..clear()
          ..addAll([_SubjectEntry(), _SubjectEntry()]);
        _step = 0;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Not Registered: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Pls input $label' : null,
      ),
    );
  }

  Widget _registrationStep() {
    return Form(
      key: _registrationFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _textField(controller: _nameController, label: 'Name'),
          _textField(controller: _sectionController, label: 'Section'),
          _textField(controller: _courseController, label: 'Course'),
        ],
      ),
    );
  }

  Widget _subjectsStep() {
    return Form(
      key: _subjectsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _subjects.length; index++)
            _subjectCard(index),
        ],
      ),
    );
  }

  Widget _subjectCard(int index) {
    final subject = _subjects[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Subject ${index + 1}'),
          _textField(controller: subject.nameController, label: 'Subject'),
          _timeField(subject: subject, isStart: true),
          _timeField(subject: subject, isStart: false),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _timeField({required _SubjectEntry subject, required bool isStart}) {
    final controller = isStart
        ? subject.startTimeController
        : subject.endTimeController;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectTime(subject, isStart: isStart),
        decoration: InputDecoration(
          labelText: isStart ? 'Start Time' : 'End Time',
          hintText: isStart ? 'Select start time' : 'Select end time',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please select a ${isStart ? 'start' : 'end'} time';
          }
          final start = subject.startTime;
          final end = subject.endTime;
          if (!isStart &&
              start != null &&
              end != null &&
              end.hour * 60 + end.minute <= start.hour * 60 + start.minute) {
            return 'End time must be after start time';
          }
          return null;
        },
      ),
    );
  }

  Widget _verificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _detailRow('Name', _nameController.text.trim()),
        _detailRow('Section', _sectionController.text.trim()),
        _detailRow('Course', _courseController.text.trim()),
        const SizedBox(height: 8),
        const Text('Subjects'),
        const SizedBox(height: 4),
        for (var index = 0; index < _subjects.length; index++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              '${index + 1}. ${_subjects[index].nameController.text.trim()}'
              ' — ${_subjects[index].startTimeController.text.trim()}'
              ' to ${_subjects[index].endTimeController.text.trim()}',
            ),
          ),
        const SizedBox(height: 8),
        Text('Please verify your details before saving.'),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text('$label: $value'),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sectionController.dispose();
    _courseController.dispose();
    for (final subject in _subjects) {
      subject.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['User Registration', 'Subject Enrollment', 'Verification'];
    final stepContent = switch (_step) {
      0 => _registrationStep(),
      1 => _subjectsStep(),
      _ => _verificationStep(),
    };

    return Scaffold(
      appBar: AppBar(
        leading: _step == 0
            ? null
            : IconButton(
                tooltip: 'Back',
                onPressed: _back,
                icon: const Icon(Icons.arrow_back),
              ),
        title: Text(titles[_step]),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Step ${_step + 1} of ${titles.length}'),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [const SizedBox(height: 16), stepContent],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isSaving ? null : (_step == 2 ? _save : _next),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_step == 2 ? 'Save' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectEntry {
  final nameController = TextEditingController();
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  void dispose() {
    nameController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
  }
}
