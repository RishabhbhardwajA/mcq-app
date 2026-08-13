import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:safe_device/safe_device.dart';

class SecurityManager {
  static const platform = MethodChannel('exam_security');
  
  /// Initializes security features based on the context.
  /// Typically called before the exam starts.
  static Future<void> enableExamSecurity() async {
    await _disableScreenshots();
    await _checkDeviceIntegrity();
  }

  /// Disables exam security features (e.g., when the exam is finished).
  static Future<void> disableExamSecurity() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await platform.invokeMethod('disableSecurity');
      } catch (e) {
        // Handle error
      }
    }
  }

  /// Blocks screenshots and screen recording.
  static Future<void> _disableScreenshots() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await platform.invokeMethod('enableSecurity');
      } catch (e) {
        // Handle error
      }
    }
    // Note: On iOS, preventing screenshots natively is restricted by Apple.
    // Usually, we just listen to screenshot events and warn the user.
  }

  /// Checks if the device is rooted (Android) or jailbroken (iOS).
  /// Throws an exception if the device is compromised.
  static Future<void> _checkDeviceIntegrity() async {
    bool isRooted = false;
    
    try {
      isRooted = await SafeDevice.isJailBroken;
    } catch (e) {
      // Handle plugin exception
    }
    
    if (isRooted) {
      // Force exit or throw exception
      throw Exception('Device is rooted/jailbroken. Exam cannot be started on compromised devices.');
    }
  }
}
