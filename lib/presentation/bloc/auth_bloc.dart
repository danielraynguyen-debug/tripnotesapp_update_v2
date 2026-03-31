import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<SendOtpEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        await _authRepository.verifyPhone(
          phoneNumber: event.phoneNumber,
          onCodeSent: (verificationId) {
            add(InternalOtpSent(verificationId));
          },
          onFailed: (e) {
            add(InternalError(e.message ?? "Xác thực thất bại"));
          },
        );
      } catch (e) {
        emit(AuthErrorState(e.toString()));
      }
    });

    on<InternalOtpSent>((event, emit) {
      emit(OtpSentState(event.verificationId));
    });

    on<InternalError>((event, emit) {
      emit(AuthErrorState(event.message));
    });

    on<VerifyOtpEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final userCredential = await _authRepository.verifyOTP(
          event.verificationId,
          event.smsCode,
        );
        
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          emit(NewUserRequiredState());
        } else {
          emit(AuthenticatedState());
        }
      } catch (e) {
        emit(AuthErrorState(e.toString()));
      }
    });

    on<UpdateUserInfoEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = _authRepository.currentUser;
        if (user != null) {
          // 1. Cập nhật Profile cơ bản trong Firebase Auth (tùy chọn)
          await user.updateDisplayName(event.name);
          // Lưu ý: updateEmail yêu cầu re-authentication hoặc xác thực mới, 
          // nên thường chúng ta chỉ lưu email vào Firestore cho Phone Auth.

          // 2. Tạo đối tượng User Model
          final userModel = UserModel(
            uid: user.uid,
            displayName: event.name,
            email: event.email,
            phoneNumber: user.phoneNumber,
            createdAt: DateTime.now(),
          );

          // 3. Gọi Repository để lưu vào Cloud Firestore
          await _authRepository.saveUserToFirestore(userModel);

          // 4. Hoàn tất xác thực
          emit(AuthenticatedState());
        } else {
          emit(const AuthErrorState("Không tìm thấy thông tin người dùng."));
        }
      } catch (e) {
        emit(AuthErrorState("Không thể lưu thông tin: ${e.toString()}"));
      }
    });

    on<LogoutEvent>((event, emit) async {
      await _authRepository.signOut();
      emit(UnauthenticatedState());
    });
  }
}
