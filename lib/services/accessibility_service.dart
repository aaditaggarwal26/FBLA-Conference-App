import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage accessibility preferences for the app
class AccessibilityService extends ChangeNotifier {
  static const String _textScaleKey = 'accessibility_text_scale';
  static const String _reduceMotionKey = 'accessibility_reduce_motion';
  static const String _highContrastKey = 'accessibility_high_contrast';
  static const String _boldTextKey = 'accessibility_bold_text';

  // Text scale options: 0.85, 1.0 (default), 1.15, 1.3, 1.5
  double _textScaleFactor = 1.0;
  bool _reduceMotion = false;
  bool _highContrast = false;
  bool _boldText = false;

  double get textScaleFactor => _textScaleFactor;
  bool get reduceMotion => _reduceMotion;
  bool get highContrast => _highContrast;
  bool get boldText => _boldText;

  AccessibilityService() {
    _loadPreferences();
  }

  /// Load all accessibility preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _textScaleFactor = prefs.getDouble(_textScaleKey) ?? 1.0;
    _reduceMotion = prefs.getBool(_reduceMotionKey) ?? false;
    _highContrast = prefs.getBool(_highContrastKey) ?? false;
    _boldText = prefs.getBool(_boldTextKey) ?? false;
    notifyListeners();
  }

  /// Set text scale factor
  Future<void> setTextScaleFactor(double scale) async {
    _textScaleFactor = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, scale);
    notifyListeners();
  }

  /// Toggle reduce motion setting
  Future<void> toggleReduceMotion() async {
    _reduceMotion = !_reduceMotion;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceMotionKey, _reduceMotion);
    notifyListeners();
  }

  /// Toggle high contrast setting
  Future<void> toggleHighContrast() async {
    _highContrast = !_highContrast;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, _highContrast);
    notifyListeners();
  }

  /// Toggle bold text setting
  Future<void> toggleBoldText() async {
    _boldText = !_boldText;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_boldTextKey, _boldText);
    notifyListeners();
  }

  /// Get animation duration based on reduce motion setting
  Duration getAnimationDuration(Duration normalDuration) {
    return _reduceMotion ? Duration.zero : normalDuration;
  }

  /// Get curve for animations based on reduce motion setting
  Curve getAnimationCurve() {
    return _reduceMotion ? Curves.linear : Curves.easeInOut;
  }

  /// Reset all accessibility settings to default
  Future<void> resetToDefaults() async {
    _textScaleFactor = 1.0;
    _reduceMotion = false;
    _highContrast = false;
    _boldText = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, 1.0);
    await prefs.setBool(_reduceMotionKey, false);
    await prefs.setBool(_highContrastKey, false);
    await prefs.setBool(_boldTextKey, false);
    
    notifyListeners();
  }

  /// Get text scale label for UI display
  String getTextScaleLabel() {
    if (_textScaleFactor <= 0.85) return 'Small';
    if (_textScaleFactor <= 1.0) return 'Default';
    if (_textScaleFactor <= 1.15) return 'Large';
    if (_textScaleFactor <= 1.3) return 'Extra Large';
    return 'Largest';
  }
}
