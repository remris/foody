import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kokomi/features/profile/presentation/profile_provider.dart';
import 'package:kokomi/models/user_profile.dart';

/// Zeigt entweder die Follower- oder die Following-Liste eines Users.
class FollowersScreen extends ConsumerWidget {
  final String userId;
  final bool showFollowers; // true = Follower, false = Folgt

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.showFollowers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = showFollowers ? 'Follower' : 'Folgt';
    final provider = showFollowers
        ? userFollowersProvider(userId)
        : userFollowingProvider(userId);
    final listAsync = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 8),
              Text('Fehler: $e', textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (users) => users.isEmpty
            ? _EmptyState(showFollowers: showFollowers)
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (ctx, i) => _UserTile(
                  profile: users[i],
                  onTap: () => context.push('/profile/${users[i].id}'),
                  ref: ref,
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool showFollowers;
  const _EmptyState({required this.showFollowers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            showFollowers ? Icons.people_outline : Icons.person_add_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            showFollowers
                ? 'Noch keine Follower'
                : 'Folgt noch niemandem',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            showFollowers
                ? 'Teile deine Rezepte um Follower zu gewinnen!'
                : 'Entdecke andere Köche in der Community.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final UserProfile profile;
  final VoidCallback onTap;
  final WidgetRef ref;

  const _UserTile({
    required this.profile,
    required this.onTap,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.read(userProfileRepositoryProvider).currentUserId;
    final isMe = me == profile.id;
    final followState = isMe ? false : ref.watch(followProvider(profile.id));

    final initials = profile.displayName.isNotEmpty
        ? profile.displayName.substring(0, 1).toUpperCase()
        : '?';

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: profile.avatarUrl?.isNotEmpty == true
            ? NetworkImage(profile.avatarUrl!)
            : null,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: profile.avatarUrl?.isNotEmpty == true
            ? null
            : Text(initials,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                )),
      ),
      title: Text(
        profile.displayName.isNotEmpty ? profile.displayName : 'Kokomi-User',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: profile.bio.isNotEmpty
          ? Text(
              profile.bio,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: isMe
          ? null
          : _FollowButton(userId: profile.id, isFollowing: followState),
    );
  }
}

class _FollowButton extends ConsumerWidget {
  final String userId;
  final bool isFollowing;
  const _FollowButton({required this.userId, required this.isFollowing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isFollowing
        ? OutlinedButton(
            onPressed: () => ref.read(followProvider(userId).notifier).toggle(userId),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Folge ich'),
          )
        : FilledButton(
            onPressed: () {
              ref.read(followProvider(userId).notifier).setInitial(false);
              ref.read(followProvider(userId).notifier).toggle(userId);
            },
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Folgen'),
          );
  }
}

