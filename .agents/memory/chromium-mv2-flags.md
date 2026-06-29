---
name: Chromium MV2 extension flags
description: Correct command-line flags to allow MV2 extensions in Chromium 138+
---

# Chromium 138+ MV2 Extension Flags

## The rule
To allow MV2 extensions in Chromium 138+, pass these flags at launch:

```
--allow-legacy-mv2-extensions
--enable-features=AllowLegacyMV2Extensions
--disable-features=ExtensionManifestV2Disabled,ExtensionManifestV2Unsupported
```

**Why:** Chromium 138 auto-disables MV2 extensions by default. The feature flag names were found by running `strings` on the Chromium binary and grepping for "mv2". The flag `--disable-features=ExtensionManifestV2Deprecation` (wrong name) did nothing. The correct names are `ExtensionManifestV2Disabled` and `ExtensionManifestV2Unsupported`.

**How to apply:** Add to the Chromium launch command in start.sh alongside `--load-extension`. Extensions loaded via `--load-extension` still get disabled without these flags.

## Policy approach (not possible on NixOS Replit)
`/etc/chromium/` is read-only — cannot create policy files there.

## Helper extension approach (failed)
MV3 "enabler" extension calling `chrome.management.setEnabled()` loses the race against Chrome's internal disable logic.
