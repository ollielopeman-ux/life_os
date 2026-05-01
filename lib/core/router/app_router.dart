import 'package:go_router/go_router.dart';
import 'package:life_os/features/gym/screens/gym_screen.dart';
import 'package:life_os/features/reading/screens/reading_screen.dart';
import 'package:life_os/features/body/screens/body_screen.dart';
import 'package:life_os/features/schedule/screens/schedule_screen.dart';
import 'package:life_os/features/cardio/screens/cardio_screen.dart';
import 'package:life_os/features/checklist/screens/checklist_screen.dart';
import 'package:life_os/shared/widgets/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/gym',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/gym', pageBuilder: (_, __) => const NoTransitionPage(child: GymScreen())),
        GoRoute(path: '/reading', pageBuilder: (_, __) => const NoTransitionPage(child: ReadingScreen())),
        GoRoute(path: '/body', pageBuilder: (_, __) => const NoTransitionPage(child: BodyScreen())),
        GoRoute(path: '/schedule', pageBuilder: (_, __) => const NoTransitionPage(child: ScheduleScreen())),
        GoRoute(path: '/cardio', pageBuilder: (_, __) => const NoTransitionPage(child: CardioScreen())),
        GoRoute(path: '/checklist', pageBuilder: (_, __) => const NoTransitionPage(child: ChecklistScreen())),
      ],
    ),
  ],
);
