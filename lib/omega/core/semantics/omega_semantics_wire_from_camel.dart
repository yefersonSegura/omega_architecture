/// Converts a Dart enum member name in camelCase to a dotted, lowercased wire id.
///
/// Inserts `.` between a lowercase/digit and an uppercase letter, then lowercases
/// the result. Examples: `ordersCreate` → `orders.create`, `authLogin` → `auth.login`,
/// `navigationIntent` → `navigation.intent`.
///
/// Used by [OmegaIntentNameDottedCamel] and [OmegaEventNameDottedCamel] so you can
/// skip string literals per enum case.
String omegaWireNameFromCamelCaseEnumMember(String enumMemberName) {
  if (enumMemberName.isEmpty) return enumMemberName;
  final dotted = enumMemberName.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (m) => '${m[1]}.${m[2]}',
  );
  return dotted.toLowerCase();
}
