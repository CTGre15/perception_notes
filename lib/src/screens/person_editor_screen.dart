import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/person_models.dart';
import '../services/notes_repository.dart';
import '../widgets/common_widgets.dart';

class PersonEditorScreen extends StatefulWidget {
  const PersonEditorScreen({super.key, required this.repository, this.person});

  final NotesRepository repository;
  final PersonRecord? person;

  @override
  State<PersonEditorScreen> createState() => _PersonEditorScreenState();
}

class _PersonEditorScreenState extends State<PersonEditorScreen> {
  static const _quickFieldLabels = [
    'School',
    'Course',
    'Location',
    'Instagram',
    'Facebook',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _ageController;
  late final TextEditingController _detailsController;
  final List<_EditableCustomField> _customFields = [];
  DateTime? _birthday;
  bool _saving = false;
  String? _profilePhotoPath;
  String? _newProfilePhotoSourcePath;
  bool _removeExistingProfilePhoto = false;
  late int _avatarStyle;
  late AvatarGender _avatarGender;

  bool get _isEditing => widget.person != null;

  @override
  void initState() {
    super.initState();
    final person = widget.person;
    _nameController = TextEditingController(text: person?.name ?? '');
    _nicknameController = TextEditingController(text: person?.nicknames ?? '');
    _ageController = TextEditingController(
      text: person?.age == null ? '' : person!.age.toString(),
    );
    _detailsController = TextEditingController(text: person?.details ?? '');
    _birthday = person?.birthday;
    _profilePhotoPath = person?.profilePhotoPath;
    _avatarStyle = person?.avatarStyle ?? Random().nextInt(5000);
    _avatarGender =
        person?.avatarGender ??
        (Random().nextBool() ? AvatarGender.female : AvatarGender.male);

    final fields = _buildInitialFields(person);
    if (fields.isEmpty) {
      _customFields.add(_EditableCustomField());
    } else {
      _customFields.addAll(fields.map(_EditableCustomField.fromCustomField));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _ageController.dispose();
    _detailsController.dispose();
    for (final field in _customFields) {
      field.dispose();
    }
    super.dispose();
  }

  List<CustomField> _buildInitialFields(PersonRecord? person) {
    if (person == null) {
      return const [];
    }

    final fields = <CustomField>[];
    if (person.school.trim().isNotEmpty &&
        !person.customFields.any(
          (field) => _sameLabel(field.label, 'School'),
        )) {
      fields.add(CustomField(label: 'School', value: person.school));
    }
    if (person.course.trim().isNotEmpty &&
        !person.customFields.any(
          (field) => _sameLabel(field.label, 'Course'),
        )) {
      fields.add(CustomField(label: 'Course', value: person.course));
    }
    fields.addAll(person.customFields);
    return fields;
  }

  bool _sameLabel(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
      });
    }
  }

  Future<void> _pickProfilePhoto() async {
    final path = await widget.repository.importPhotoFromPicker();
    if (path == null) {
      return;
    }

    setState(() {
      _newProfilePhotoSourcePath = path;
      _profilePhotoPath = path;
      _removeExistingProfilePhoto = false;
    });
  }

  void _addCustomField([String? label]) {
    setState(() {
      _customFields.add(_EditableCustomField(label: label ?? ''));
    });
  }

  Future<void> _pickGeneratedPlaceholder() async {
    final chosen = await showAvatarStylePicker(
      context,
      name: _nameController.text.trim(),
      currentStyle: _avatarStyle,
      currentGender: _avatarGender,
    );
    if (chosen == null) {
      return;
    }
    setState(() {
      _avatarStyle = chosen.style;
      _avatarGender = chosen.gender;
      _newProfilePhotoSourcePath = null;
      _profilePhotoPath = null;
      _removeExistingProfilePhoto = false;
    });
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required.')));
      return;
    }

    final customFields = _customFields
        .map((field) => field.toCustomField())
        .whereType<CustomField>()
        .toList();

    String getFieldValue(String label) {
      final match = customFields.where(
        (field) => _sameLabel(field.label, label),
      );
      if (match.isEmpty) {
        return '';
      }
      return match.first.value;
    }

    setState(() {
      _saving = true;
    });

    final person = PersonRecord(
      id: widget.person?.id ?? 0,
      name: name,
      nicknames: _nicknameController.text.trim(),
      school: getFieldValue('School'),
      course: getFieldValue('Course'),
      birthday: _birthday,
      age: int.tryParse(_ageController.text.trim()),
      details: _detailsController.text.trim(),
      profilePhotoPath: widget.person?.profilePhotoPath,
      avatarStyle: _avatarStyle,
      avatarGender: _avatarGender,
      customFields: customFields,
      isPinned: widget.person?.isPinned ?? false,
      createdAt: widget.person?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final personId = _isEditing
        ? person.id
        : await widget.repository.insertPerson(person);
    if (_isEditing) {
      await widget.repository.updatePerson(person);
    }

    if (_removeExistingProfilePhoto && _newProfilePhotoSourcePath == null) {
      await widget.repository.clearProfilePhoto(personId);
    }

    if (_newProfilePhotoSourcePath != null) {
      await widget.repository.setProfilePhoto(
        personId,
        _newProfilePhotoSourcePath!,
      );
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit person' : 'New person')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _pickGeneratedPlaceholder,
                  child: PhotoAvatar(
                    path: _profilePhotoPath,
                    radius: 42,
                    name: _nameController.text,
                    avatarStyle: _avatarStyle,
                    avatarGender: _avatarGender,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: _pickProfilePhoto,
                  icon: const Icon(Icons.photo_camera_back_outlined),
                  label: const Text('Choose profile picture'),
                ),
                const SizedBox(height: 8),
                Text(
                  _profilePhotoPath == null
                      ? 'Tap the avatar to choose a generated icon'
                      : 'Tap the avatar to switch back to a generated icon',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_isEditing && widget.person?.profilePhotoPath != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _newProfilePhotoSourcePath = null;
                        _profilePhotoPath = null;
                        _removeExistingProfilePhoto = true;
                      });
                    },
                    child: const Text('Clear profile picture preview'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Full name',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nicknameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nicknames',
              hintText: 'Comma-separated nicknames',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _pickBirthday,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _birthday == null
                        ? 'Birthday'
                        : DateFormat.yMd().format(_birthday!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Extra fields',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _addCustomField(),
                icon: const Icon(Icons.add),
                label: const Text('Add field'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickFieldLabels
                .map(
                  (label) => ActionChip(
                    label: Text(label),
                    onPressed: () => _addCustomField(label),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          ..._customFields.asMap().entries.map((entry) {
            final index = entry.key;
            final field = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: field.labelController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Field'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: field.valueController,
                      decoration: const InputDecoration(labelText: 'Value'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        field.dispose();
                        _customFields.removeAt(index);
                        if (_customFields.isEmpty) {
                          _customFields.add(_EditableCustomField());
                        }
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 14),
          TextField(
            controller: _detailsController,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'More details',
              hintText: 'Anything else you want to remember about this person',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isEditing ? 'Save changes' : 'Create person'),
          ),
        ],
      ),
    );
  }
}

class _EditableCustomField {
  _EditableCustomField({String label = '', String value = ''})
    : labelController = TextEditingController(text: label),
      valueController = TextEditingController(text: value);

  factory _EditableCustomField.fromCustomField(CustomField field) {
    return _EditableCustomField(label: field.label, value: field.value);
  }

  final TextEditingController labelController;
  final TextEditingController valueController;

  CustomField? toCustomField() {
    final label = labelController.text.trim();
    final value = valueController.text.trim();
    if (label.isEmpty || value.isEmpty) {
      return null;
    }
    return CustomField(label: label, value: value);
  }

  void dispose() {
    labelController.dispose();
    valueController.dispose();
  }
}
