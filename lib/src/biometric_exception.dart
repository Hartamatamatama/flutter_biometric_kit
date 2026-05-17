enum BiometricErrorCode {
  noBiometricHardware,
  notEnrolled,
  temporaryLockout,
  biometricLockout,
  userCanceled,
  systemCanceled,
  unknown,
}

class BiometricException implements Exception {
  final BiometricErrorCode code;
  final String message;
  final String userMessage;

  BiometricException({
    required this.code,
    required this.message,
    required this.userMessage,
  });

  factory BiometricException.fromLocalAuthException(dynamic e) {
    // Membaca kode error sebagai string untuk kebal terhadap perubahan struktur SDK
    final String errorCode = e.code.toString();

    if (errorCode.contains('noBiometricHardware') ||
        errorCode.contains('noHardware')) {
      return BiometricException(
        code: BiometricErrorCode.noBiometricHardware,
        message: e.toString(),
        userMessage: 'Perangkat tidak memiliki sensor biometrik.',
      );
    } else if (errorCode.contains('notEnrolled') ||
        errorCode.contains('noBiometricsEnrolled')) {
      return BiometricException(
        code: BiometricErrorCode.notEnrolled,
        message: e.toString(),
        userMessage:
            'Belum ada sidik jari/wajah tersimpan. Daftarkan di Pengaturan.',
      );
    } else if (errorCode.contains('lockedOut')) {
      return BiometricException(
        code: BiometricErrorCode.temporaryLockout,
        message: e.toString(),
        userMessage: 'Terlalu banyak percobaan. Terkunci sementara.',
      );
    } else if (errorCode.contains('permanentlyLockedOut')) {
      return BiometricException(
        code: BiometricErrorCode.biometricLockout,
        message: e.toString(),
        userMessage:
            'Sensor terkunci permanen. Gunakan PIN/Password untuk membuka.',
      );
    } else {
      return BiometricException(
        code: BiometricErrorCode.unknown,
        message: e.toString(),
        userMessage: 'Terjadi kesalahan biometrik yang tidak diketahui.',
      );
    }
  }

  bool get isRetryable =>
      code == BiometricErrorCode.userCanceled ||
      code == BiometricErrorCode.systemCanceled ||
      code == BiometricErrorCode.unknown;

  bool get requiresSettings => code == BiometricErrorCode.notEnrolled;

  bool get requiresFallback =>
      code == BiometricErrorCode.noBiometricHardware ||
      code == BiometricErrorCode.biometricLockout;
}
