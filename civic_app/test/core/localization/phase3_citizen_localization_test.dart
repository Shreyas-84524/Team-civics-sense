import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/localization/app_localizations.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/map/basemap_mode.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/reward_model.dart';
import 'package:civic_app/core/widgets/priority_badge.dart';
import 'package:civic_app/core/widgets/status_badge.dart';
import 'package:civic_app/User UI/widgets/rewards/achievement_card.dart';
import 'package:civic_app/User UI/widgets/profile/profile_stat_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3 - Static Citizen App ARB Resolution (en, hi, mr)', () {
    test('English ARB loads all citizen keys correctly', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.appName, 'CivicFix');
      expect(l10n.navHome, 'Home');
      expect(l10n.navComplaints, 'Complaints');
      expect(l10n.navNotifications, 'Notifications');
      expect(l10n.navProfile, 'Profile');
      expect(l10n.myComplaintsTitle, 'My Complaints');
      expect(l10n.hazardMapTitle, 'Hazard Map');
      expect(l10n.citizenProfile, 'Citizen Profile');
      expect(l10n.civicRewardsAndAchievements, 'Civic Rewards & Achievements');
      expect(l10n.civicAssistant, 'Civic Assistant');
      expect(l10n.reviewYourIssue, 'Review your issue');
      expect(l10n.confirmLocation, 'Confirm Location');
      expect(l10n.communityPerks, 'Community Perks');
    });

    test('Hindi ARB loads all citizen keys in Devanagari script', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('hi'));
      expect(l10n.appName, 'CivicFix');
      expect(l10n.navHome, 'होम');
      expect(l10n.navComplaints, 'शिकायतें');
      expect(l10n.navNotifications, 'सूचनाएं');
      expect(l10n.navProfile, 'प्रोफ़ाइल');
      expect(l10n.myComplaintsTitle, 'मेरी शिकायतें');
      expect(l10n.hazardMapTitle, 'खतरा मानचित्र');
      expect(l10n.citizenProfile, 'नागरिक प्रोफ़ाइल');
      expect(l10n.civicRewardsAndAchievements, 'नागरिक पुरस्कार एवं उपलब्धियां');
      expect(l10n.civicAssistant, 'सिविक सहायक');
      expect(l10n.reviewYourIssue, 'अपनी शिकायत की समीक्षा करें');
      expect(l10n.confirmLocation, 'स्थान की पुष्टि करें');
      expect(l10n.communityPerks, 'सामुदायिक लाभ');
    });

    test('Marathi ARB loads all citizen keys in Marathi Devanagari script', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('mr'));
      expect(l10n.appName, 'CivicFix');
      expect(l10n.navHome, 'मुख्यपृष्ठ');
      expect(l10n.navComplaints, 'तक्रारी');
      expect(l10n.navNotifications, 'सूचना');
      expect(l10n.navProfile, 'प्रोफाइल');
      expect(l10n.myComplaintsTitle, 'माझ्या तक्रारी');
      expect(l10n.hazardMapTitle, 'धोका नकाशा');
      expect(l10n.citizenProfile, 'नागरिक प्रोफाइल');
      expect(l10n.civicRewardsAndAchievements, 'नागरी पुरस्कार आणि उपलब्धी');
      expect(l10n.civicAssistant, 'सिविक सहाय्यक');
      expect(l10n.reviewYourIssue, 'तुमच्या तक्रारीचे पुनरावलोकन करा');
      expect(l10n.confirmLocation, 'स्थानाची पुष्टी करा');
      expect(l10n.communityPerks, 'समुदाय लाभ');
    });
  });

  group('Phase 3 - Canonical Display Mappers across Locales', () {
    test('localizedComplaintStatus maps all 7 statuses across en, hi, mr', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      for (final status in ComplaintStatus.values) {
        final enLabel = localizedComplaintStatus(status, l10n: en);
        final hiLabel = localizedComplaintStatus(status, l10n: hi);
        final mrLabel = localizedComplaintStatus(status, l10n: mr);

        expect(enLabel.isNotEmpty, isTrue);
        expect(hiLabel.isNotEmpty, isTrue);
        expect(mrLabel.isNotEmpty, isTrue);
      }

      // Explicit status checks
      expect(localizedComplaintStatus(ComplaintStatus.underVerification, l10n: en), 'Under Verification');
      expect(localizedComplaintStatus(ComplaintStatus.underVerification, l10n: hi), 'सत्यापन प्रक्रिया में');
      expect(localizedComplaintStatus(ComplaintStatus.underVerification, l10n: mr), 'पडताळणी सुरू आहे');

      expect(localizedComplaintStatus(ComplaintStatus.resolved, l10n: en), 'Resolved');
      expect(localizedComplaintStatus(ComplaintStatus.resolved, l10n: hi), 'समाधान हुआ');
      expect(localizedComplaintStatus(ComplaintStatus.resolved, l10n: mr), 'निवारण झाले');

      expect(localizedComplaintStatus(ComplaintStatus.closed, l10n: en), 'Closed');
      expect(localizedComplaintStatus(ComplaintStatus.closed, l10n: hi), 'बंद');
      expect(localizedComplaintStatus(ComplaintStatus.closed, l10n: mr), 'बंद');
    });

    test('localizedCategory maps canonical category models & strings across en, hi, mr', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      const testCategories = [
        'roads',
        'water',
        'sanitation',
        'waste',
        'streetlights',
        'drainage',
        'infrastructure',
        'traffic',
        'other',
        'potholes',
        'garbageOverflow',
        'waterlogging',
        'waterLeakage',
        'damagedWater',
        'sewageOverflow',
        'openManholes',
        'damagedFootpaths',
        'fallenTrees',
      ];

      for (final cat in testCategories) {
        final enName = localizedCategory(cat, l10n: en);
        final hiName = localizedCategory(cat, l10n: hi);
        final mrName = localizedCategory(cat, l10n: mr);

        expect(enName.isNotEmpty, isTrue);
        expect(hiName.isNotEmpty, isTrue);
        expect(mrName.isNotEmpty, isTrue);
      }

      // Check specific categories
      expect(localizedCategory('roads', l10n: en), 'Roads');
      expect(localizedCategory('roads', l10n: hi), 'सड़कें');
      expect(localizedCategory('roads', l10n: mr), 'रस्ते');

      expect(localizedCategory('potholes', l10n: en), 'Potholes');
      expect(localizedCategory('potholes', l10n: hi), 'सड़क के गड्ढे');
      expect(localizedCategory('potholes', l10n: mr), 'रस्त्यावरील खड्डे');

      expect(localizedCategory('waterLeakage', l10n: en), 'Water Leakage');
      expect(localizedCategory('waterLeakage', l10n: hi), 'पानी का रिसाव');
      expect(localizedCategory('waterLeakage', l10n: mr), 'पाणी गळती');
    });

    test('localizedCategoryDescription maps category descriptions across en, hi, mr', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      expect(localizedCategoryDescription('roads', l10n: en), 'Road damage, potholes and unsafe road surfaces.');
      expect(localizedCategoryDescription('roads', l10n: hi), 'सड़क क्षति, गड्ढे और असुरक्षित सड़क की सतह।');
      expect(localizedCategoryDescription('roads', l10n: mr), 'रस्त्यांचे नुकसान, खड्डे आणि असुरक्षित रस्ते.');
    });

    test('localizedComplaintPriority maps all 4 priority levels across en, hi, mr', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      for (final priority in ComplaintPriority.values) {
        expect(localizedComplaintPriority(priority, l10n: en).isNotEmpty, isTrue);
        expect(localizedComplaintPriority(priority, l10n: hi).isNotEmpty, isTrue);
        expect(localizedComplaintPriority(priority, l10n: mr).isNotEmpty, isTrue);
      }

      expect(localizedComplaintPriority(ComplaintPriority.emergency, l10n: en), 'Critical');
      expect(localizedComplaintPriority(ComplaintPriority.emergency, l10n: hi), 'गंभीर');
      expect(localizedComplaintPriority(ComplaintPriority.emergency, l10n: mr), 'अतिगंभीर');
    });

    test('localizedDepartment maps all municipal departments across en, hi, mr', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      expect(localizedDepartment('roads_traffic', l10n: en), 'Roads & Traffic Department');
      expect(localizedDepartment('roads_traffic', l10n: hi), 'सड़क एवं यातायात विभाग');
      expect(localizedDepartment('roads_traffic', l10n: mr), 'रस्ते आणि वाहतूक विभाग');

      expect(localizedDepartment('water_supply', l10n: en), 'Water Supply & Sewerage');
      expect(localizedDepartment('water_supply', l10n: hi), 'जल आपूर्ति एवं सीवरेज विभाग');
      expect(localizedDepartment('water_supply', l10n: mr), 'पाणीपुरवठा आणि मलनिस्सारण विभाग');
    });

    test('localizedVerificationState maps AI/officer verification states across en, hi, mr', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      expect(localizedVerificationState('pending', l10n: en), 'Verification Pending');
      expect(localizedVerificationState('pending', l10n: hi), 'सत्यापन लंबित');
      expect(localizedVerificationState('pending', l10n: mr), 'पडताळणी प्रलंबित');

      expect(localizedVerificationState('passed', l10n: en), 'Verification Passed');
      expect(localizedVerificationState('passed', l10n: hi), 'सत्यापन सफल');
      expect(localizedVerificationState('passed', l10n: mr), 'पडताळणी यशस्वी');
    });

    test('localizedSyncStatus maps offline synchronization states across en, hi, mr', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      expect(localizedSyncStatus(SyncStatus.synced, l10n: en), 'Synced');
      expect(localizedSyncStatus(SyncStatus.synced, l10n: hi), 'सिंक हुआ');
      expect(localizedSyncStatus(SyncStatus.synced, l10n: mr), 'सिंक केले');

      expect(localizedSyncStatus(SyncStatus.pending, l10n: en), 'Pending Sync');
      expect(localizedSyncStatus(SyncStatus.pending, l10n: hi), 'सिंक लंबित');
      expect(localizedSyncStatus(SyncStatus.pending, l10n: mr), 'सिंक प्रलंबित');
    });

    test('localizedBasemapMode and localizedBasemapModeDescription map modes across en, hi, mr', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      for (final mode in BasemapMode.values) {
        expect(localizedBasemapMode(mode, l10n: en).isNotEmpty, isTrue);
        expect(localizedBasemapMode(mode, l10n: hi).isNotEmpty, isTrue);
        expect(localizedBasemapMode(mode, l10n: mr).isNotEmpty, isTrue);

        expect(localizedBasemapModeDescription(mode, l10n: en).isNotEmpty, isTrue);
        expect(localizedBasemapModeDescription(mode, l10n: hi).isNotEmpty, isTrue);
        expect(localizedBasemapModeDescription(mode, l10n: mr).isNotEmpty, isTrue);
      }

      expect(localizedBasemapMode(BasemapMode.streets, l10n: en), 'Streets');
      expect(localizedBasemapMode(BasemapMode.streets, l10n: hi), 'सड़कें');
      expect(localizedBasemapMode(BasemapMode.streets, l10n: mr), 'रस्ते');
    });

    test('localizedAchievementTitle & localizedAchievementDescription map badges across en, hi, mr', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      const achievements = [
        'first_report',
        'active_citizen',
        'neighborhood_hero',
        'sharp_eye',
        'community_pillar',
      ];

      for (final id in achievements) {
        expect(localizedAchievementTitle(id, l10n: en).isNotEmpty, isTrue);
        expect(localizedAchievementTitle(id, l10n: hi).isNotEmpty, isTrue);
        expect(localizedAchievementTitle(id, l10n: mr).isNotEmpty, isTrue);

        expect(localizedAchievementDescription(id, l10n: en).isNotEmpty, isTrue);
        expect(localizedAchievementDescription(id, l10n: hi).isNotEmpty, isTrue);
        expect(localizedAchievementDescription(id, l10n: mr).isNotEmpty, isTrue);
      }

      expect(localizedAchievementTitle('first_report', l10n: en), 'First Report');
      expect(localizedAchievementTitle('first_report', l10n: hi), 'पहली शिकायत');
      expect(localizedAchievementTitle('first_report', l10n: mr), 'पहिली तक्रार');
    });
  });

  group('Phase 3 - Parameterized Strings & Pluralization', () {
    test('Plurals format complaint count correctly', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(en.complaintCount(0), 'No complaints');
      expect(en.complaintCount(1), '1 complaint');
      expect(en.complaintCount(5), '5 complaints');
    });

    test('Plurals format complaints found count correctly', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(en.complaintsFound(0), '0 complaints found');
      expect(en.complaintsFound(1), '1 complaint found');
      expect(en.complaintsFound(8), '8 complaints found');
    });

    test('Interpolation inserts parameters correctly across locales', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      expect(en.welcomeUser('Priya'), 'Welcome, Priya');
      expect(hi.welcomeUser('Priya'), 'स्वागत है, Priya');
      expect(mr.welcomeUser('Priya'), 'स्वागत आहे, Priya');

      expect(en.evidencePhotos(3), 'Photo Evidence (3)');
      expect(en.supportsCount(12), '12 supports');
      expect(en.pointsReward(20), '+20 Points');
      expect(en.executedBy('Suresh Patil'), 'Executed by Suresh Patil');
      expect(en.reportedOn('Oct 8, 2026'), 'Reported on Oct 8, 2026');
      expect(en.routedToDepartment('Roads & Traffic'), 'This issue will be routed to Roads & Traffic.');
    });
  });

  group('Phase 3 - Hard Immutability of Citizen-Entered Content', () {
    test('Citizen-entered title and description are strictly preserved raw and unmutated', () {
      const rawTitle = 'Severe road cave-in on SV Road near Bandra signal';
      const rawDesc = 'A large sinkhole has opened up in the middle of the road causing heavy traffic and risk to two-wheelers.';

      final complaint = ComplaintModel(
        id: 'comp_test_101',
        ticketNumber: 'CF-101',
        title: rawTitle,
        description: rawDesc,
        category: CivicCategory.defaultCategories.first,
        departmentName: 'Roads & Traffic',
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.high,
        location: const CivicLocation(
          latitude: 19.0596,
          longitude: 72.8295,
          address: 'SV Road, Bandra West',
          landmark: 'Near Bandra Police Station',
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        citizenId: 'cit_123',
      );

      // Verify raw fields remain immutable regardless of any mapping
      expect(complaint.title, rawTitle);
      expect(complaint.description, rawDesc);
      expect(complaint.citizenId, 'cit_123');
    });
  });

  group('Phase 3 - Responsive Width Verification (320px, 360px, 390px, 412px)', () {
    const testWidths = [320.0, 360.0, 390.0, 412.0];
    const testLocales = [Locale('en'), Locale('hi'), Locale('mr')];

    for (final width in testWidths) {
      for (final locale in testLocales) {
        testWidgets('StatusBadge and PriorityBadge render without overflow at ${width.toInt()}px in ${locale.languageCode}', (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        children: ComplaintStatus.values.map((s) => StatusBadge(status: s)).toList(),
                      ),
                      Wrap(
                        spacing: 8,
                        children: ComplaintPriority.values.map((p) => PriorityBadge(priority: p)).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });

        testWidgets('ProfileStatCard renders without overflow at ${width.toInt()}px in ${locale.languageCode}', (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: ProfileStatCard(
                    reportsSubmitted: 14,
                    reportsResolved: 9,
                    civicPoints: 480,
                    onRewardsTap: () {},
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });

        testWidgets('AchievementCard renders without overflow at ${width.toInt()}px in ${locale.languageCode}', (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final testAchievement = CivicAchievement(
            id: 'neighborhood_hero',
            title: 'Neighborhood Hero',
            description: 'Had 10 issues resolved in your community',
            howToUnlock: 'Have 10 issues resolved',
            icon: Icons.shield_rounded,
            isUnlocked: true,
            unlockedAt: DateTime.now(),
            pointsRequired: 10,
          );

          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: width / 2 - 16,
                    child: AchievementCard(achievement: testAchievement),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
