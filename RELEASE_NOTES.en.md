# Release Notes — Capture Compatibility Fixes and Tool Updates

[中文](RELEASE_NOTES.md) · [Installation](install.en.md) · [User guide](usage.en.md)

Release date: 2026-10-10. These notes describe the compatibility update; runtime scripts still report version 1.0.0.

## Loading, menus and encoding

- Use Capture's Tcl-list InsertXMLMenu format with registered action and update callbacks instead of passing an XML filename.
- Initialize Tk on demand before GUI and message-box calls such as winfo; report actionable initialization errors.
- Hide the blank root created by tool initialization while leaving existing third-party Tk UI alone.
- Explicitly load UTF-8 scripts through an ASCII autoload bootstrap. Use English menu labels to avoid native menu code-page differences and remove unsupported button symbols.
- Allow registration retries without duplicating successful entries; preserve existing commands.
- Correct Capture Session, active design, selection, page/part iteration, CString property reads, property writes and display-property creation calls.

## ShowProperties

- Display footprints on resistors and combined capacitor labels such as CC0805/6.3V when both default properties are selected.
- Extract one unambiguous capacitor voltage from Description only when VOLTAGE_RATING is empty. Preserve existing ratings and skip missing or conflicting matches.
- Preserve source data, store combined text in CAP_PACKAGE_VOLTAGE and hide separate source labels.
- Reuse Value/Reference text anchors, font and rotation. RepositionProperties repairs existing label positions and adjusts spacing.

## BulkReplace and DNP

- Add PCB Footprint matching alongside Value and Part Number, using exact property matching.
- Correct full-design scans and page-name reads; fix success logging and continue after individual write failures.
- Correct DNP scanning and support nonempty multi-character prefixes. Repeated marking does not duplicate the prefix; unmarking restores the original Value.
- Remove the experimental full CIS relinking entry and diagnostics. BulkReplace only edits a specified property; it does not synchronize database attributes or replace complete symbols.

## Validation

Capture baseline: **OrCAD Capture CIS 17.4-2019 S037 (4108587), Windows SPB 64-bit Edition, Tcl 8.6.5**.

- Manual loading, Chinese panels, ShowProperties combined footprint/voltage display and positioning verified in Capture.
- Part Number scanning and result listing verified in Capture.
- DNP batch marking, unmarking and full-design scanning verified in Capture.
- All 11 Tcl mock regression tests pass; release contents, UTF-8 encoding and local documentation links checked.

The original reports concerned **17.2-2016 S079 / S083**. Fixes target the reported menu, Tk and encoding problems, but these hotfixes have not been retested in Capture. This release does not claim complete 17.2 compatibility. See README for other candidate products.

## Upgrade and limitations

Close panels, replace all runtime scripts together and reload the entry or restart Capture. Autoload uses one ASCII bootstrap plus a tool subdirectory; follow the installation guide. Do not mix old modules or encodings.

Use RepositionProperties explicitly to repair old positions; updates do not automatically move every label. Rerun property display after changing sources to refresh combined labels.

Layout does not detect collisions with parts or wires. Check occurrence overrides separately. Undo, actual bulk writes, CSV export, menu clicks and autoload still need full Capture acceptance testing. CSV uses simple comma separation. DNP does not automatically manage CIS Variants or BOM exclusion.

## Documentation

Updated Chinese and English README files, installation instructions and user guides with complete workflows, examples, troubleshooting and version validation scope. The package is available from repository Releases.
