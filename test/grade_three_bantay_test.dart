import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/features/lesson_game/screens/flows/grade_3/grade_three_bantay_flow.dart';

const saveKey = 'bantay.g3.u2.l2.1.guest';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => 1,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global/events'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        final arguments = call.arguments;
        if (arguments is Map && arguments['playerId'] != null) {
          messenger.setMockMethodCallHandler(
            MethodChannel(
              'xyz.luan/audioplayers/events/${arguments['playerId']}',
            ),
            (_) async => null,
          );
        }
        return 1;
      },
    );
    AppAudioService.instance.voiceOverEnabledNotifier.value = false;
    AppAudioService.instance.soundEffectsEnabledNotifier.value = false;
    AppAudioService.instance.musicEnabledNotifier.value = false;
  });

  Future<void> mount(
    WidgetTester tester,
    Map<String, dynamic> save, {
    Size size = const Size(960, 540),
  }) async {
    SharedPreferences.setMockInitialValues({saveKey: jsonEncode(save)});
    tester.view.reset();
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      AppStateScope(
        notifier: AppState(),
        child: MaterialApp(
          home: Scaffold(
            body: GradeThreeBantayFlow(
              onExit: () {},
              onLessonComplete: () {},
              onBackToMap: () {},
              onContinue: () {},
              rewardStickerAsset:
                  'assets/images/stickers/rewards/home/dog-home-sticker.svg',
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pump();
  }

  Future<Map<String, dynamic>> saved(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    return jsonDecode(
          (await SharedPreferences.getInstance()).getString(saveKey)!,
        )
        as Map<String, dynamic>;
  }

  testWidgets(
    'classroom searches count stable IDs once and unlock Market only at 3/3',
    (tester) async {
      await mount(tester, {'currentStage': 'classroom'});
      expect(find.text('SUNOD'), findsNothing);
      await tester.tap(find.text('Lamesa'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('Lamesa'));
      await tester.pump(const Duration(milliseconds: 600));
      expect((await saved(tester))['classroomSearchCount'], 1);
      for (final label in ['Bag', 'Pultahan']) {
        await tester.tap(find.text(label));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump(const Duration(milliseconds: 600));
      }
      final data = await saved(tester);
      expect(data['classroomSearchCount'], 3);
      expect(data['unlockedLocationIds'], contains('Market'));
      expect(find.text('SUNOD'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'sequence retry returns only misplaced cards and preserves the investigation',
    (tester) async {
      await mount(tester, {
        'currentStage': 'sequence',
        'searchedHotspotIds': [
          'classroom_desk',
          'classroom_bag',
          'classroom_door',
        ],
        'farmClueCollected': true,
        'footprintIndex': 3,
        'bantayFound': true,
        'sequenceOrder': ['missing', 'found', 'clue'],
        'trayOrder': ['found', 'missing', 'clue'],
      });
      expect(
        find.text('SUNOD'),
        findsOneWidget,
      ); // Slot label, not a Continue button.
      await tester.tap(find.text('USISAON'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      final data = await saved(tester);
      expect(data['sequenceOrder'], ['missing', null, null]);
      expect(data['footprintIndex'], 3);
      expect(data['farmClueCollected'], true);
      expect(data['searchedHotspotIds'], hasLength(3));
      expect(data['sequenceCompleted'], false);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'resume after footprint three reveals Bantay without restarting the trail on a tall phone',
    (tester) async {
      await mount(tester, {
        'currentStage': 'farm',
        'footprintIndex': 3,
        'farmClueCollected': true,
      }, size: const Size(390, 844));
      expect(find.text('Salamat! Nakita naton si Bantay!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final data = await saved(tester);
      expect(data['currentStage'], 'found');
      expect(data['bantayFound'], true);
      expect(data['completedFootprintIds'], hasLength(3));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
