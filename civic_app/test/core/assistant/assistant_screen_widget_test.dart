import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/assistant/config/civic_assistant_config.dart';
import 'package:civic_app/core/assistant/services/civic_assistant_feedback_service.dart';
import 'package:civic_app/core/assistant/services/civic_assistant_tts_service.dart';
import 'package:civic_app/core/repositories/user_repository.dart';
import 'package:civic_app/User UI/screens/assistant_screen.dart';
import 'package:civic_app/User UI/services/assistant_service.dart';
import 'package:civic_app/User UI/widgets/assistant/assistant_message_bubble.dart';

class TestFakeTtsEngine implements CivicTtsEngine {
  bool isSpeaking = false;
  void Function()? onStart;
  void Function()? onCompletion;
  void Function()? onCancel;
  dynamic Function(dynamic message)? onError;

  @override
  Future<dynamic> setLanguage(String language) async => 1;

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> setVolume(double volume) async => 1;

  @override
  Future<dynamic> setPitch(double pitch) async => 1;

  @override
  Future<dynamic> speak(String text) async {
    isSpeaking = true;
    onStart?.call();
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    isSpeaking = false;
    onCancel?.call();
    return 1;
  }

  @override
  Future<dynamic> pause() async {
    isSpeaking = false;
    return 1;
  }

  @override
  Future<dynamic> isLanguageAvailable(String language) async => true;

  @override
  void setStartHandler(VoidCallback callback) => onStart = callback;

  @override
  void setCompletionHandler(VoidCallback callback) => onCompletion = callback;

  @override
  void setCancelHandler(VoidCallback callback) => onCancel = callback;

  @override
  void setErrorHandler(dynamic Function(dynamic message) callback) => onError = callback;
}

void main() {
  setUp(() {
    CivicAssistantConfig.resetToDefault();
    CivicAssistantTtsService.instance = CivicAssistantTtsService(engine: TestFakeTtsEngine());
  });

  group('AssistantScreen Widget Tests', () {
    testWidgets('Renders welcome message and sends user query', (tester) async {
      final mockRepo = MockUserRepository();
      final assistantService = CivicAssistantService();

      await tester.pumpWidget(
        MaterialApp(
          home: AssistantScreen(
            userRepository: mockRepo,
            assistantService: assistantService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify welcome message is visible
      expect(find.textContaining('CivicFix Assistant'), findsWidgets);
      expect(find.byType(AssistantMessageBubble), findsAtLeastNWidgets(1));

      // Enter a casual greeting
      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);

      await tester.enterText(inputField, 'Hello');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify user message and assistant reply are rendered
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Hi! How can I help you today?'), findsOneWidget);
    });

    testWidgets('Tapping suggestion chip sends message and receives answer', (tester) async {
      final mockRepo = MockUserRepository();
      final assistantService = CivicAssistantService();

      await tester.pumpWidget(
        MaterialApp(
          home: AssistantScreen(
            userRepository: mockRepo,
            assistantService: assistantService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find top chip for "What is CivicFix?"
      final chipFinder = find.widgetWithText(ActionChip, 'What is CivicFix?');
      expect(chipFinder, findsWidgets);

      await tester.tap(chipFinder.first);
      await tester.pumpAndSettle();

      // Verify response explains CivicFix
      expect(find.textContaining('municipal grievance redressal platform'), findsWidgets);
    });

    testWidgets('Clear chat resets messages and halts active speech', (tester) async {
      final mockRepo = MockUserRepository();
      final assistantService = CivicAssistantService();

      await tester.pumpWidget(
        MaterialApp(
          home: AssistantScreen(
            userRepository: mockRepo,
            assistantService: assistantService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Send a query
      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'How do I report a pothole on my street?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('How do I report a pothole on my street?', skipOffstage: false), findsOneWidget);

      // Tap clear chat icon
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();

      // History should be reset, user message should no longer exist
      expect(find.text('How do I report a pothole on my street?', skipOffstage: false), findsNothing);
      expect(find.textContaining('CivicFix Assistant'), findsWidgets);
      expect(CivicAssistantTtsService.instance.isSpeaking, isFalse);
    });

    testWidgets('Tapping speaker button toggles between speaking and idle visual states', (tester) async {
      final mockRepo = MockUserRepository();
      final assistantService = CivicAssistantService();

      await tester.pumpWidget(
        MaterialApp(
          home: AssistantScreen(
            userRepository: mockRepo,
            assistantService: assistantService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find speaker icon on the welcome message
      final idleSpeakerFinder = find.byIcon(Icons.volume_up_outlined);
      expect(idleSpeakerFinder, findsAtLeastNWidgets(1));

      // Tap speaker button -> starts speaking -> icon changes to stop_circle_outlined
      await tester.tap(idleSpeakerFinder.first);
      await tester.pumpAndSettle();

      expect(CivicAssistantTtsService.instance.isSpeaking, isTrue);
      expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);

      // Tap same button -> stops speaking -> icon returns to volume_up_outlined
      final activeSpeakerFinder = find.byIcon(Icons.stop_circle_outlined);
      await tester.tap(activeSpeakerFinder);
      await tester.pumpAndSettle();

      expect(CivicAssistantTtsService.instance.isSpeaking, isFalse);
      expect(find.byIcon(Icons.stop_circle_outlined), findsNothing);
      expect(find.byIcon(Icons.volume_up_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('Sending a new query stops active speech and updates conversation', (tester) async {
      final mockRepo = MockUserRepository();
      final assistantService = CivicAssistantService();

      await tester.pumpWidget(
        MaterialApp(
          home: AssistantScreen(
            userRepository: mockRepo,
            assistantService: assistantService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start speaking welcome message
      final speakerFinder = find.byIcon(Icons.volume_up_outlined);
      expect(speakerFinder, findsAtLeastNWidgets(1));
      await tester.tap(speakerFinder.first);
      await tester.pumpAndSettle();

      expect(CivicAssistantTtsService.instance.isSpeaking, isTrue);

      // User submits a new message -> speech must stop automatically
      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'Where is the nearest ward office?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(CivicAssistantTtsService.instance.isSpeaking, isFalse);
      expect(find.textContaining(RegExp(r'ward', caseSensitive: false)), findsWidgets);
    });

    testWidgets('Tapping thumbs up updates UI state and submits feedback', (tester) async {
      final mockEngine = MockCivicAssistantFeedbackEngine();
      CivicAssistantFeedbackService.instance.setEngine(mockEngine);

      final mockRepo = MockUserRepository();
      final assistantService = CivicAssistantService();

      await tester.pumpWidget(
        MaterialApp(
          home: AssistantScreen(
            userRepository: mockRepo,
            assistantService: assistantService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find initial neutral thumbs up icon
      final thumbsUpOutline = find.byIcon(Icons.thumb_up_alt_outlined);
      expect(thumbsUpOutline, findsAtLeastNWidgets(1));

      // Tap thumbs up on welcome message
      await tester.tap(thumbsUpOutline.first);
      await tester.pumpAndSettle();

      // Icon should now be active solid
      expect(find.byIcon(Icons.thumb_up_alt_rounded), findsOneWidget);
      expect(mockEngine.saveCallCount, equals(1));
    });

    testWidgets('Tapping thumbs down switches vote state', (tester) async {
      final mockEngine = MockCivicAssistantFeedbackEngine();
      CivicAssistantFeedbackService.instance.setEngine(mockEngine);

      final mockRepo = MockUserRepository();
      final assistantService = CivicAssistantService();

      await tester.pumpWidget(
        MaterialApp(
          home: AssistantScreen(
            userRepository: mockRepo,
            assistantService: assistantService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap thumbs up first
      await tester.tap(find.byIcon(Icons.thumb_up_alt_outlined).first);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.thumb_up_alt_rounded), findsOneWidget);

      // Tap thumbs down
      await tester.tap(find.byIcon(Icons.thumb_down_alt_outlined).first);
      await tester.pumpAndSettle();

      // Thumbs down should be active solid, thumbs up back to outline
      expect(find.byIcon(Icons.thumb_down_alt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_alt_rounded), findsNothing);
      expect(mockEngine.saveCallCount, equals(2));
    });

    testWidgets('Tapping active thumbs up deselects and removes feedback', (tester) async {
      final mockEngine = MockCivicAssistantFeedbackEngine();
      CivicAssistantFeedbackService.instance.setEngine(mockEngine);

      final mockRepo = MockUserRepository();
      final assistantService = CivicAssistantService();

      await tester.pumpWidget(
        MaterialApp(
          home: AssistantScreen(
            userRepository: mockRepo,
            assistantService: assistantService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap thumbs up -> active
      await tester.tap(find.byIcon(Icons.thumb_up_alt_outlined).first);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.thumb_up_alt_rounded), findsOneWidget);

      // Tap active thumbs up again -> deselect
      await tester.tap(find.byIcon(Icons.thumb_up_alt_rounded).first);
      await tester.pumpAndSettle();

      // Both should be outlines
      expect(find.byIcon(Icons.thumb_up_alt_rounded), findsNothing);
      expect(find.byIcon(Icons.thumb_down_alt_rounded), findsNothing);
      expect(mockEngine.deleteCallCount, equals(1));
    });

    testWidgets('Rolls back UI state and displays SnackBar when persistence fails', (tester) async {
      final mockEngine = MockCivicAssistantFeedbackEngine()..shouldThrow = true;
      CivicAssistantFeedbackService.instance.setEngine(mockEngine);

      final mockRepo = MockUserRepository();
      final assistantService = CivicAssistantService();

      await tester.pumpWidget(
        MaterialApp(
          home: AssistantScreen(
            userRepository: mockRepo,
            assistantService: assistantService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap thumbs up
      await tester.tap(find.byIcon(Icons.thumb_up_alt_outlined).first);
      await tester.pumpAndSettle();

      // State should have rolled back to outline, and snackbar should be displayed
      expect(find.byIcon(Icons.thumb_up_alt_rounded), findsNothing);
      expect(find.text("Couldn't save feedback. Please try again."), findsOneWidget);
    });
  });
}
