// lib/widgets/interest_tags.dart
//
// Allows users to set local interest tags (e.g. #music, #gaming).
// Tags are broadcast in the UDP beacon so nearby peers with matching
// tags get a visual highlight. No tag data is stored on any server.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

const _kTagsKey = 'user_interest_tags';

const List<String> _availableTags = [
  '🎵 Music',
  '🎮 Gaming',
  '📚 Reading',
  '🎨 Art',
  '💻 Tech',
  '🎬 Films',
  '✈️ Travel',
  '🍕 Food',
  '🏋️ Fitness',
  '📸 Photos',
  '🤖 AI',
  '🎭 Drama',
];

class InterestTagsSheet extends StatefulWidget {
  const InterestTagsSheet({super.key});

  @override
  State<InterestTagsSheet> createState() => _InterestTagsSheetState();
}

class _InterestTagsSheetState extends State<InterestTagsSheet> {
  Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_kTagsKey) ?? [];
    setState(() => _selected = saved.toSet());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kTagsKey, _selected.toList());
    if (mounted) Navigator.pop(context, _selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'YOUR INTERESTS',
                    style: GoogleFonts.orbitron(
                      color: AppTheme.accent,
                      fontSize: 12,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'LOCAL ONLY',
                    style: GoogleFonts.spaceMono(
                      color: AppTheme.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Peers with matching tags are highlighted. Tags broadcast over LAN only.',
                style: GoogleFonts.spaceMono(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.asMap().entries.map((entry) {
                  final tag = entry.value;
                  final idx = entry.key;
                  final selected = _selected.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selected.remove(tag);
                        } else if (_selected.length < 5) {
                          _selected.add(tag);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.accentGlow
                            : AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.accent.withValues(alpha: 0.5)
                              : AppTheme.divider,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.spaceMono(
                          color: selected
                              ? AppTheme.accent
                              : AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                      .animate(delay: (idx * 40).ms)
                      .fadeIn(duration: 200.ms)
                      .scale(begin: const Offset(0.9, 0.9), duration: 200.ms);
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                '${_selected.length}/5 selected',
                style: GoogleFonts.spaceMono(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'SAVE TAGS',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String tag;
  final bool highlighted;

  const TagChip({super.key, required this.tag, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: highlighted
            ? AppTheme.accentGlow
            : AppTheme.stranger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: highlighted
              ? AppTheme.accent.withValues(alpha: 0.4)
              : AppTheme.stranger.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        tag,
        style: GoogleFonts.spaceMono(
          color: highlighted ? AppTheme.accent : AppTheme.stranger,
          fontSize: 9,
        ),
      ),
    );
  }
}
