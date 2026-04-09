import 'package:flutter/material.dart';

Future<String?> promptForPin(
  BuildContext context, {
  required String title,
  required String actionLabel,
}) {
  final controller = TextEditingController();
  String? errorText;

  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Use at least 4 digits',
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.length < 4) {
                  setState(() {
                    errorText = 'Enter at least 4 digits.';
                  });
                  return;
                }
                Navigator.of(context).pop(value);
              },
              child: Text(actionLabel),
            ),
          ],
        ),
      );
    },
  );
}
