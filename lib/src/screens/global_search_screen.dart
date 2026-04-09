import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/person_models.dart';
import '../services/notes_repository.dart';
import '../widgets/common_widgets.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({
    super.key,
    required this.repository,
    required this.onOpenPerson,
  });

  final NotesRepository repository;
  final Future<void> Function(int personId) onOpenPerson;

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _controller = TextEditingController();
  Future<GlobalSearchResult>? _resultsFuture;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    final query = value.trim();
    setState(() {
      _resultsFuture = query.isEmpty
          ? null
          : widget.repository.searchEverything(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Global search')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _controller,
            onChanged: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search people, attributes, and notes',
            ),
          ),
          const SizedBox(height: 18),
          if (_resultsFuture == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Start typing to search across people details and all notes.',
                ),
              ),
            )
          else
            FutureBuilder<GlobalSearchResult>(
              future: _resultsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final results =
                    snapshot.data ??
                    const GlobalSearchResult(people: [], notes: []);
                if (results.people.isEmpty && results.notes.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('No matches found.'),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (results.people.isNotEmpty) ...[
                      Text(
                        'People',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...results.people.map(
                        (person) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              leading: PhotoAvatar(
                                path: person.primaryPhotoPath,
                                radius: 22,
                                name: person.name,
                                avatarStyle: person.avatarStyle,
                                avatarGender: person.avatarGender,
                              ),
                              title: Text(person.name),
                              subtitle: Text(
                                summaryDisplayFields(person)
                                    .take(2)
                                    .map(
                                      (field) =>
                                          '${field.label}: ${field.value}',
                                    )
                                    .join(' • '),
                              ),
                              trailing: person.isPinned
                                  ? const Icon(Icons.push_pin, size: 18)
                                  : null,
                              onTap: () async {
                                await widget.onOpenPerson(person.id);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (results.notes.isNotEmpty) ...[
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...results.notes.map(
                        (match) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              title: Text(match.person.name),
                              subtitle: Text(match.note.content),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (match.note.isPinned)
                                    const Icon(Icons.push_pin, size: 18),
                                  Text(
                                    DateFormat.MMMd().format(
                                      match.note.createdAt,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                await widget.onOpenPerson(match.person.id);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
