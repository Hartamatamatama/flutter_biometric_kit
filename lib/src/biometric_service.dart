import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'biometric_exception.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  // 1. Cek Ketersediaan Hardware
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }

  // 2. Ambil Daftar Biometrik yang Aktif
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // 3. Eksekusi Autentikasi Utama
  Future<bool> authenticate({
    String reason = 'Verifikasi dibutuhkan untuk membuka aplikasi',
  }) async {
    try {
      // Pre-check 1: Ketersediaan Sensor
      final bool available = await isBiometricAvailable();
      if (!available) {
        throw BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: 'Hardware not available or unsupported',
          userMessage:
              'Perangkat tidak memiliki atau tidak mendukung sensor biometrik.',
        );
      }

      // Pre-check 2: Pendaftaran Sidik Jari/Wajah
      final List<BiometricType> types = await getAvailableBiometrics();
      if (types.isEmpty) {
        throw BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: 'No biometrics enrolled',
          userMessage:
              'Belum ada sidik jari/wajah yang terdaftar di perangkat ini.',
        );
      }

      // Memanggil Dialog Sensor Bawaan OS
      final bool result = await _auth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Verifikasi Keamanan',
            cancelButton: 'Batal',
            signInHint: 'Tempelkan jari atau arahkan wajah',
          ),
        ],
        options: const AuthenticationOptions(
          biometricOnly:
              false, // Mengizinkan fallback ke PIN/Pola HP jika biometrik gagal
          sensitiveTransaction:
              true, // Keamanan ketat: Menolak Face Unlock 2D (Class 2) yang mudah diretas
          useErrorDialogs: true,
          stickyAuth:
              true, // Dialog tidak hilang jika ada panggilan masuk/notifikasi
        ),
      );

      // Jika pengguna menekan tombol "Batal"
      if (!result) {
        throw BiometricException(
          code: BiometricErrorCode.userCanceled,
          message: 'Authentication canceled by user',
          userMessage: 'Autentikasi dibatalkan.',
        );
      }

      return true;
    } on PlatformException catch (e) {
      // Menerjemahkan error mentah dari OS menjadi pesan elegan
      throw BiometricException.fromLocalAuthException(e);
    }
  }
}
