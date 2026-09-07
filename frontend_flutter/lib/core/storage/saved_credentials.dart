/// An e-mail and password kept for the sign-in form to pre-fill.
///
/// Deliberately a separate type from anything in the auth feature: this is a
/// convenience the *form* owns, never a session and never proof of anything.
/// Holding it apart is what stops it drifting into code that treats a stored
/// password as authentication.
class SavedCredentials {
  const SavedCredentials({required this.email, required this.password});

  final String email;
  final String password;

  @override
  bool operator ==(Object other) =>
      other is SavedCredentials &&
      other.email == email &&
      other.password == password;

  @override
  int get hashCode => Object.hash(email, password);
}
