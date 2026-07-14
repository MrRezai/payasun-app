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

  /// Formats phone number into +98 9XX XXX XXXX with Persian digits
  static String formatPhoneNumber(String phone) {
    var cleaned = phone.trim().replaceAll(' ', '');
    if (cleaned.startsWith('0')) {
      cleaned = '+98${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }

    if (cleaned.length == 13) {
      cleaned = '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9)}';
    }
    return toPersianNumbers(cleaned);
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
class PersianDigitsFormatter extends TextInputFormatter {
  final bool stripLeadingZero;

  PersianDigitsFormatter({this.stripLeadingZero = false});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    
    // 1. Convert English/Arabic digits to Persian digits
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    for (var i = 0; i < 10; i++) {
      text = text.replaceAll(english[i], persian[i]);
      text = text.replaceAll(arabic[i], persian[i]);
    }
    
    // 2. Keep only Persian digits (Unicode range \u06f0 to \u06f9)
    text = text.replaceAll(RegExp(r'[^\u06f0-\u06f9]'), '');
    
    // 3. Strip leading zeroes
    if (stripLeadingZero) {
      while (text.startsWith('۰')) {
        text = text.substring(1);
      }
    }
    
    // 4. Calculate selection index
    int selectionIndex = text.length;
    
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
