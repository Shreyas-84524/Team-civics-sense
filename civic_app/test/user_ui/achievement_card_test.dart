import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/User UI/widgets/rewards/achievement_card.dart';
import 'package:civic_app/core/models/reward_model.dart';
import 'package:civic_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('AchievementCard renders locked state with requirement and progress', (tester) async {
    const lockedAchievement = CivicAchievement(
      id: 'evidence_expert',
      title: 'Evidence Expert',
      description: 'Useful evidence helps officers act.',
      howToUnlock: 'Provide useful images on 5 verified complaints.',
      icon: Icons.photo_camera_outlined,
      isUnlocked: false,
      currentProgress: 3,
      targetProgress: 5,
    );

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: AchievementCard(achievement: lockedAchievement),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and lock icon
    expect(find.text('Evidence Expert'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

    // Verify progress text and percentage
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Tap to open details dialog
    await tester.tap(find.byType(AchievementCard));
    await tester.pumpAndSettle();

    expect(find.text('How to Unlock'), findsOneWidget);
    expect(find.text('Provide useful images on 5 verified complaints.'), findsWidgets);
    expect(find.text('3 / 5 (60%)'), findsOneWidget);
  });

  testWidgets('AchievementCard renders unlocked state with checkmark and unlock date', (tester) async {
    final unlockedAchievement = CivicAchievement(
      id: 'resolution_champion',
      title: 'Resolution Champion',
      description: 'Follow reports through to resolution.',
      howToUnlock: 'Have 5 eligible complaints reach resolution.',
      icon: Icons.emoji_events_outlined,
      isUnlocked: true,
      unlockedAt: DateTime(2026, 10, 8),
      currentProgress: 5,
      targetProgress: 5,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: AchievementCard(achievement: unlockedAchievement),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and check icon
    expect(find.text('Resolution Champion'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('Unlocked 08/10/2026'), findsOneWidget);

    // Tap to open details dialog
    await tester.tap(find.byType(AchievementCard));
    await tester.pumpAndSettle();

    expect(find.text('Unlocked 08/10/2026'), findsWidgets);
    expect(find.text('Follow reports through to resolution.'), findsWidgets);
  });
}
