import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourn/Ui/domain/domain_data_sources/firebase_auth_sevice.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Profile.dart';
import 'package:tourn/Ui/splash/splash.dart';
import 'firebase_options.dart';
import 'package:tourn/Ui/domain/domain_authentication_repository/authentication_repository.dart';

// dịch vụ ảnh và bài viết
import 'package:tourn/data/post/firestore_post_repository.dart';
import 'package:tourn/domain/post_repository/post_repository.dart';
import 'package:tourn/data/storage/firebase_storage_service.dart';
import 'package:tourn/domain/storage/storage_service.dart';

// nhắn tin và người dùng
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/domain/message_repository/message_repository.dart';
// thông báo và badge
import 'package:tourn/domain/notification_repository/notification_repository.dart';
// trang bài viết chi tiết
import 'package:tourn/Ui/main/category/favorites/pages/baiviet.dart';
// trang chat - hiện tại chỉ có giao diện, chưa kết nối backend, sẽ được cập nhật sau khi hoàn thiện chức năng nhắn tin
// ChatPage được import từ ChatPage.dart để tránh lỗi vòng lặp khi cả hai file đều cần import nhau
import 'package:tourn/Ui/main/category/messenge/pages/ChatPage.dart' as mail;
import 'package:tourn/Ui/main/category/menu/pages/Menu_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Đảm bảo các binding của Flutter được khởi tạo
  await EasyLocalization.ensureInitialized(); // Khởi tạo EasyLocalization trước khi chạy ứng dụng

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Khởi tạo Firebase với các tùy chọn mặc định
  
  // Xóa bộ đệm bị lỗi của Firestore trên trình duyệt (giải quyết lỗi WatchChangeAggregator)
  try {
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
    await FirebaseFirestore.instance.clearPersistence();
    print('✅ Đã xóa cache và vô hiệu hóa persistence Firestore thành công');
  } catch (e) {
    print('⚠️ Không thể thiết lập Firestore settings/cache: $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('en'), // Hỗ trợ ngôn ngữ tiếng Anh
        Locale('vi'), // Hỗ trợ ngôn ngữ tiếng Việt
        Locale('zh'), // Hỗ trợ ngôn ngữ tiếng Trung
        Locale('ko'), // Hỗ trợ ngôn ngữ tiếng Hàn
        Locale('ja'), // Hỗ trợ ngôn ngữ tiếng Nhật
      ],
      path: "asset/language", // Đường dẫn đến thư mục chứa file ngôn ngữ
      child: const App(),
    ),
  );
}

class App extends StatefulWidget {
  // chức năng của đăng nhập/ đăng ký
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late final AuthenticationRepositoryImpl
  authenticationRepositoryImpl; // Khai báo biến authenticationRepositoryImpl
  late final FirebaseAuthService
  firebaseAuthService; // Khai báo biến firebaseAuthService

  // PostRepository để cung cấp dữ liệu bài viết (Firestore)
  late final PostRepository postRepository;

  // StorageService để upload ảnh/video lên Firebase Storage
  late final StorageService storageService;

  // UserRepository để quản lý thông tin người dùng (Firestore)
  late final UserRepository userRepository;

  // MessageRepository để quản lý tin nhắn và hội thoại (Firestore)
  late final MessageRepository messageRepository;

  // Timer to periodically update lastSeen while app is active
  Timer? _onlineStatusTimer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    firebaseAuthService = FirebaseAuthService();
    authenticationRepositoryImpl = AuthenticationRepositoryImpl(
      firebaseAuthService: firebaseAuthService,
    );

    // Khởi tạo PostRepository (Firestore implementation)
    // Đây là nơi bạn có thể swap thành mock hoặc implementation khác trong tương lai
    postRepository = FirestorePostRepository();

    // Khởi tạo StorageService (Firebase Storage)
    storageService = FirebaseStorageService();

    // Khởi tạo UserRepository (Firestore)
    userRepository = FirestoreUserRepository();

    // Khởi tạo MessageRepository (Firestore)
    messageRepository = FirestoreMessageRepository();

    // NOTE: seedSamplePostsIfEmpty() removed - it was causing app to hang
    // because Firestore rules require authentication, but this runs before login.
    // If needed, call it after user logs in.

    // NOTE: Online status timer will be started after user logs in
    // instead of here to avoid Firestore permission errors
  }

  void _startOnlineStatusTimer() {
    _onlineStatusTimer?.cancel();
    // Update online status every 30 seconds while app is active
    // Only run if user is logged in
    _onlineStatusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Check if user is logged in before updating status
      if (firebaseAuthService.getCurrentUser() != null) {
        userRepository.setOnlineStatus(true);
      }
    });
  }

  void _stopOnlineStatusTimer() {
    _onlineStatusTimer?.cancel();
    _onlineStatusTimer = null;
  }

  @override
  void dispose() {
    _stopOnlineStatusTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Only update online status if user is logged in
    if (firebaseAuthService.getCurrentUser() == null) return;

    // Update online status based on app lifecycle
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground - set user as online and start timer
        userRepository.setOnlineStatus(true);
        _startOnlineStatusTimer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is in background or closed - set user as offline and stop timer
        _stopOnlineStatusTimer();
        userRepository.setOnlineStatus(false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthenticationRepository>(
          create: (context) => authenticationRepositoryImpl,
        ),
        // Đăng ký PostRepository để có thể lấy trong UI: context.read<PostRepository>()
        RepositoryProvider<PostRepository>(create: (context) => postRepository),
        // Đăng ký StorageService để upload media: context.read<StorageService>()
        RepositoryProvider<StorageService>(create: (context) => storageService),
        // Đăng ký UserRepository để quản lý user: context.read<UserRepository>()
        RepositoryProvider<UserRepository>(create: (context) => userRepository),
        // Đăng ký MessageRepository để quản lý messages: context.read<MessageRepository>()
        RepositoryProvider<MessageRepository>(
          create: (context) => messageRepository,
        ),
        // notification repository - used by Thông báo page and badge
        RepositoryProvider<NotificationRepository>(
          create: (context) => FirestoreNotificationRepository(),
        ),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nguyễn Chiến',
      theme: ThemeData(
        // Định nghĩa chủ đề cho ứng dụng
        scaffoldBackgroundColor: const Color(0xFFF5F5F3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ), // Màu chủ đề được tạo từ màu hạt giống
        useMaterial3: true, // Sử dụng Material Design 3
      ),
      // ngôn ngữ hỗ trợ
      localizationsDelegates: context
          .localizationDelegates, // Thiết lập các delegate cho localization
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      home: SplashScreen(), // Trang chính của ứng dụng
      routes: {
        '/baiviet': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return Baiviet(
              post: args['post'] as Map<String, dynamic>?,
              postId: args['postId'] as String?,
            );
          }
          return const Baiviet();
        },
        '/profile': (context) => const Profile(),
        '/chatPage': (context) =>
            const mail.ChatPage(), // ChatPage imported from ChatPage.dart
        '/menudrawer': (context) => const MenuDrawer(),
      },
    );
  }
}
