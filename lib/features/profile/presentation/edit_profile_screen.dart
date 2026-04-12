import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kokomu/features/profile/presentation/profile_provider.dart';
import 'package:kokomu/models/user_profile.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _householdNicknameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _instaCtrl;
  late final TextEditingController _tiktokCtrl;
  late final TextEditingController _ytCtrl;
  late final TextEditingController _webCtrl;

  bool _isLoading = false;
  String? _newAvatarUrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _householdNicknameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _instaCtrl = TextEditingController();
    _tiktokCtrl = TextEditingController();
    _ytCtrl = TextEditingController();
    _webCtrl = TextEditingController();

    // Felder mit aktuellen Daten befüllen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(ownProfileProvider).valueOrNull;
      if (profile != null) _fillFrom(profile);
    });
  }

  void _fillFrom(UserProfile profile) {
    _nameCtrl.text = profile.displayName;
    _householdNicknameCtrl.text = profile.householdNickname ?? '';
    _bioCtrl.text = profile.bio;
    _instaCtrl.text = profile.socialLinks.instagram ?? '';
    _tiktokCtrl.text = profile.socialLinks.tiktok ?? '';
    _ytCtrl.text = profile.socialLinks.youtube ?? '';
    _webCtrl.text = profile.socialLinks.website ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _householdNicknameCtrl.dispose();
    _bioCtrl.dispose();
    _instaCtrl.dispose();
    _tiktokCtrl.dispose();
    _ytCtrl.dispose();
    _webCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (xFile == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await xFile.readAsBytes();
      final ext = xFile.path.split('.').last.toLowerCase();
      final repo = ref.read(userProfileRepositoryProvider);
      final userId = repo.currentUserId;
      if (userId == null) return;
      final url = await repo.uploadAvatar(userId, bytes, ext);
      setState(() => _newAvatarUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Avatar-Upload fehlgeschlagen: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(ownProfileProvider.notifier).updateProfile(
            displayName: _nameCtrl.text.trim(),
            householdNickname: _householdNicknameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            avatarUrl: _newAvatarUrl,
            socialLinks: SocialLinks(
              instagram: _instaCtrl.text.trim(),
              tiktok: _tiktokCtrl.text.trim(),
              youtube: _ytCtrl.text.trim(),
              website: _webCtrl.text.trim(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil gespeichert'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(ownProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil bearbeiten'),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Speichern'),
                ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (profile) {
          // Felder einmalig befüllen wenn noch leer
          if (_nameCtrl.text.isEmpty) _fillFrom(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ─────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            backgroundImage: (_newAvatarUrl ??
                                        profile.avatarUrl) !=
                                    null
                                ? NetworkImage(
                                    _newAvatarUrl ?? profile.avatarUrl!)
                                : null,
                            child: (_newAvatarUrl ?? profile.avatarUrl) ==
                                    null
                                ? Text(
                                    profile.initials,
                                    style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: theme
                                            .colorScheme.onPrimaryContainer),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.camera_alt_rounded,
                                  size: 16,
                                  color: theme.colorScheme.onPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Basis-Infos ─────────────────────────────────────
                  Text('Basis-Infos',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Anzeigename',
                      hintText: 'Wird öffentlich in der Community angezeigt',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name darf nicht leer sein'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _householdNicknameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Spitzname (Haushalt & Community)',
                      hintText: 'z.B. Papa, Mama, Roomie – in Haushalt & Community sichtbar',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    maxLength: 30,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Erzähl etwas über dich…',
                      prefixIcon: Icon(Icons.info_outline),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Social Media ────────────────────────────────────
                  Text('Social Media',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary)),
                  const SizedBox(height: 10),
                  _SocialField(
                    controller: _instaCtrl,
                    label: 'Instagram',
                    hint: '@deinname',
                    faIcon: FontAwesomeIcons.instagram,
                    color: const Color(0xFFE1306C),
                  ),
                  const SizedBox(height: 10),
                  _SocialField(
                    controller: _tiktokCtrl,
                    label: 'TikTok',
                    hint: '@deinname',
                    faIcon: FontAwesomeIcons.tiktok,
                    color: const Color(0xFF010101),
                  ),
                  const SizedBox(height: 10),
                  _SocialField(
                    controller: _ytCtrl,
                    label: 'YouTube',
                    hint: 'https://youtube.com/@...',
                    faIcon: FontAwesomeIcons.youtube,
                    color: const Color(0xFFFF0000),
                  ),
                  const SizedBox(height: 10),
                  _SocialField(
                    controller: _webCtrl,
                    label: 'Website',
                    hint: 'https://deine-website.de',
                    faIcon: null,
                    materialIcon: Icons.language_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Profil speichern'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SocialField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Object? faIcon;      // FaIconData oder null
  final IconData? materialIcon;
  final Color color;

  const _SocialField({
    required this.controller,
    required this.label,
    required this.hint,
    this.faIcon,
    this.materialIcon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Widget prefixIcon;
    if (faIcon != null) {
      prefixIcon = Padding(
        padding: const EdgeInsets.all(12),
        child: FaIcon(faIcon as dynamic, size: 18, color: color),
      );
    } else {
      prefixIcon = Icon(materialIcon, color: color);
    }

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.url,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
      ),
    );
  }
}

