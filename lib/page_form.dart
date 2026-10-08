import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  static const _brandGreen = Color(0xFF2D6A4F);
  static const _brandGreenLight = Color(0xFFDCEBE3);

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

  void _addSubject() {
    setState(() => _subjects.add(_SubjectEntry()));
  }

  void _removeSubject(int index) {
    if (_subjects.length <= 1) return;
    setState(() => _subjects.removeAt(index).dispose());
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
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final radius = constraints.maxWidth * 0.05;
        final border = _inputBorder(radius, colors.outline, width: 1.5);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              prefixIcon: Icon(_fieldIcon(label), color: _brandGreen),
              labelText: label,
              filled: true,
              fillColor: colors.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: _inputBorder(radius, _brandGreen, width: 2),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Pls input $label'
                : null,
          ),
        );
      },
    );
  }

  IconData _fieldIcon(String label) {
    return switch (label) {
      'Name' => Icons.person_outline,
      'Section' => Icons.groups_2_outlined,
      'Course' => Icons.school_outlined,
      _ => Icons.menu_book_outlined,
    };
  }

  OutlineInputBorder _inputBorder(
    double radius,
    Color color, {
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _registrationStep() {
    return Form(
      key: _registrationFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepSectionHeading(
            icon: Icons.badge_outlined,
            title: 'Personal details',
            subtitle: 'Tell us a little about your enrollment.',
          ),
          const SizedBox(height: 16),
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
          _stepSectionHeading(
            icon: Icons.menu_book_outlined,
            title: 'Your subjects',
            subtitle: 'Add a subject and set its class schedule.',
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < _subjects.length; index++)
            _subjectCard(index),
          OutlinedButton.icon(
            onPressed: _addSubject,
            icon: const Icon(Icons.add),
            label: const Text('Add another subject'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectCard(int index) {
    final subject = _subjects[index];
    return TweenAnimationBuilder<double>(
      key: subject.key,
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) => Opacity(
        opacity: animation,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - animation)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final colors = Theme.of(context).colorScheme;
            final radius = constraints.maxWidth * 0.05;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: colors.outline, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _brandGreenLight,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: _brandGreen,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Subject ${index + 1}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (_subjects.length > 1)
                        IconButton(
                          onPressed: () => _removeSubject(index),
                          tooltip: 'Remove subject',
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _textField(
                    controller: subject.nameController,
                    label: 'Subject',
                  ),
                  _timeField(subject: subject, isStart: true),
                  _timeField(subject: subject, isStart: false),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _timeField({required _SubjectEntry subject, required bool isStart}) {
    final controller = isStart
        ? subject.startTimeController
        : subject.endTimeController;
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final radius = constraints.maxWidth * 0.05;
        final border = _inputBorder(radius, colors.outline, width: 1.5);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            readOnly: true,
            onTap: () => _selectTime(subject, isStart: isStart),
            decoration: InputDecoration(
              prefixIcon: Icon(
                isStart ? Icons.play_circle_outline : Icons.flag_outlined,
                color: _brandGreen,
              ),
              labelText: isStart ? 'Start Time' : 'End Time',
              hintText: isStart ? 'Select start time' : 'Select end time',
              suffixIcon: const Icon(Icons.schedule),
              filled: true,
              fillColor: colors.surface,
              border: border,
              enabledBorder: border,
              focusedBorder: _inputBorder(radius, _brandGreen, width: 2),
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
                  end.hour * 60 + end.minute <=
                      start.hour * 60 + start.minute) {
                return 'End time must be after start time';
              }
              return null;
            },
          ),
        );
      },
    );
  }

  Widget _verificationStep() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepSectionHeading(
          icon: Icons.fact_check_outlined,
          title: 'Review your details',
          subtitle: 'Make sure everything looks right before saving.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            children: [
              _detailRow(
                Icons.person_outline,
                'Name',
                _nameController.text.trim(),
              ),
              Divider(height: 1, color: colors.outlineVariant),
              _detailRow(
                Icons.groups_2_outlined,
                'Section',
                _sectionController.text.trim(),
              ),
              Divider(height: 1, color: colors.outlineVariant),
              _detailRow(
                Icons.school_outlined,
                'Course',
                _courseController.text.trim(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Class schedule',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < _subjects.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu_book_outlined, color: _brandGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _subjects[index].nameController.text.trim(),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_subjects[index].startTimeController.text.trim()}'
                          ' – ${_subjects[index].endTimeController.text.trim()}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _stepSectionHeading({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _brandGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _brandGreen),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
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
    final colors = Theme.of(context).colorScheme;
    final titles = ['User Registration', 'Subject Enrollment', 'Verification'];
    final descriptions = [
      'Enter your registration details.',
      'Add subjects and their class times.',
      'Review your details before saving.',
    ];
    final stepContent = switch (_step) {
      0 => _registrationStep(),
      1 => _subjectsStep(),
      _ => _verificationStep(),
    };

    const accent = _brandGreen;
    const completedAccent = _brandGreen;
    const stepLabels = ['Details', 'Subjects', 'Review'];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: _brandGreen),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomBandHeight = (constraints.maxHeight * 0.09).clamp(
              44.0,
              72.0,
            );
            return Column(
              children: [
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 32,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  36,
                                  30,
                                  36,
                                  24,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEFFFE),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF173A2B)
                                          .withValues(alpha: 0.12),
                                      blurRadius: 32,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Create Your Profile',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: const Color(0xFF3D383A),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 26),
                                    Row(
                                      children: [
                                        for (
                                          var index = 0;
                                          index < titles.length;
                                          index++
                                        ) ...[
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 250,
                                                ),
                                                width: 30,
                                                height: 30,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: index < _step
                                                      ? completedAccent
                                                      : index == _step
                                                      ? Colors.white
                                                      : const Color(0xFFF7F7F7),
                                                  border: Border.all(
                                                    color: index <= _step
                                                        ? accent
                                                        : const Color(
                                                            0xFFE1E1E1,
                                                          ),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Text(
                                                  '${index + 1}',
                                                  style: TextStyle(
                                                    color: index < _step
                                                        ? Colors.white
                                                        : index == _step
                                                        ? completedAccent
                                                        : const Color(
                                                            0xFFB8B2B4,
                                                          ),
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 7),
                                              Text(
                                                stepLabels[index],
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: index <= _step
                                                          ? completedAccent
                                                          : const Color(
                                                              0xFF9B9597,
                                                            ),
                                                      fontWeight: index == _step
                                                          ? FontWeight.w700
                                                          : FontWeight.normal,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          if (index < titles.length - 1)
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 21,
                                                ),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 250,
                                                  ),
                                                  height: 2,
                                                  color: index < _step
                                                      ? accent
                                                      : const Color(0xFFE3E3E3),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 26),
                                    Text(
                                      titles[_step].toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: const Color(0xFF464043),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      descriptions[_step],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF787174),
                                          ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFE8E3E5),
                                    ),
                                    const SizedBox(height: 22),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      reverseDuration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, animation) {
                                        final slideAnimation = Tween<Offset>(
                                          begin: const Offset(0.04, 0),
                                          end: Offset.zero,
                                        ).animate(animation);
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: slideAnimation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: KeyedSubtree(
                                        key: ValueKey(_step),
                                        child: stepContent,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (_step > 0)
                                          TextButton.icon(
                                            onPressed: _isSaving ? null : _back,
                                            icon: const Icon(
                                              Icons.chevron_left,
                                              size: 20,
                                            ),
                                            label: const Text('Previous'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: completedAccent,
                                            ),
                                          )
                                        else
                                          const SizedBox(width: 100),
                                        FilledButton(
                                          onPressed: _isSaving
                                              ? null
                                              : (_step == 2 ? _save : _next),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: accent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 22,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _step == 2
                                                    ? 'Save'
                                                    : _step == 1
                                                    ? 'Review'
                                                    : 'Next',
                                              ),
                                              const SizedBox(width: 5),
                                              const Icon(
                                                Icons.chevron_right,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            reverseDuration: const Duration(milliseconds: 180),
                            child: _isSaving
                                ? ColoredBox(
                                    key: const ValueKey('saving-overlay'),
                                    color: colors.scrim.withValues(alpha: 0.48),
                                    child: Center(
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.85, end: 1),
                                        duration: const Duration(
                                          milliseconds: 280,
                                        ),
                                        curve: Curves.easeOutBack,
                                        builder: (context, scale, child) =>
                                            Transform.scale(
                                              scale: scale,
                                              child: child,
                                            ),
                                        child: Card(
                                          elevation: 12,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 26,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 42,
                                                  height: 42,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 3,
                                                        color: accent,
                                                      ),
                                                ),
                                                const SizedBox(height: 18),
                                                Text(
                                                  'Saving registration...',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Please wait a moment',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: colors
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('no-saving-overlay'),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: bottomBandHeight,
                  width: double.infinity,
                  child: const ColoredBox(color: _brandGreen),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SubjectEntry {
  final key = UniqueKey();
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
