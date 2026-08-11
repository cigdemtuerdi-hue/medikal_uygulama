import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';

const _prefsKey = 'founding_story_welcome_v1_seen';

/// Shows the founding-story welcome once after the user enters the app.
Future<void> maybeShowFoundingStoryWelcome(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_prefsKey) == true) return;
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const FoundingStoryWelcomeSheet(markSeenOnClose: true),
  );
}

/// Full founding story body (About + welcome sheet).
class FoundingStoryContent extends StatelessWidget {
  const FoundingStoryContent({super.key, this.showContinue = false});

  final bool showContinue;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          loc.t('story.title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryDeepBlue,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          loc.t('story.greeting'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          loc.t('story.whoTitle'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryDeepBlue,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          loc.t('story.whoBody1'),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 12),
        Text(
          loc.t('story.whoBody2'),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 22),
        Text(
          loc.t('story.missionTitle'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryDeepBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loc.t('story.missionBody'),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 22),
        Text(
          loc.t('story.visionTitle'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryDeepBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loc.t('story.visionBody'),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        if (showContinue) ...[
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(loc.t('story.continueCta')),
          ),
        ],
      ],
    );
  }
}

class FoundingStoryWelcomeSheet extends StatefulWidget {
  const FoundingStoryWelcomeSheet({super.key, this.markSeenOnClose = false});

  final bool markSeenOnClose;

  @override
  State<FoundingStoryWelcomeSheet> createState() =>
      _FoundingStoryWelcomeSheetState();
}

class _FoundingStoryWelcomeSheetState extends State<FoundingStoryWelcomeSheet> {
  @override
  void dispose() {
    if (widget.markSeenOnClose) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool(_prefsKey, true);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const FoundingStoryContent(showContinue: true),
          ],
        ),
      ),
    );
  }
}
