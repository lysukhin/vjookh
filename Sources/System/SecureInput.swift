import Carbon

/// Whether a secure keyboard-entry field (password field) currently has focus.
/// When true the pipeline must not accumulate or correct typed text — the
/// privacy invariant plus a hard rule that we never touch credential input.
/// Thin shim — verified manually.
public enum SecureInput {
    public static var isEnabled: Bool {
        IsSecureEventInputEnabled()
    }
}
