import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../notifications/data/repositories/notification_repository.dart';

// Providers for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// State definition for Auth
class AuthState {
  final UserModel? userModel;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialised;

  AuthState({
    this.userModel,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialised = false,
  });

  AuthState copyWith({
    UserModel? userModel,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialised,
  }) {
    return AuthState(
      userModel: userModel ?? this.userModel,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isInitialised: isInitialised ?? this.isInitialised,
    );
  }

  bool get isAuthenticated => userModel != null;
}

// StateNotifier for authentication -> converted to Riverpod v3 Notifier
class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _authRepository;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _init();
    return AuthState();
  }

  void _init() {
    bool hasInitialized = false;

    // Absolute fallback timeout of 5.5 seconds
    Future.delayed(const Duration(milliseconds: 5500), () {
      if (!hasInitialized) {
        hasInitialized = true;
        state = AuthState(isInitialised: true);
      }
    });

    // Paced delay of 4 seconds to allow splash screen animations to render fully
    Future.delayed(const Duration(seconds: 4), () {
      if (hasInitialized) return;

      _authRepository.authStateChanges.listen((User? user) async {
        if (hasInitialized) return;

        if (user == null) {
          hasInitialized = true;
          state = AuthState(isInitialised: true);
        } else {
          try {
            // Profile fetch with 1.5 second timeout guard to prevent network stalls
            final profile = await _authRepository.getUserProfile(user.uid).timeout(
              const Duration(milliseconds: 1500),
              onTimeout: () => throw Exception('Profile fetch timed out'),
            );
            hasInitialized = true;
            state = AuthState(
              userModel: profile,
              isInitialised: true,
            );
            if (profile != null) {
              ref.read(notificationRepositoryProvider).updateFcmToken(profile.uid);
            }
          } catch (e) {
            hasInitialized = true;
            state = AuthState(
              errorMessage: 'Failed to load user profile: ${e.toString()}',
              isInitialised: true,
            );
          }
        }
      });
    });
  }

  // Sign in with email and password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final credential = await _authRepository.signIn(email, password);
      final profile = await _authRepository.getUserProfile(credential.user!.uid);
      if (profile == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User profile does not exist in FireStore.',
        );
        return false;
      }
      state = state.copyWith(userModel: profile, isLoading: false);
      ref.read(notificationRepositoryProvider).updateFcmToken(profile.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred during authentication.';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address format.';
      } else {
        message = e.message ?? message;
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // Register a new user
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final credential = await _authRepository.signUp(email, password);
      final uid = credential.user!.uid;

      // Build profile based on role
      final employerId = role == UserRole.employer ? 'employer_$uid' : null;
      final employeeId = role == UserRole.employee ? 'employee_$uid' : null;

      final userProfile = UserModel(
        uid: uid,
        email: email,
        fullName: fullName,
        role: role,
        employerId: employerId,
        employeeId: employeeId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      await _authRepository.saveUserProfile(userProfile);
      state = state.copyWith(userModel: userProfile, isLoading: false);
      ref.read(notificationRepositoryProvider).updateFcmToken(userProfile.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred during registration.';
      if (e.code == 'email-already-in-use') {
        message = 'The email address is already in use by another account.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak.';
      } else {
        message = e.message ?? message;
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // Sign out
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    final user = state.userModel;
    if (user != null) {
      await ref.read(notificationRepositoryProvider).removeFcmToken(user.uid);
    }
    await _authRepository.signOut();
    state = AuthState(isInitialised: true);
  }

  // Seed default test accounts
  Future<void> seedDevAccounts() async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Employee
      await _authRepository.seedMockUser(
        'employee@focus360.com',
        'password123',
        'Alex Mercer',
        UserRole.employee,
      );

      // 2. Employer
      await _authRepository.seedMockUser(
        'employer@focus360.com',
        'password123',
        'Sarah Connor',
        UserRole.employer,
      );

      // 3. Admin
      await _authRepository.seedMockUser(
        'admin@focus360.com',
        'password123',
        'Tony Stark',
        UserRole.admin,
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Seeding failed: $e');
    }
  }

  // Update current user's password
  Future<bool> changePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authRepository.updatePassword(newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to update password.';
      if (e.code == 'requires-recent-login') {
        message = 'This operation is sensitive and requires recent authentication. Please log out and log back in to change your password.';
      } else {
        message = e.message ?? message;
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

// Global provider for AuthNotifier
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
