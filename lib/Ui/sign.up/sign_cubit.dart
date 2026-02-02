import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/Ui/domain/domain_authentication_repository/authentication_repository.dart';

part 'sign_state.dart';

class signCubit extends Cubit<signState> {
  final AuthenticationRepository authenticationRepository;

  signCubit({required this.authenticationRepository})
    : super(const signState(title: ''));

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
