import 'package:flutter/services.dart';
import 'package:shamsi_date/shamsi_date.dart';

class Formatters {
  /// Converts Gregorian DateTime to Shamsi String (e.g. "۱۴۰۵/۰۴/۱۸")
  static String toPersianDate(DateTime dt) {
    final jalali = Jalali.fromDateTime(dt);
    final f = jalali.formatter;
    return toPersianNumbers('${f.yyyy}/${f.mm}/${f.dd}');
  }

  /// Converts a string containing English digits to Persian digits
  static String toPersianNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  /// Replaces Persian digits with English digits and removes non-numeric characters (like commas)
  static String cleanNumber(String text) {
    var result = text;
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (var i = 0; i < persian.length; i++) {
      result = result.replaceAll(persian[i], english[i]);
    }
    return result.replaceAll(RegExp(r'\D'), '');
  }

  /// Formats price amount with thousands separator and Persian numbers (e.g. "۵,۳۰۰,۰۰۰")
  static String formatPrice(dynamic price) {
    if (price == null) return '';
    final String priceStr;
    if (price is num) {
      priceStr = price.toStringAsFixed(0);
    } else {
      priceStr = cleanNumber(price.toString());
    }

    if (priceStr.isEmpty) return '';

    // Add thousands separator (comma)
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = priceStr.replaceAllMapped(regExp, (Match m) => '${m[1]},');
    return toPersianNumbers(formatted);
  }
}

class PersianPriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final cleanText = Formatters.cleanNumber(newValue.text);
    if (cleanText.isEmpty) {
      return const TextEditingValue();
    }

    final double? val = double.tryParse(cleanText);
    if (val == null) {
      return oldValue;
    }

    final formatted = Formatters.formatPrice(cleanText);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
