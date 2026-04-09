import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/person_models.dart';
import '../services/notes_repository.dart';
import '../widgets/common_widgets.dart';
import 'person_editor_screen.dart';

class PersonDetailScreen extends StatefulWidget {
  const PersonDetailScreen({
    super.key,
    required this.repository,
    required this.personId,
  });

  final NotesRepository repository;
  final int personId;

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  late Future<PersonDetails?> _detailsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _detailsFuture = widget.repository.fetchPersonDetails(widget.personId);
  }

  void _refresh() {
    setState(() {
      _detailsFuture = widget.repository.fetchPersonDetails(widget.personId);
    });
  }

  Future<void> _addNote() async {
    final controller = TextEditingController();
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New note',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 5,
                maxLines: 8,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Write what you noticed or want to remember',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) {
                      return;
                    }
                    await widget.repository.addNote(
                      personId: widget.personId,
                      content: text,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: const Text('Save note'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (didSave ?? false) {
      _refresh();
    }
  }

  Future<void> _editPerson(PersonRecord person) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            PersonEditorScreen(repository: widget.repository, person: person),
      ),
    );

    if (changed ?? false) {
      _refresh();
    }
  }

  Future<void> _addPhoto() async {
    final path = await widget.repository.importPhotoFromPicker();
    if (path == null) {
      return;
    }

    await widget.repository.addPhoto(widget.personId, path);
    _refresh();
  }

  Future<void> _changeProfilePhoto() async {
    final path = await widget.repository.importPhotoFromPicker();
    if (path == null) {
      return;
    }
    await widget.repository.setProfilePhoto(widget.personId, path);
    _refresh();
  }

  Future<void> _removeProfilePhoto() async {
    await widget.repository.clearProfilePhoto(widget.personId);
    _refresh();
  }

  Future<void> _togglePersonPinned(PersonRecord person) async {
    await widget.repository.togglePersonPinned(person.id, !person.isPinned);
    _refresh();
  }

  Future<void> _toggleNotePinned(NoteEntry note) async {
    await widget.repository.toggleNotePinned(note, !note.isPinned);
    _refresh();
  }

  Future<void> _deletePhoto(PhotoAttachment photo) async {
    await widget.repository.deletePhoto(photo);
    _refresh();
  }

  Future<void> _deleteNote(NoteEntry note) async {
    await widget.repository.deleteNote(note.id);
    _refresh();
  }

  Future<void> _deletePerson(PersonDetails details) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this person?'),
        content: Text(
          'This will remove ${details.person.name} and all saved notes and photos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await widget.repository.deletePerson(details.person.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<PersonDetails?>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final details = snapshot.data;
          if (details == null) {
            return const Center(child: Text('This person could not be found.'));
          }

          final person = details.person;
          final infoFields = _displayFields(person);
          final normalizedQuery = _searchQuery.trim().toLowerCase();
          final filteredFields = normalizedQuery.isEmpty
              ? infoFields
              : infoFields
                    .where(
                      (field) =>
                          field.label.toLowerCase().contains(normalizedQuery) ||
                          field.value.toLowerCase().contains(normalizedQuery),
                    )
                    .toList();
          final filteredNotes = normalizedQuery.isEmpty
              ? details.notes
              : details.notes
                    .where(
                      (note) =>
                          note.content.toLowerCase().contains(normalizedQuery),
                    )
                    .toList();

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        person.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _togglePersonPinned(person),
                      icon: Icon(
                        person.isPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editPerson(person),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => _deletePerson(details),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search this person\'s attributes and notes',
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PhotoAvatar(
                              path: details.primaryPhotoPath,
                              radius: 42,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (person.nicknames.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Text(
                                        'Nicknames: ${person.nicknames}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                    ),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      if (person.birthday != null)
                                        InfoChip(
                                          icon: Icons.event_outlined,
                                          label: DateFormat.yMMMMd().format(
                                            person.birthday!,
                                          ),
                                        ),
                                      if (person.age != null)
                                        InfoChip(
                                          icon: Icons.hourglass_bottom,
                                          label: '${person.age} years old',
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: _changeProfilePhoto,
                              icon: const Icon(
                                Icons.photo_camera_back_outlined,
                              ),
                              label: const Text('Change profile picture'),
                            ),
                            if (details.primaryPhotoPath != null)
                              TextButton(
                                onPressed: _removeProfilePhoto,
                                child: const Text('Remove profile picture'),
                              ),
                          ],
                        ),
                        if (filteredFields.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            'Info',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          ...filteredFields.map(
                            (field) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      field.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(field.value)),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (person.details.isNotEmpty &&
                            (normalizedQuery.isEmpty ||
                                person.details.toLowerCase().contains(
                                  normalizedQuery,
                                ))) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Details',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(person.details),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SectionHeader(
                  title: 'Pictures',
                  actionLabel: 'Add picture',
                  onPressed: _addPhoto,
                ),
                const SizedBox(height: 10),
                if (details.photos.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'No pictures yet. Add one to keep a visual reference locally on this device.',
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 122,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: details.photos.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final photo = details.photos[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                File(photo.path),
                                width: 122,
                                height: 122,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 122,
                                      height: 122,
                                      color: Colors.black12,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                    ),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _deletePhoto(photo),
                                  icon: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 22),
                SectionHeader(
                  title: 'Notes',
                  actionLabel: 'Add note',
                  onPressed: _addNote,
                ),
                const SizedBox(height: 10),
                if (filteredNotes.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'No matching notes yet. Try another phrase or add a new note.',
                      ),
                    ),
                  )
                else
                  ...filteredNotes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      DateFormat.yMMMMd().add_jm().format(
                                        note.createdAt,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _toggleNotePinned(note),
                                    icon: Icon(
                                      note.isPinned
                                          ? Icons.push_pin
                                          : Icons.push_pin_outlined,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteNote(note),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(note.content),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<CustomField> _displayFields(PersonRecord person) {
    final fields = [...person.customFields];
    if (person.school.trim().isNotEmpty &&
        fields.every((field) => field.label.toLowerCase() != 'school')) {
      fields.insert(0, CustomField(label: 'School', value: person.school));
    }
    if (person.course.trim().isNotEmpty &&
        fields.every((field) => field.label.toLowerCase() != 'course')) {
      fields.add(CustomField(label: 'Course', value: person.course));
    }
    return fields;
  }
}
