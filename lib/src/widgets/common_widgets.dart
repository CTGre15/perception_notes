import 'dart:io';

import 'package:flutter/material.dart';

import '../models/person_models.dart';

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({super.key, required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.people_alt_outlined, size: 48),
            const SizedBox(height: 14),
            Text(
              'No people yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a person profile first, then keep dated notes and pictures under their profile.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreatePressed,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add your first person'),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class PhotoAvatar extends StatelessWidget {
  const PhotoAvatar({super.key, required this.path, required this.radius});

  final String? path;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final file = path == null ? null : File(path!);
    final canShowFile = file != null && file.existsSync();

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      backgroundImage: canShowFile ? FileImage(file) : null,
      child: canShowFile
          ? null
          : Icon(
              Icons.person,
              size: radius,
              color: Theme.of(context).colorScheme.primary,
            ),
    );
  }
}

List<CustomField> summaryDisplayFields(PersonSummary person) {
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
