import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/Ui/main/main_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tourn/Ui/domain/domain_data_sources/firebase_auth_sevice.dart';
import 'firebase_options.dart';
import 'package:tourn/Ui/domain/domain_authentication_repository/authentication_repository.dart';

// Post + Storage implementations
import 'package:tourn/data/post/firestore_post_repository.dart';
import 'package:tourn/domain/post_repository/post_repository.dart';
import 'package:tourn/data/storage/firebase_storage_service.dart';
import 'package:tourn/domain/storage/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Đảm bảo các binding của Flutter được khởi tạo
  await EasyLocalization.ensureInitialized(); // Khởi tạo EasyLocalization trước khi chạy ứng dụng

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Khởi tạo Firebase với các tùy chọn mặc định

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

class _AppState extends State<App> {
  late final AuthenticationRepositoryImpl
  authenticationRepositoryImpl; // Khai báo biến authenticationRepositoryImpl
  late final FirebaseAuthService
  firebaseAuthService; // Khai báo biến firebaseAuthService

  // PostRepository để cung cấp dữ liệu bài viết (Firestore)
  late final PostRepository postRepository;

  // StorageService để upload ảnh/video lên Firebase Storage
  late final StorageService storageService;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    firebaseAuthService = FirebaseAuthService();
    authenticationRepositoryImpl = AuthenticationRepositoryImpl(
      firebaseAuthService: firebaseAuthService,
    );

    // Khởi tạo PostRepository (Firestore implementation)
    // Đây là nơi bạn có thể swap thành mock hoặc implementation khác trong tương lai
    postRepository = FirestorePostRepository();

    // Khởi tạo StorageService (Firebase Storage)
    storageService = FirebaseStorageService();

    // Thêm dữ liệu mẫu nếu collection rỗng (tiện phát triển)
    postRepository.seedSamplePostsIfEmpty();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthenticationRepositoryImpl>(
          create: (context) => authenticationRepositoryImpl,
        ),
        // Đăng ký PostRepository để có thể lấy trong UI: context.read<PostRepository>()
        RepositoryProvider<PostRepository>(create: (context) => postRepository),
        // Đăng ký StorageService để upload media: context.read<StorageService>()
        RepositoryProvider<StorageService>(create: (context) => storageService),
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
      home: Mainpage(), // Trang chính của ứng dụng
    );
  }
}
