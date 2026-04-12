import 'package:flutter/material.dart';

/// Standard-Tag-Vorschläge für Rezepte / Wochenpläne.
const kSuggestedTags = [
  'Airfryer', 'OnePot', 'MealPrep', 'Vegan', 'Vegetarisch',
  'Glutenfrei', 'Low Carb', 'High Protein', 'Schnell', 'Backen',
  'Suppe', 'Salat', 'Frühstück', 'Dessert', 'Snack',
  'Scharf', 'Comfort Food', 'Festlich', 'Familienküche',
  'Pescetarisch', 'Grillen', 'Brot', 'Sauerteig',
];

/// Bottom-Sheet zum Auswählen und Erstellen von Tags.
/// Gibt `List<String>` zurück oder `null` bei Abbruch.
class TagPickerSheet extends StatefulWidget {
  final List<String> selected;
  final List<String> suggestions;
  const TagPickerSheet({
    super.key,
    required this.selected,
    this.suggestions = kSuggestedTags,
  });

  @override
  State<TagPickerSheet> createState() => _TagPickerSheetState();

  /// Bequemer Helper: öffnet das Sheet und gibt die gewählten Tags zurück.
  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> selected,
    List<String> suggestions = kSuggestedTags,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TagPickerSheet(
        selected: List.from(selected),
        suggestions: suggestions,
      ),
    );
  }
}

class _TagPickerSheetState extends State<TagPickerSheet> {
  late final List<String> _selected;
  final _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _addCustom() {
    final t = _customCtrl.text.trim();
    if (t.isNotEmpty && !_selected.contains(t)) {
      setState(() => _selected.add(t));
      _customCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text('Tags auswählen',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: const Text('Fertig'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _customCtrl,
              decoration: InputDecoration(
                hintText: 'Eigenen Tag eingeben…',
                isDense: true,
                prefixIcon: const Icon(Icons.edit_outlined, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_rounded, size: 20),
                  onPressed: _addCustom,
                ),
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _addCustom(),
            ),
          ),
          if (_selected.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Ausgewählt',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _selected
                    .map((t) => InputChip(
                          label: Text(t, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _selected.remove(t)),
                          selected: true,
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Vorschläge',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.suggestions
                    .where((t) => !_selected.contains(t))
                    .map((t) => ActionChip(
                          label: Text(t, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() => _selected.add(t)),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

