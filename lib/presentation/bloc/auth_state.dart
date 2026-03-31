import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class OtpSentState extends AuthState {
  final String verificationId;
  const OtpSentState(this.verificationId);

  @override
  List<Object?> get props => [verificationId];
}

class AuthenticatedState extends AuthState {}

class NewUserRequiredState extends AuthState {}

class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class UnauthenticatedState extends AuthState {}
