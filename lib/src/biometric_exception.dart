import 'package:local_auth/local_auth.dart';

// Enum internal untuk mengelompokkan jenis error
enum BiometricErrorCode {
  noBiometricHardware,
  notEnrolled,
  temporaryLockout,
  biometricLockout,
  userCanceled,
  systemCanceled,
  unknown,
}

// Custom Exception Class
class BiometricException implements Exception {
  final BiometricErrorCode code;
  final String message;
  final String userMessage;

  BiometricException({
    required this.code,
    required this.message,
    required this.userMessage,
  });

  // Pabrik konversi: Error OS -> Custom Model
  factory BiometricException.fromLocalAuthException(LocalAuthException e) {
    switch (e.code) {
      case LocalAuthExceptionCode.noBiometricHardware:
        return BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: e.message ?? '',
          userMessage: 'Perangkat tidak memiliki sensor biometrik.',
        );
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: e.message ?? '',
          userMessage:
              'Belum ada sidik jari/wajah tersimpan. Daftarkan di Pengaturan.',
        );
      case LocalAuthExceptionCode.lockedOut:
        return BiometricException(
          code: BiometricErrorCode.temporaryLockout,
          message: e.message ?? '',
          userMessage: 'Terlalu banyak percobaan. Terkunci sementara.',
        );
      case LocalAuthExceptionCode.permanentlyLockedOut:
        return BiometricException(
          code: BiometricErrorCode.biometricLockout,
          message: e.message ?? '',
          userMessage:
              'Sensor terkunci permanen. Gunakan PIN/Password untuk membuka.',
        );
      default:
        return BiometricException(
          code: BiometricErrorCode.unknown,
          message: e.message ?? '',
          userMessage: 'Terjadi kesalahan biometrik yang tidak diketahui.',
        );
    }
  }

  // --- Computed getters untuk Keputusan UI ---

  bool get isRetryable =>
      code == BiometricErrorCode.userCanceled ||
      code == BiometricErrorCode.systemCanceled ||
      code == BiometricErrorCode.unknown;

  bool get requiresSettings => code == BiometricErrorCode.notEnrolled;

  bool get requiresFallback =>
      code == BiometricErrorCode.noBiometricHardware ||
      code == BiometricErrorCode.biometricLockout;
}
