import 'package:flutter/material.dart';

import 'models/person_models.dart';
import 'screens/person_detail_screen.dart';
import 'screens/person_editor_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_lock_service.dart';
import 'services/notes_repository.dart';
import 'widgets/common_widgets.dart';

class PerceptionNotesApp extends StatelessWidget {
  const PerceptionNotesApp({
    super.key,
    required this.repository,
    required this.lockService,
  });

  final NotesRepository repository;
  final AppLockService lockService;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2C6E63),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Perception Notes',
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF4EFE7),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.85),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.94),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      home: NotesAppShell(repository: repository, lockService: lockService),
    );
  }
}

class NotesAppShell extends StatefulWidget {
  const NotesAppShell({
    super.key,
    required this.repository,
    required this.lockService,
  });

  final NotesRepository repository;
  final AppLockService lockService;

  @override
  State<NotesAppShell> createState() => _NotesAppShellState();
}

class _NotesAppShellState extends State<NotesAppShell>
    with WidgetsBindingObserver {
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isLocked = widget.lockService.isLockEnabled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (widget.lockService.isLockEnabled) {
        setState(() {
          _isLocked = true;
        });
      }
    }
  }

  void _onUnlocked() {
    setState(() {
      _isLocked = false;
    });
  }

  void _lockNow() {
    setState(() {
      _isLocked = widget.lockService.isLockEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked && widget.lockService.isLockEnabled) {
      return UnlockScreen(
        lockService: widget.lockService,
        onUnlocked: _onUnlocked,
      );
    }

    return HomeScreen(
      repository: widget.repository,
      lockService: widget.lockService,
      onLockRequested: _lockNow,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.lockService,
    required this.onLockRequested,
  });

  final NotesRepository repository;
  final AppLockService lockService;
  final VoidCallback onLockRequested;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<PersonSummary>> _peopleFuture;
  Future<GlobalSearchResult>? _searchFuture;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _peopleFuture = widget.repository.fetchPeople();
  }

  void _refresh() {
    setState(() {
      _peopleFuture = widget.repository.fetchPeople();
      if (_search.trim().isNotEmpty) {
        _searchFuture = widget.repository.searchEverything(_search);
      }
    });
  }

  void _updateSearch(String value) {
    setState(() {
      _search = value;
      _searchFuture = value.trim().isEmpty
          ? null
          : widget.repository.searchEverything(value);
    });
  }

  Future<void> _openPersonEditor([PersonRecord? person]) async {
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

  Future<void> _openPersonDetail(int personId) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PersonDetailScreen(
          repository: widget.repository,
          personId: personId,
        ),
      ),
    );

    if (changed ?? false) {
      _refresh();
    }
  }

  Future<void> _openSettings() async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          lockService: widget.lockService,
          repository: widget.repository,
          onLockNow: widget.onLockRequested,
          onDataImported: _refresh,
        ),
      ),
    );

    if (shouldRefresh ?? false) {
      _refresh();
    }
  }

  Future<void> _togglePinned(PersonSummary person) async {
    await widget.repository.togglePersonPinned(person.id, !person.isPinned);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPersonEditor(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('New person'),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3E3CF), Color(0xFFF4EFE7), Color(0xFFD8E8E0)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<PersonSummary>>(
            future: _peopleFuture,
            builder: (context, snapshot) {
              final people = snapshot.data ?? const <PersonSummary>[];
              final isInitialLoading =
                  snapshot.connectionState == ConnectionState.waiting &&
                  snapshot.data == null;

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Perception Notes',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.8,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Private notes about the people in your life, stored on this device only.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: _openSettings,
                          icon: const Icon(Icons.settings_outlined),
                          tooltip: 'Settings',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      onChanged: _updateSearch,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText:
                            'Search people, attributes, and notes from here',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => _refresh(),
                        child: _buildHomeContent(
                          context,
                          people: people,
                          isInitialLoading: isInitialLoading,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(
    BuildContext context, {
    required List<PersonSummary> people,
    required bool isInitialLoading,
  }) {
    if (isInitialLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 64, 0, 120),
        children: const [
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_searchFuture != null) {
      return FutureBuilder<GlobalSearchResult>(
        future: _searchFuture,
        builder: (context, searchSnapshot) {
          final isSearchInitialLoading =
              searchSnapshot.connectionState == ConnectionState.waiting &&
              searchSnapshot.data == null;

          if (isSearchInitialLoading) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 64, 0, 120),
              children: const [
                Center(child: CircularProgressIndicator()),
              ],
            );
          }

          final results =
              searchSnapshot.data ??
              const GlobalSearchResult(people: [], notes: []);

          if (results.people.isEmpty && results.notes.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
              children: const [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No matches found.'),
                  ),
                ),
              ],
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
            children: [
              if (results.people.isNotEmpty) ...[
                Text(
                  'People',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ...results.people.map(
                  (person) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: PersonCard(
                      person: person,
                      onTap: () => _openPersonDetail(person.id),
                      onTogglePinned: () => _togglePinned(person),
                    ),
                  ),
                ),
              ],
              if (results.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ...results.notes.map(
                  (match) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        title: Text(match.person.name),
                        subtitle: Text(match.note.content),
                        trailing: match.note.isPinned
                            ? const Icon(Icons.push_pin)
                            : null,
                        onTap: () => _openPersonDetail(match.person.id),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      );
    }

    if (people.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: [
          EmptyStateCard(onCreatePressed: () => _openPersonEditor()),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
      children: people
          .map(
            (person) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PersonCard(
                person: person,
                onTap: () => _openPersonDetail(person.id),
                onTogglePinned: () => _togglePinned(person),
              ),
            ),
          )
          .toList(),
    );
  }
}

class PersonCard extends StatelessWidget {
  const PersonCard({
    super.key,
    required this.person,
    required this.onTap,
    required this.onTogglePinned,
  });

  final PersonSummary person;
  final VoidCallback onTap;
  final VoidCallback onTogglePinned;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              PhotoAvatar(path: person.primaryPhotoPath, radius: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            person.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: onTogglePinned,
                          icon: Icon(
                            person.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                          ),
                        ),
                      ],
                    ),
                    if (person.nicknames.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Nicknames: ${person.nicknames}'),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...summaryDisplayFields(person)
                            .take(3)
                            .map(
                              (field) => InfoChip(
                                icon: _iconForLabel(field.label),
                                label: '${field.label}: ${field.value}',
                              ),
                            ),
                        if (person.age != null)
                          InfoChip(
                            icon: Icons.cake_outlined,
                            label: '${person.age} yrs',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForLabel(String label) {
    switch (label.trim().toLowerCase()) {
      case 'school':
        return Icons.school;
      case 'course':
        return Icons.menu_book;
      case 'location':
        return Icons.location_on_outlined;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'facebook':
        return Icons.facebook;
      default:
        return Icons.label_outline;
    }
  }
}
