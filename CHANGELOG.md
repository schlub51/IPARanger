# Changelog

## Experimental fork

Version label: `2.3.0+exp1`, based on upstream IPARanger 2.3.0.

### Added

- Multi-account support.
- Per-account `ipatool` keychain service isolation via `IPATOOL_KEYCHAIN_SERVICE`.
- Version picker before downloading an app.
- Version release dates when returned by the version history service.
- Latest-version fallback when version history is unavailable.
- Minimum iOS version extraction from downloaded IPA metadata.
- Account attribution for downloaded IPAs.
- Non-blocking download banner.
- iOS 13 fallback for the Downloads menu on rootful builds.

### Changed

- Downloaded IPA metadata is fitted to the available cell width.
- Download list refresh keeps the original storage location instead of moving downloaded IPAs into account-specific folders.
- Logout wording was adjusted to avoid the scary "delete account" phrasing while still revoking the local token for the active account.
- Rootful post-install setup now creates the cache folders used by the Downloads page.
- Card styling is used consistently for version selection and has better dark-mode contrast.

### Notes

- The embedded `ipatool` binary is patched. See [`patches/ipatool-keychain-service.patch`](patches/ipatool-keychain-service.patch).
- Downloaded App Store IPAs remain encrypted.
- Limited rootful testing was done on iOS 13.5; other rootful/rootless setups may still behave differently.
