import 'dart:io';
import 'dart:math' as math;

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
  const PhotoAvatar({
    super.key,
    required this.path,
    required this.radius,
    this.name = '',
    this.avatarStyle = 0,
    this.avatarGender = AvatarGender.female,
  });

  final String? path;
  final double radius;
  final String name;
  final int avatarStyle;
  final AvatarGender avatarGender;

  @override
  Widget build(BuildContext context) {
    final file = path == null ? null : File(path!);
    final canShowFile = file != null && file.existsSync();

    if (canShowFile) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        backgroundImage: FileImage(file),
      );
    }

    return _GeneratedAvatar(
      radius: radius,
      name: name,
      avatarStyle: avatarStyle,
      avatarGender: avatarGender,
    );
  }
}

class AvatarChoice {
  const AvatarChoice({required this.style, required this.gender});

  final int style;
  final AvatarGender gender;
}

Future<AvatarChoice?> showAvatarStylePicker(
  BuildContext context, {
  required String name,
  required int currentStyle,
  required AvatarGender currentGender,
}) {
  List<int> buildOptions(int currentStyle) {
    final random = math.Random();
    final options = <int>{currentStyle};
    while (options.length < 9) {
      options.add(random.nextInt(5000));
    }
    return options.toList();
  }

  return showDialog<AvatarChoice>(
    context: context,
    builder: (context) {
      var selectedGender = currentGender;
      var options = buildOptions(currentStyle);

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 40,
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6F1),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 30,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a placeholder',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pick one of these generated profile icons.',
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<AvatarGender>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: AvatarGender.female,
                        label: Text('Girl'),
                        icon: Icon(Icons.face_3_outlined),
                      ),
                      ButtonSegment(
                        value: AvatarGender.male,
                        label: Text('Boy'),
                        icon: Icon(Icons.face_2_outlined),
                      ),
                    ],
                    selected: {selectedGender},
                    onSelectionChanged: (selection) {
                      setModalState(() {
                        selectedGender = selection.first;
                        options = buildOptions(
                          selection.first == currentGender
                              ? currentStyle
                              : math.Random().nextInt(5000),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1.14,
                        ),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected =
                          option == currentStyle &&
                          selectedGender == currentGender;
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).pop(
                          AvatarChoice(
                            style: option,
                            gender: selectedGender,
                          ),
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                width: isSelected ? 2.2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Center(
                              child: PhotoAvatar(
                                path: null,
                                radius: 22,
                                name: name,
                                avatarStyle: option,
                                avatarGender: selectedGender,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _GeneratedAvatar extends StatelessWidget {
  const _GeneratedAvatar({
    required this.radius,
    required this.name,
    required this.avatarStyle,
    required this.avatarGender,
  });

  final double radius;
  final String name;
  final int avatarStyle;
  final AvatarGender avatarGender;

  static const _palettes = [
    [Color(0xFFE3F2FD), Color(0xFF8DB5D9), Color(0xFF4D6F95)],
    [Color(0xFFFFF1D6), Color(0xFFE9B96E), Color(0xFFA96839)],
    [Color(0xFFEDE7F6), Color(0xFFB49DDB), Color(0xFF6F5C9B)],
    [Color(0xFFE4F3E2), Color(0xFF8FB87D), Color(0xFF4E7B4A)],
    [Color(0xFFFDE7EC), Color(0xFFD98EAA), Color(0xFF8D5068)],
    [Color(0xFFE6F7F3), Color(0xFF75BEB0), Color(0xFF3A8174)],
  ];

  static const _skinTones = [
    Color(0xFFFFE6CC),
    Color(0xFFF3D0AC),
    Color(0xFFE0B689),
    Color(0xFFC99563),
    Color(0xFFA57147),
    Color(0xFF6D462D),
  ];

  static const _hairTones = [
    Color(0xFF1F1612),
    Color(0xFF3D2920),
    Color(0xFF5B3B2A),
    Color(0xFF8A5B34),
    Color(0xFFB57A44),
    Color(0xFF6B4B3A),
    Color(0xFFD1A15B),
    Color(0xFFB6B0A3),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[avatarStyle % _palettes.length];
    final appearanceSeed = _stableHash('$name-${avatarGender.name}');
    final styleSeed = _stableHash('$name-$avatarStyle-${avatarGender.name}');
    final isFemale = avatarGender == AvatarGender.female;
    final skin = _skinTones[(styleSeed ~/ 5) % _skinTones.length];
    final hair = _hairTones[(styleSeed ~/ 3) % _hairTones.length];
    final shirt = palette[1];
    final backdrop = palette[0];
    final outline = palette[2];
    final mouthSmile = _fraction(appearanceSeed, 17);
    final fringeDepth = isFemale
        ? 0.16 + _fraction(styleSeed, 23) * 0.08
        : 0.08 + _fraction(styleSeed, 23) * 0.08;
    final hairVolume = isFemale
        ? 1.0 + _fraction(styleSeed, 31) * 0.12
        : 0.84 + _fraction(styleSeed, 31) * 0.18;
    final shoulderWidth = 1.08 + _fraction(appearanceSeed, 41) * 0.18;
    final headTilt = (0.5 - _fraction(appearanceSeed, 53)) * 0.08;
    final hairStyle = isFemale ? 10 + (styleSeed % 3) : (styleSeed % 4) + 1;
    final accessoryMode = styleSeed % 4;
    final hoodie = isFemale
        ? _fraction(styleSeed, 59) > 0.7
        : _fraction(styleSeed, 59) > 0.35;
    final sparkle = _fraction(styleSeed, 67) > 0.62;
    final faceWidth = isFemale ? radius * 0.74 : radius * 0.9;
    final faceHeight = isFemale ? radius * 0.82 : radius * 0.92;
    final faceTop = isFemale ? radius * 0.48 : radius * 0.42;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backdrop, Colors.white],
        ),
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -radius * 0.22,
              right: -radius * 0.1,
              child: _orb(
                radius * 0.85,
                Colors.white.withValues(alpha: 0.55),
              ),
            ),
            Positioned(
              bottom: -radius * 0.46,
              left: radius * (0.45 - shoulderWidth / 2),
              child: Container(
                width: radius * shoulderWidth,
                height: radius * 1.05,
                decoration: BoxDecoration(
                  color: shirt,
                  borderRadius: BorderRadius.circular(radius * 0.8),
                ),
              ),
            ),
            Positioned(
              bottom: radius * 0.1,
              left: radius * 0.4,
              child: Container(
                width: radius * 1.2,
                height: radius * 0.45,
                decoration: BoxDecoration(
                  color: shirt,
                  borderRadius: BorderRadius.circular(radius * 0.7),
                ),
              ),
            ),
            Center(
              child: Transform.rotate(
                angle: headTilt,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ..._hairBackLayer(
                      radius: radius,
                      color: hair,
                      hairVolume: hairVolume,
                      hairStyle: hairStyle,
                      isFemale: isFemale,
                    ),
                    Positioned(
                      top: faceTop,
                      child: Container(
                        width: faceWidth,
                        height: faceHeight,
                        decoration: BoxDecoration(
                          color: skin,
                          borderRadius: BorderRadius.circular(radius * 0.66),
                        ),
                      ),
                    ),
                    ..._hairFrontLayer(
                      radius: radius,
                      color: hair,
                      fringeDepth: fringeDepth,
                      hairVolume: hairVolume,
                      hairStyle: hairStyle,
                      isFemale: isFemale,
                    ),
                    Positioned(
                      top: isFemale ? radius * 0.78 : radius * 0.8,
                      child: SizedBox(
                        width: isFemale ? radius * 0.34 : radius * 0.44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _featureDot(radius * 0.08),
                            _featureDot(radius * 0.08),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: isFemale ? radius * 0.92 : radius * 0.96,
                      child: Container(
                        width: radius * 0.1,
                        height: radius * 0.15,
                        decoration: BoxDecoration(
                          color: outline.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(radius),
                        ),
                      ),
                    ),
                    Positioned(
                      top: isFemale ? radius * 1.0 : radius * 1.06,
                      child: CustomPaint(
                        size: Size(radius * 0.42, radius * 0.22),
                        painter: _SmilePainter(
                          color: const Color(0xFF5B3424),
                          smile: mouthSmile,
                        ),
                      ),
                    ),
                    if (accessoryMode == 1)
                      Positioned(
                        top: isFemale ? radius * 0.66 : radius * 0.7,
                        child: CustomPaint(
                          size: Size(radius * 0.8, radius * 0.28),
                          painter: _GlassesPainter(
                            color: outline.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                    if (accessoryMode == 2)
                      Positioned(
                        top: isFemale ? radius * 0.24 : radius * 0.28,
                        right: radius * 0.34,
                        child: Transform.rotate(
                          angle: math.pi / 12,
                          child: Icon(
                            Icons.auto_awesome,
                            size: radius * 0.2,
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                        ),
                      ),
                    if (accessoryMode == 3)
                      Positioned(
                        top: isFemale ? radius * 0.28 : radius * 0.32,
                        left: radius * 0.28,
                        child: Transform.rotate(
                          angle: -math.pi / 10,
                          child: Icon(
                            Icons.bolt_rounded,
                            size: radius * 0.18,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ),
                    if (hoodie)
                      Positioned(
                        bottom: radius * 0.02,
                        child: Container(
                          width: radius * 0.64,
                          height: radius * 0.36,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.32),
                              width: radius * 0.05,
                            ),
                            borderRadius: BorderRadius.circular(radius),
                          ),
                        ),
                      ),
                    if (sparkle)
                      Positioned(
                        top: radius * 0.2,
                        left: radius * 0.18,
                        child: Icon(
                          Icons.circle,
                          size: radius * 0.1,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _featureDot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF2C201A),
      ),
    );
  }

  List<Widget> _hairBackLayer({
    required double radius,
    required Color color,
    required double hairVolume,
    required int hairStyle,
    required bool isFemale,
  }) {
    if (!isFemale) {
      return const [];
    }

    final width = switch (hairStyle) {
      10 => radius * 1.02,
      11 => radius * 1.08,
      _ => radius * 1.06,
    } * hairVolume;
    final height = switch (hairStyle) {
      10 => radius * 0.96,
      11 => radius * 1.04,
      _ => radius * 1.0,
    };

    return [
      Positioned(
        top: radius * 0.28,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radius),
              topRight: Radius.circular(radius),
              bottomLeft: Radius.circular(radius * 0.72),
              bottomRight: Radius.circular(radius * 0.72),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _hairFrontLayer({
    required double radius,
    required Color color,
    required double fringeDepth,
    required double hairVolume,
    required int hairStyle,
    required bool isFemale,
  }) {
    if (isFemale) {
      final fringeWidth = switch (hairStyle) {
        10 => radius * 0.78,
        11 => radius * 0.84,
        _ => radius * 0.8,
      } * hairVolume;
      final fringeHeight = switch (hairStyle) {
        10 => radius * (0.08 + fringeDepth),
        11 => radius * (0.12 + fringeDepth),
        _ => radius * (0.1 + fringeDepth),
      };

      return [
        Positioned(
          top: radius * 0.38,
          child: Container(
            width: fringeWidth,
            height: fringeHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(radius * 0.8),
                topRight: Radius.circular(radius * 0.8),
                bottomLeft: Radius.circular(radius * 0.42),
                bottomRight: Radius.circular(radius * 0.42),
              ),
            ),
          ),
        ),
      ];
    }

    final top = switch (hairStyle) {
      1 => radius * 0.28,
      2 => radius * 0.24,
      3 => radius * 0.26,
      _ => radius * 0.2,
    };
    final width = switch (hairStyle) {
      1 => radius * 0.88,
      2 => radius * 0.96,
      3 => radius * 0.94,
      _ => radius * 0.82,
    } * hairVolume;
    final height = switch (hairStyle) {
      1 => radius * 0.18,
      2 => radius * 0.22,
      3 => radius * 0.16,
      _ => radius * 0.24,
    };

    return [
      Positioned(
        top: top,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radius),
              topRight: Radius.circular(radius),
              bottomLeft: Radius.circular(radius * 0.34),
              bottomRight: Radius.circular(radius * 0.34),
            ),
          ),
        ),
      ),
      if (hairStyle == 4)
        Positioned(
          top: radius * 0.4,
          child: Container(
            width: radius * 0.3,
            height: radius * 0.07,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ),
    ];
  }

  double _fraction(int seed, int salt) {
    final value = ((seed ~/ salt) % 1000).abs();
    return value / 1000;
  }

  int _stableHash(String value) {
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    return hash;
  }
}

class _SmilePainter extends CustomPainter {
  const _SmilePainter({required this.color, required this.smile});

  final Color color;
  final double smile;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.18
      ..strokeCap = StrokeCap.round;

    final curve = (smile - 0.5) * size.height * 0.9;
    final path = Path()
      ..moveTo(0, size.height * 0.45)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 0.45 + curve,
        size.width,
        size.height * 0.45,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SmilePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.smile != smile;
  }
}

class _GlassesPainter extends CustomPainter {
  const _GlassesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.11;

    final lensWidth = size.width * 0.32;
    final lensHeight = size.height * 0.62;
    final top = size.height * 0.12;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, top, lensWidth, lensHeight),
        Radius.circular(size.height * 0.2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - lensWidth, top, lensWidth, lensHeight),
        Radius.circular(size.height * 0.2),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(lensWidth, top + lensHeight * 0.45),
      Offset(size.width - lensWidth, top + lensHeight * 0.45),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassesPainter oldDelegate) {
    return oldDelegate.color != color;
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
