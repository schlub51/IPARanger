# Changelog

## Experimental fork

### Added

- Multi-account support.
- Per-account `ipatool` keychain service isolation via `IPATOOL_KEYCHAIN_SERVICE`.
- Version picker before downloading an app.
- Version release dates when returned by the version history service.
- Latest-version fallback when version history is unavailable.
- Minimum iOS version extraction from downloaded IPA metadata.
- Account attribution for downloaded IPAs.
- Non-blocking download banner.

### Changed

- Downloaded IPA metadata is fitted to the available cell width.
- Download list refresh keeps the original storage location instead of moving downloaded IPAs into account-specific folders.
- Logout wording was adjusted to avoid the scary "delete account" phrasing while still revoking the local token for the active account.

### Notes

- The embedded `ipatool` binary is patched. See [`patches/ipatool-keychain-service.patch`](patches/ipatool-keychain-service.patch).
- Downloaded App Store IPAs remain encrypted.
