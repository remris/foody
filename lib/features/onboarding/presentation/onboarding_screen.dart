import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Interaktiver Onboarding-Flow beim ersten App-Start (4 Screens).
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  static const _pages = [
    _OnboardingPage(
      emoji: '',
      title: 'Willkommen bei Kokomi!',
      subtitle: 'Dein smarter Küchenhelfer',
      description:
          'Schluss mit abgelaufenen Lebensmitteln und leeren Kühlschränken.\n'
          'Kokomi hilft dir, deinen Alltag in der Küche einfacher zu machen.',
      color: Color(0xFF3D6B8F),
      features: [],
    ),
    _OnboardingPage(
      emoji: '',
      title: 'Scannen & Organisieren',
      subtitle: 'In Sekunden erfasst',
      description:
          'Scanne einfach den Barcode deiner Lebensmittel.\n'
          'Kokomi erkennt das Produkt und fügt es automatisch\n'
          'deinem Vorrat hinzu.',
      color: Color(0xFF2E5F7A),
      features: [
        ('📦', 'Barcode-Scanner'),
        ('⏰', 'Ablauf-Erinnerungen'),
        ('🛒', 'Einkaufsliste auto'),
        ('🏠', 'Haushalt teilen'),
      ],
    ),
    _OnboardingPage(
      emoji: '',
      title: 'KI-Rezepte',
      subtitle: 'Kochen aus dem Vorrat',
      description:
          'Was soll ich heute kochen?\n'
          'Kokomi schlägt dir Rezepte vor, die genau\n'
          'zu deinen vorhandenen Zutaten passen.',
      color: Color(0xFF2A5470),
      features: [
        ('✨', 'KI-Rezeptvorschläge'),
        ('📅', 'Wochenplaner'),
        ('📊', 'Kalorien-Tracking'),
        ('🔥', 'Koch-Streak'),
      ],
    ),
    _OnboardingPage(
      emoji: '',
      title: 'Community',
      subtitle: 'Teile & entdecke',
      description:
          'Teile deine Rezepte und Wochenpläne\n'
          'mit der Kokomi-Community und entdecke\n'
          'Ideen von anderen Köchen.',
      color: Color(0xFF1E4A63),
      features: [
        ('🍽️', 'Rezepte teilen'),
        ('📋', 'Pläne veröffentlichen'),
        ('❤️', 'Likes & Bewertungen'),
        ('💬', 'Kommentare'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _fadeController.reverse().then((_) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
        _fadeController.forward();
      });
    } else {
      _complete();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _fadeController.reverse().then((_) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
        _fadeController.forward();
      });
    }
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    HapticFeedback.mediumImpact();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;
    final isFirst = _currentPage == 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: page.color,
        body: Stack(
          children: [
            // Hintergrund-Gradient
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      page.color,
                      page.color.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Zurück-Button
                        if (!isFirst)
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white),
                            onPressed: _prevPage,
                          )
                        else
                          const SizedBox(width: 48),

                        // Seiten-Dots
                        Row(
                          children: List.generate(_pages.length, (i) {
                            final isActive = i == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),

                        // Überspringen
                        TextButton(
                          onPressed: _complete,
                          child: Text(
                            'Überspringen',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Haupt-Content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (i) {
                        setState(() => _currentPage = i);
                        _fadeController.forward(from: 0);
                        HapticFeedback.selectionClick();
                      },
                      itemBuilder: (context, index) {
                        final p = _pages[index];
                        return FadeTransition(
                          opacity: _fadeAnim,
                          child: _PageContent(page: p),
                        );
                      },
                    ),
                  ),

                  // Bottom Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      children: [
                        // Weiter / Los-Button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _nextPage,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: page.color,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLast ? 'Jetzt starten' : 'Weiter',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isLast
                                      ? Icons.rocket_launch_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (isLast) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                _complete().then((_) {});
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.white54, width: 1.5),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Bereits registriert? Anmelden',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page Data ────────────────────────────────────────────────────────────────

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final List<(String, String)> features;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.features,
  });
}

// ─── Page Content ─────────────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fester Abstand von oben – Logo immer auf gleicher Höhe
          SizedBox(height: screenHeight * 0.12),

          // Logo (alle Seiten)
          Image.asset(
            'assets/icon/foody_icon2-Photoroom.png',
            width: 110,
            height: 110,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 36),

          // Subtitle-Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              page.subtitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Titel
          Text(
            page.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),

          // Beschreibung
          Text(
            page.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              height: 1.6,
            ),
          ),

          // Feature-Chips
          if (page.features.isNotEmpty) ...[
            const SizedBox(height: 28),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: page.features
                  .map((f) => _FeatureChip(emoji: f.$1, label: f.$2))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Feature Chip ─────────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _FeatureChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

/// Prüft ob der Onboarding-Flow schon gezeigt wurde.
Future<bool> isOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
}
