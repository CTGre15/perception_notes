import 'package:flutter/material.dart';

import '../models/person_models.dart';
import '../services/app_lock_service.dart';
import '../services/notes_repository.dart';
import '../widgets/pin_prompt.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.lockService,
    required this.repository,
    required this.onLockNow,
    required this.onDataImported,
  });

  final AppLockService lockService;
  final NotesRepository repository;
  final VoidCallback onLockNow;
  final VoidCallback onDataImported;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _working = false;
  late Future<StorageSummary> _storageFuture;

  @override
  void initState() {
    super.initState();
    _storageFuture = widget.repository.getStorageSummary();
  }

  void _refreshStorage() {
    setState(() {
      _storageFuture = widget.repository.getStorageSummary();
    });
  }

  Future<void> _setPin() async {
    final pin = await promptForPin(
      context,
      title: widget.lockService.isLockEnabled ? 'Change PIN' : 'Set a PIN',
      actionLabel: 'Save PIN',
    );
    if (pin == null) {
      return;
    }

    setState(() {
      _working = true;
    });
    await widget.lockService.setPin(pin);
    if (!mounted) {
      return;
    }
    setState(() {
      _working = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('App lock updated.')));
  }

  Future<void> _removePin() async {
    setState(() {
      _working = true;
    });
    await widget.lockService.clearPin();
    if (!mounted) {
      return;
    }
    setState(() {
      _working = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('App lock removed.')));
    Navigator.of(context).pop(true);
  }

  Future<void> _exportBackup() async {
    setState(() {
      _working = true;
    });
    String? path;
    Object? error;
    try {
      path = await widget.repository.exportBackup();
    } catch (exception) {
      error = exception;
      debugPrint('[backup] export threw: $exception');
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
    if (!mounted) {
      return;
    }
    _refreshStorage();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error != null
              ? 'Backup export failed.'
              : path == null
              ? 'Backup export cancelled.'
              : 'Backup exported to $path',
        ),
      ),
    );
  }

  Future<void> _importBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import backup?'),
        content: const Text(
          'This replaces the current local data with the selected backup file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    setState(() {
      _working = true;
    });
    final success = await widget.repository.importBackup();
    if (!mounted) {
      return;
    }
    setState(() {
      _working = false;
    });
    _refreshStorage();
    if (success) {
      widget.onDataImported();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Backup imported.' : 'Backup import cancelled or failed.',
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }
    return '${value.toStringAsFixed(index == 0 ? 0 : 1)} ${units[index]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: FutureBuilder<StorageSummary>(
                future: _storageFuture,
                builder: (context, snapshot) {
                  final storage =
                      snapshot.data ??
                      const StorageSummary(
                        totalBytes: 0,
                        databaseBytes: 0,
                        imageBytes: 0,
                        backupBytes: 0,
                      );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storage',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total local usage: ${_formatBytes(storage.totalBytes)}',
                      ),
                      const SizedBox(height: 12),
                      Text('Database: ${_formatBytes(storage.databaseBytes)}'),
                      Text('Images: ${_formatBytes(storage.imageBytes)}'),
                      Text(
                        'Internal backups/assets: ${_formatBytes(storage.backupBytes)}',
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.lockService.isLockEnabled
                        ? 'A PIN is currently protecting the app.'
                        : 'Set a PIN so the app asks for it whenever it is reopened or sent to the background.',
                  ),
                  const SizedBox(height: 18),
                  FilledButton.tonal(
                    onPressed: _working ? null : _setPin,
                    child: Text(
                      widget.lockService.isLockEnabled
                          ? 'Change PIN'
                          : 'Set PIN',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.lockService.isLockEnabled)
                    OutlinedButton(
                      onPressed: _working
                          ? null
                          : () {
                              widget.onLockNow();
                              Navigator.of(context).pop(true);
                            },
                      child: const Text('Lock now'),
                    ),
                  if (widget.lockService.isLockEnabled)
                    const SizedBox(height: 12),
                  if (widget.lockService.isLockEnabled)
                    TextButton(
                      onPressed: _working ? null : _removePin,
                      child: const Text('Remove PIN'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Export your local database plus saved images into one portable JSON backup, or restore from one later.',
                  ),
                  const SizedBox(height: 18),
                  FilledButton.tonalIcon(
                    onPressed: _working ? null : _exportBackup,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export backup'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _working ? null : _importBackup,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Import backup'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Perception Notes was built for private, local-first memory keeping.',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Developer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'entropious is a Filipino full stack developer focused on building thoughtful, practical software across frontend, backend, and product experiences.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({
    super.key,
    required this.lockService,
    required this.onUnlocked,
  });

  final AppLockService lockService;
  final VoidCallback onUnlocked;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final valid = await widget.lockService.verifyPin(_controller.text.trim());
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _error = valid ? null : 'Incorrect PIN.';
    });
    if (valid) {
      _controller.clear();
      widget.onUnlocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1D3C37), Color(0xFF38645A), Color(0xFFF4EFE7)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 34,
                        child: Icon(Icons.lock, size: 32),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Unlock Perception Notes',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your notes stay local to this device. Enter your PIN to continue.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        onSubmitted: (_) => _unlock(),
                        decoration: InputDecoration(
                          labelText: 'PIN',
                          errorText: _error,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _unlock,
                          child: const Text('Unlock'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
