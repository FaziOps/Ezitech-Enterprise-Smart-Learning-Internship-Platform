import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/offline/offline_providers.dart';
import 'core/offline/outbox_item.dart';
import 'core/offline/outbox_queue.dart';
import 'features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import 'features/assignments/data/datasources/assignment_local_datasource.dart';
import 'features/assignments/presentation/providers/assignment_providers.dart';
import 'features/courses/data/datasources/course_local_datasource.dart';
import 'features/courses/presentation/providers/course_providers.dart';
import 'features/internship/data/datasources/internship_local_datasource.dart';
import 'features/internship/presentation/providers/internship_providers.dart';
import 'features/community/data/repositories/community_repository_impl.dart';
import 'features/live/data/repositories/live_repository_impl.dart';
import 'features/live/presentation/providers/live_providers.dart';
import 'features/notifications/data/datasources/fcm_service.dart';
import 'features/notifications/data/models/notification_model.dart';
import 'features/notifications/presentation/providers/notification_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local persistence (offline outbox, cached course/PDF/chat/session
  // content).
  await Hive.initFlutter();
  Hive.registerAdapter(OutboxItemAdapter());
  await OutboxQueue.registerAndOpen();
  await CourseLocalDataSource.openBoxes();
  await InternshipLocalDataSource.openBox();
  await AssignmentLocalDataSource.openBox();
  await LiveRepositoryImpl.openBox();
  await AiAssistantRepositoryImpl.openBox();
  await NotificationLocalDataSource.openBox();
  await CommunityRepositoryImpl.openBox();

  // Firebase is genuinely optional here: without google-services.json /
  // GoogleService-Info.plist (README API table #9), initializeApp()
  // throws. Catching it means the whole app still runs — the
  // Notification Center just shows seed data and FcmService.initialize()
  // no-ops internally (see its `_available` check) instead of crashing
  // the app at launch.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  final container = ProviderContainer();

  // Riverpod providers are lazy — reading each feature's repository
  // provider here (rather than waiting for its screen to open) registers
  // its outbox sync handler immediately, so a write queued before the
  // student ever visits that screen still syncs on the first
  // connectivity event instead of sitting unsynced until later.
  container.read(courseRepositoryProvider);
  container.read(internshipRepositoryProvider);
  container.read(assignmentRepositoryProvider);
  container.read(liveRepositoryProvider);
  container.read(syncWorkerProvider).start();

  if (firebaseReady) {
    await container.read(fcmServiceProvider).initialize();
  }
  container.read(notificationRepositoryProvider); // starts listening for incoming FCM messages

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EzitechApp(),
    ),
  );
}
