import 'package:go_router/go_router.dart';
import 'package:life_os/features/gym/screens/gym_screen.dart';
import 'package:life_os/features/reading/screens/reading_screen.dart';
import 'package:life_os/features/body/screens/body_screen.dart';
import 'package:life_os/features/schedule/screens/schedule_screen.dart';
import 'package:life_os/features/cardio/screens/cardio_screen.dart';
import 'package:life_os/features/checklist/screens/checklist_screen.dart';
import 'package:life_os/shared/widgets/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/checklist',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/gym', builder: (_, _) => const GymScreen()),
        GoRoute(path: '/reading', builder: (_, _) => const ReadingScreen()),
        GoRoute(path: '/body', builder: (_, _) => const BodyScreen()),
        GoRoute(path: '/schedule', builder: (_, _) => const ScheduleScreen()),
        GoRoute(path: '/cardio', builder: (_, _) => const CardioScreen()),
        GoRoute(path: '/checklist', builder: (_, _) => const ChecklistScreen()),
      ],
    ),
  ],
);
