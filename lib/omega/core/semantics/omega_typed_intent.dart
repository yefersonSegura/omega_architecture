import 'omega_intent_name.dart';

/// A strongly-typed intent: the type carries both the wire name ([OmegaIntentName.name])
/// and your fields (credentials, ids, etc.).
///
/// Use with [OmegaFlowManager.handleTypedIntent] so the same instance is both the
/// semantic name source and the [OmegaIntent.payload]. In [OmegaFlow.onIntent], read
/// it with [OmegaIntentPayloadExtension.payloadAs] or [OmegaIntentTypedPayloadExtension.typedPayloadAs].
///
/// ```dart
/// final class SubmitLogin implements OmegaTypedIntent {
///   SubmitLogin(this.email, this.password);
///   @override
///   String get name => 'auth.login.submit';
///   final String email;
///   final String password;
/// }
///
/// flowManager.handleTypedIntent(SubmitLogin('a@b.com', 'secret'));
/// // onIntent: final data = ctx.intent?.typedPayloadAs<SubmitLogin>();
/// ```
///
/// For enum-only wires without a dedicated payload class, prefer
/// `OmegaIntent.fromName<YourDto>(AppIntent.login, payload: dto)` instead.
abstract interface class OmegaTypedIntent implements OmegaIntentName {}
