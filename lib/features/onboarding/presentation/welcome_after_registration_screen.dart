import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wird nach erfolgreicher Registrierung angezeigt – Willkommensseite
class WelcomeAfterRegistrationScreen extends StatelessWidget {
  final String? displayName;
  const WelcomeAfterRegistrationScreen({super.key, this.displayName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = displayName?.split(' ').first ?? 'dort';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Großes Willkommens-Emoji
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🎉', style: TextStyle(fontSize: 64)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Willkommen, $name!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Dein kokomu-Konto wurde erfolgreich erstellt.\n'
                'Bitte bestätige noch deine E-Mail, damit du alle Funktionen nutzen kannst.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Feature-Cards
              _FeatureRow(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Produkte scannen',
                subtitle: 'Barcode scannen → automatisch im Vorrat',
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.auto_awesome_rounded,
                title: 'KI-Rezepte',
                subtitle: 'Rezepte aus deinen Zutaten generieren',
                color: Colors.purple,
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.calendar_month_rounded,
                title: 'Wochenplaner',
                subtitle: 'Plane deine Mahlzeiten für die ganze Woche',
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.people_rounded,
                title: 'Community',
                subtitle: 'Rezepte & Pläne mit anderen teilen',
                color: Colors.blue,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/login'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Zum Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

