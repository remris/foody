import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/features/household/presentation/household_chat_provider.dart';

class HouseholdChatSection extends ConsumerStatefulWidget {
  const HouseholdChatSection({super.key});

  @override
  ConsumerState<HouseholdChatSection> createState() =>
      _HouseholdChatSectionState();
}

class _HouseholdChatSectionState
    extends ConsumerState<HouseholdChatSection> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _showQuickMessages = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send({String? quickContent, String? quickEmoji}) async {
    final content = quickContent ?? _controller.text.trim();
    if (content.isEmpty) return;

    _controller.clear();
    setState(() => _showQuickMessages = false);

    try {
      await ref.read(householdChatProvider.notifier).sendMessage(
            content,
            emoji: quickEmoji,
          );
      // Zum Anfang scrollen (neueste Nachricht oben)
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } on ProfanityException catch (e) {
      if (mounted) {
        // Text wiederherstellen damit der User korrigieren kann
        _controller.text = content;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(e.message)),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nachricht konnte nicht gesendet werden')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(householdChatProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Haushalt-Chat',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.bolt_rounded,
                  size: 18,
                  color: _showQuickMessages
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant),
              tooltip: 'Schnellnachrichten',
              onPressed: () =>
                  setState(() => _showQuickMessages = !_showQuickMessages),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Quick-Messages ───────────────────────────────────────────────
        if (_showQuickMessages) ...[
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: kQuickMessages.map((q) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    avatar: Text(q.$1,
                        style: const TextStyle(fontSize: 14)),
                    label: Text(q.$2,
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () =>
                        _send(quickContent: q.$2, quickEmoji: q.$1),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // ── Nachrichten-Liste ────────────────────────────────────────────
        Card(
          child: SizedBox(
            height: 280,
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Chat nicht verfügbar',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
              data: (messages) => messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Noch keine Nachrichten.\nSchreib die erste!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true, // neueste oben
                      padding: const EdgeInsets.all(8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.userId == currentUserId;
                        return _MessageBubble(
                          message: msg,
                          isMe: isMe,
                          onDelete: isMe
                              ? () => ref
                                  .read(householdChatProvider.notifier)
                                  .deleteMessage(msg.id)
                              : null,
                        );
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Eingabefeld ──────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Nachricht an den Haushalt…',
                  hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _send,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
                minimumSize: Size.zero,
              ),
              child: const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Nachrichtenblase ──────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final HouseholdMessage message;
  final bool isMe;
  final VoidCallback? onDelete;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (nur für andere)
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Bubble
          Flexible(
            child: GestureDetector(
              onLongPress: onDelete != null
                  ? () => showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Nachricht löschen?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Abbrechen'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                onDelete!();
                              },
                              style: FilledButton.styleFrom(
                                  backgroundColor:
                                      theme.colorScheme.error),
                              child: const Text('Löschen'),
                            ),
                          ],
                        ),
                      )
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Sender-Name (nur für andere)
                    if (!isMe)
                      Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    // Inhalt
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.emoji != null) ...[
                          Text(message.emoji!,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            message.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: isMe
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Zeitstempel
                    Text(
                      message.timeFormatted,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? theme.colorScheme.onPrimary
                                .withValues(alpha: 0.7)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

