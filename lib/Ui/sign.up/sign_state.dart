part of 'sign_cubit.dart';

class signState extends Equatable {
  final String title;

  const signState({required this.title});

  @override
  List<Object> get props => [title];
}
