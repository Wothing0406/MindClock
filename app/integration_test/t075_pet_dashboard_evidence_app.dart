import 'package:flutter/material.dart';
import 'package:mindclock_app/data/debug/debug_fixture_community_repository.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/community/views/today_pet_card.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final DebugFixtureCommunityRepository repository =
      DebugFixtureCommunityRepository();
  await repository.createCommitmentGroup(
    name: 'Nhóm Ôn thi 12A',
    petName: 'Mầm Xanh',
  );
  runApp(_EvidenceApp(repository: repository));
}

class _EvidenceApp extends StatelessWidget {
  const _EvidenceApp({required this.repository});

  final DebugFixtureCommunityRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MindClockTheme.buildThemeData(),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Hôm nay',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text('Dậy đúng giờ, học thật, cùng chăm pet nhóm.'),
                const SizedBox(height: 20),
                TodayPetCard(repository: repository),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
