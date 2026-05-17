import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart';

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
  factory BiometricException.fromLocalAuthException(PlatformException e) {
    switch (e.code) {
      case noHardware:
        return BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: e.message ?? '',
          userMessage: 'Perangkat tidak memiliki sensor biometrik.',
        );
      case notEnrolled:
        return BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: e.message ?? '',
          userMessage:
              'Belum ada sidik jari/wajah tersimpan. Daftarkan di Pengaturan.',
        );
      case lockedOut:
        return BiometricException(
          code: BiometricErrorCode.temporaryLockout,
          message: e.message ?? '',
          userMessage: 'Terlalu banyak percobaan. Terkunci sementara.',
        );
      case permanentlyLockedOut:
        return BiometricException(
          code: BiometricErrorCode.biometricLockout,
          message: e.message ?? '',
          userMessage:
              'Sensor terkunci permanen. Gunakan PIN/Password untuk membuka.',
        );
      // Di local_auth v3, user canceled sering kali tidak melempar error melainkan me-return false
      // Namun kita tetap sediakan penangkapannya untuk berjaga-jaga
      default:
        return BiometricException(
          code: BiometricErrorCode.unknown,
          message: e.message ?? '',
          userMessage: 'Terjadi kesalahan biometrik yang tidak diketahui.',
        );
    }
  }

  // --- Computed getters untuk Keputusan UI ---

  // Tampilkan tombol "Coba Lagi"?
  bool get isRetryable =>
      code == BiometricErrorCode.userCanceled ||
      code == BiometricErrorCode.systemCanceled ||
      code == BiometricErrorCode.unknown;

  // Arahkan ke Pengaturan?
  bool get requiresSettings => code == BiometricErrorCode.notEnrolled;

  // Lempar ke form Password/PIN manual?
  bool get requiresFallback =>
      code == BiometricErrorCode.noBiometricHardware ||
      code == BiometricErrorCode.biometricLockout;
}
