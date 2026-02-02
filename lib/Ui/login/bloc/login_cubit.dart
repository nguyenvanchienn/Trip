import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/Ui/domain/domain_authentication_repository/authentication_repository.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthenticationRepository authenticationRepository;

  LoginCubit({required this.authenticationRepository})
    : super(const LoginState(title: ''));

  Future<void> login(String email, String password) async {
    try {
      await authenticationRepository.loginInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // handle error
    }
  }
}
