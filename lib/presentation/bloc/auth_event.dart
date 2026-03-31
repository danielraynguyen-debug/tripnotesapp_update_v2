import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;
  const SendOtpEvent(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class VerifyOtpEvent extends AuthEvent {
  final String verificationId;
  final String smsCode;
  const VerifyOtpEvent(this.verificationId, this.smsCode);

  @override
  List<Object?> get props => [verificationId, smsCode];
}

class UpdateUserInfoEvent extends AuthEvent {
  final String name;
  final String email;

  const UpdateUserInfoEvent({required this.name, required this.email});

  @override
  List<Object?> get props => [name, email];
}

class InternalOtpSent extends AuthEvent {
  final String verificationId;
  const InternalOtpSent(this.verificationId);

  @override
  List<Object?> get props => [verificationId];
}

class InternalError extends AuthEvent {
  final String message;
  const InternalError(this.message);

  @override
  List<Object?> get props => [message];
}

class LogoutEvent extends AuthEvent {}
