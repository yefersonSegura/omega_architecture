/// Reactive UI state exposed by [AuthAgent] when using [OmegaStatefulAgent].
class AuthViewState {
  const AuthViewState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  AuthViewState copyWith({bool? isLoading, String? errorMessage}) {
    return AuthViewState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  static const empty = AuthViewState();
}
