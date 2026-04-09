import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';

const _referralOptions = [
  'Bitte wählen …',
  'App Store / Play Store',
  'Freunde oder Familie',
  'Instagram / TikTok',
  'YouTube',
  'Google-Suche',
  'Podcast',
  'Sonstiges',
];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Step 1
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  final _step1Key = GlobalKey<FormState>();

  // Step 2
  final _communityNameCtrl = TextEditingController();
  final _householdNameCtrl = TextEditingController();
  final _step2Key = GlobalKey<FormState>();

  // Step 3
  String _referral = _referralOptions[0];
  bool _acceptedTerms = false;
  bool _acceptedNewsletter = false;

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _communityNameCtrl.dispose();
    _householdNameCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    bool valid = false;
    if (_currentPage == 0) valid = _step1Key.currentState?.validate() ?? false;
    if (_currentPage == 1) valid = _step2Key.currentState?.validate() ?? false;
    if (!valid) return;
    FocusScope.of(context).unfocus();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte akzeptiere die Nutzungsbedingungen.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (!mounted) return;
    }

    await ref.read(authNotifierProvider.notifier).signUpWithProfile(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _communityNameCtrl.text.trim(),
          referralSource: _referral == _referralOptions[0] ? null : _referral,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      context.go(
        '/welcome-registered',
        extra: _communityNameCtrl.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Fortschrittsanzeige ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: _currentPage == 0
                            ? () => context.pop()
                            : _prevPage,
                        visualDensity: VisualDensity.compact,
                      ),
                      const Spacer(),
                      Text(
                        'Schritt ${_currentPage + 1} von 3',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Fortschrittsbalken
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / 3,
                      minHeight: 6,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            // ── Seiten ───────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _Step1(
                    formKey: _step1Key,
                    emailCtrl: _emailCtrl,
                    passwordCtrl: _passwordCtrl,
                    confirmCtrl: _confirmCtrl,
                    obscurePassword: _obscurePassword,
                    obscureConfirm: _obscureConfirm,
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onToggleConfirm: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    onNext: _nextPage,
                    onLogin: () => context.pop(),
                  ),
                  _Step2(
                    formKey: _step2Key,
                    communityNameCtrl: _communityNameCtrl,
                    householdNameCtrl: _householdNameCtrl,
                    onNext: _nextPage,
                  ),
                  _Step3(
                    referral: _referral,
                    acceptedTerms: _acceptedTerms,
                    acceptedNewsletter: _acceptedNewsletter,
                    isLoading: _isLoading,
                    onReferralChanged: (v) => setState(() => _referral = v),
                    onTermsChanged: (v) =>
                        setState(() => _acceptedTerms = v ?? false),
                    onNewsletterChanged: (v) =>
                        setState(() => _acceptedNewsletter = v ?? false),
                    onSubmit: _submit,
                    onShowTerms: () => _showTermsDialog(context),
                    onShowPrivacy: () => _showPrivacyDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nutzungsbedingungen'),
        content: const SingleChildScrollView(
          child: Text(
            'Durch die Nutzung von kokomu erklärst du dich mit unseren '
            'Nutzungsbedingungen einverstanden. kokomu dient der persönlichen '
            'Nutzung zur Verwaltung von Lebensmitteln und Rezepten. '
            'Die Weitergabe von Inhalten Dritter ist nicht gestattet. '
            'Wir behalten uns vor, Konten bei Verstößen zu sperren.\n\n'
            'Stand: April 2026',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Datenschutzerklärung'),
        content: const SingleChildScrollView(
          child: Text(
            'kokomu speichert deine Daten sicher über Supabase. '
            'Deine E-Mail-Adresse wird nur für die Authentifizierung verwendet. '
            'Wir geben keine persönlichen Daten an Dritte weiter. '
            'Du kannst dein Konto und alle Daten jederzeit löschen.\n\n'
            'Stand: April 2026',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}

// ─── Schritt 1: E-Mail + Passwort ────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onNext;
  final VoidCallback onLogin;

  const _Step1({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onNext,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Icon(Icons.lock_outline_rounded,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'Zugangsdaten',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            Text(
              'Mit welcher E-Mail möchtest du dich anmelden?',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // E-Mail
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'E-Mail-Adresse',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Bitte E-Mail eingeben';
                if (!v.contains('@') || !v.contains('.')) {
                  return 'Ungültige E-Mail-Adresse';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Passwort
            TextFormField(
              controller: passwordCtrl,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Passwort',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Bitte Passwort eingeben';
                if (v.length < 8) return 'Mindestens 8 Zeichen';
                if (!v.contains(RegExp(r'[0-9]'))) {
                  return 'Mindestens eine Zahl';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Passwort bestätigen
            TextFormField(
              controller: confirmCtrl,
              obscureText: obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onNext(),
              decoration: InputDecoration(
                labelText: 'Passwort bestätigen',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(obscureConfirm
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: onToggleConfirm,
                ),
              ),
              validator: (v) {
                if (v != passwordCtrl.text) {
                  return 'Passwörter stimmen nicht überein';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Weiter', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onLogin,
              child: const Text('Bereits registriert? Anmelden'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Schritt 2: Namen ────────────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController communityNameCtrl;
  final TextEditingController householdNameCtrl;
  final VoidCallback onNext;

  const _Step2({
    required this.formKey,
    required this.communityNameCtrl,
    required this.householdNameCtrl,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Icon(Icons.badge_outlined,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'Deine Namen',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            Text(
              'Wie sollen andere dich kennen?',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Community-Name
            TextFormField(
              controller: communityNameCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Community-Name *',
                hintText: 'z. B. KochProfi42',
                helperText: 'Öffentlich sichtbar in Rezepten & Wochenplänen',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Bitte einen Namen eingeben';
                }
                if (v.trim().length < 2) return 'Mindestens 2 Zeichen';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Haushalts-Spitzname
            TextFormField(
              controller: householdNameCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onNext(),
              decoration: const InputDecoration(
                labelText: 'Haushalts-Spitzname (optional)',
                hintText: 'z. B. Papa, Mama, Roomie',
                helperText:
                    'Nur für deinen Haushalt sichtbar – kann später geändert werden',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              maxLength: 30,
            ),
            const SizedBox(height: 24),

            // Infokarte
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.secondaryContainer,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18,
                      color: theme.colorScheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dein Community-Name ist öffentlich. Der Haushalts-Spitzname bleibt privat.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Weiter', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Schritt 3: Woher + Checkboxen + Registrieren ────────────────────────────

class _Step3 extends StatelessWidget {
  final String referral;
  final bool acceptedTerms;
  final bool acceptedNewsletter;
  final bool isLoading;
  final ValueChanged<String> onReferralChanged;
  final ValueChanged<bool?> onTermsChanged;
  final ValueChanged<bool?> onNewsletterChanged;
  final VoidCallback onSubmit;
  final VoidCallback onShowTerms;
  final VoidCallback onShowPrivacy;

  const _Step3({
    required this.referral,
    required this.acceptedTerms,
    required this.acceptedNewsletter,
    required this.isLoading,
    required this.onReferralChanged,
    required this.onTermsChanged,
    required this.onNewsletterChanged,
    required this.onSubmit,
    required this.onShowTerms,
    required this.onShowPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Icon(Icons.celebration_rounded,
              size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Fast geschafft!',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          Text(
            'Noch ein paar letzte Angaben',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Woher kennst du uns
          DropdownButtonFormField<String>(
            value: referral,
            decoration: const InputDecoration(
              labelText: 'Woher kennst du kokomu?',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            items: _referralOptions
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => onReferralChanged(v!),
          ),
          const SizedBox(height: 24),

          // Nutzungsbedingungen
          _CheckRow(
            value: acceptedTerms,
            onChanged: onTermsChanged,
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall,
                children: [
                  const TextSpan(text: 'Ich akzeptiere die '),
                  TextSpan(
                    text: 'Nutzungsbedingungen',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = onShowTerms,
                  ),
                  const TextSpan(text: ' und die '),
                  TextSpan(
                    text: 'Datenschutzerklärung',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = onShowPrivacy,
                  ),
                  const TextSpan(text: '. *'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Newsletter
          _CheckRow(
            value: acceptedNewsletter,
            onChanged: onNewsletterChanged,
            child: Text(
              'Ich möchte gelegentlich Rezept-Tipps & News erhalten (optional)',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 32),

          // Registrieren Button
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Jetzt registrieren 🎉',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            '* Pflichtfeld',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Widget child;

  const _CheckRow({
    required this.value,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: child,
          ),
        ),
      ],
    );
  }
}

