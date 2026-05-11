class AppDateFormatters {
  const AppDateFormatters._();

  static const _months = [
    "Ocak",
    "Şubat",
    "Mart",
    "Nisan",
    "Mayıs",
    "Haziran",
    "Temmuz",
    "Ağustos",
    "Eylül",
    "Ekim",
    "Kasım",
    "Aralık",
  ];

  static String formatDate(String value) {
    final date = _parse(value);
    if (date == null) {
      return "Tarih bilgisi yok";
    }

    return "${date.day} ${_months[date.month - 1]} ${date.year}";
  }

  static String formatResetDate(String value) {
    final date = _parse(value);
    if (date == null) {
      return "Sıfırlanma tarihi henüz belli değil";
    }

    return "${date.day} ${_months[date.month - 1]} ${date.year} tarihinde sıfırlanır";
  }

  static String formatDateTime(String value) {
    final date = _parse(value);
    if (date == null) {
      return "Tarih bilgisi yok";
    }

    final hour = date.hour.toString().padLeft(2, "0");
    final minute = date.minute.toString().padLeft(2, "0");
    return "${date.day} ${_months[date.month - 1]} ${date.year}, $hour:$minute";
  }

  static DateTime? _parse(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value)?.toLocal();
  }
}
