class DateTimeUtils {
  const DateTimeUtils._();

  static DateTime utcNow() => DateTime.now().toUtc();

  static DateTime normalizeUtc(DateTime value) => value.toUtc();
}
