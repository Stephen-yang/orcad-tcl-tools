# User Guide

[中文](usage.md) · [Installation](install.en.md) · [Validation scope](README.en.md)

Open a design copy and a schematic page. Select parts on the canvas rather than cells in Property Editor. All examples below are generic. Menu labels are English; panel buttons are Chinese.

## Commands

| Command | Purpose |
|---|---|
| ShowProperties | Property display panel |
| RepositionProperties 0 | Automatically reposition target labels on selected parts |
| RepositionProperties 4 | Set a custom gap; 0 restores automatic calculation |
| BulkReplace | Bulk property replacement panel |
| DNPTool | DNP panel |
| DNPMark / DNPUnmark | Mark / unmark selected parts |
| DNPToggle | Toggle each selected part independently |
| RegisterOrcadToolsMenu | Retry menu registration after Capture initialization |

## ShowProperties

Use **OrCAD Tools → Show Footprint / Voltage...** or ShowProperties.

1. PCB Footprint and VOLTAGE_RATING are selected by default. Custom property names are case-sensitive.
2. Choose value only, name and value, or name only.
3. Apply to selected parts, the current page or all pages. All-pages processing asks for confirmation.
4. Read the console and statistics. Missing properties are skipped with the reference and reason logged.

### Resistors and capacitors

- Resistors show their footprint by default, such as RC0402. VOLTAGE_RATING text is hidden while its data remains. Other explicitly added custom properties can still be displayed.
- With both defaults selected, capacitors show one label such as `CC0805/6.3V`, stored as **CAP_PACKAGE_VOLTAGE**. Original footprint and voltage data remain; separate existing labels are hidden.
- A populated voltage rating is preserved, not overwritten from Description.
- If absent, capacitor Description is parsed. `CAP CER 47uF 20% 6.3V X5R` produces `6.3V`, written to VOLTAGE_RATING before display.
- Supported forms include 25V, 25 VDC, 1KV and 2V5. Missing or conflicting voltages are skipped. Repeated identical values are accepted.
- Capacitors are identified by a C-plus-digits reference or a Part Type starting with CAP. R-plus-digits references do not trigger voltage extraction. Validate unusual naming conventions.
- A new full combined label is not created when either source is missing or both defaults are not selected. Available target properties may still be displayed. Run display again after changing source values to refresh a combined label.

Unchecking an option does not delete or hide every label created previously. When changing display schemes, inspect existing combined and separate labels and manually hide unwanted entries using Capture Display Properties if necessary.

### Layout

New labels reuse the Value anchor, or Part Reference / Reference when necessary, with its rotation and font. Horizontal text extends along its row; vertical text extends downward in the same column. Normal display preserves existing positions.

Select parts and run RepositionProperties 0 to repair old positions. Use a nonnegative integer such as RepositionProperties 4 to adjust the gap. Units are drawing coordinates, not millimeters. Automatic spacing is derived from text bounds. The setting affects subsequent calls in the session.

This is not a collision-aware layout engine: it does not detect other parts, wires or borders. Test one part in dense areas before processing a group; long combined labels may need manual adjustment. Missing Value/Reference anchors produce an error instead of guessed coordinates.

## BulkReplace

Use **OrCAD Tools → Bulk Replace...** or BulkReplace.

1. Select Value, Part Number or PCB Footprint.
2. Enter old and new values, for example CC0805 → CC0603.
3. Scan for exact, case-sensitive matches across all design pages; inspect references, pages and values.
4. Execute replacement after reviewing the confirmation. Execution rescans the whole design; it does not change only a selected result row.
5. Inspect properties, schematic and logs; optionally export CSV.

Only the selected property is changed. Symbols are not replaced, footprint availability is not validated, and other database attributes are not synchronized. Part Number mode is not complete CIS relinking. Occurrence overrides may still differ from instance values.

A combined capacitor label may become stale after a source property changes; rerun ShowProperties. Individual write failures are logged and processing continues, so a batch is not an atomic transaction. Do not assume Ctrl+Z reverses every change; retain the original design copy.

CSV contains real design data. Export currently uses simple comma-separated fields; inspect values containing commas, quotes or newlines. It is not a reliable automated rollback file.

## DNP annotation

Use **OrCAD Tools → DNP → DNP Panel...** or DNPTool.

- DNPMark changes 10K to *10K; repeated marking does not duplicate the prefix.
- DNPUnmark restores *10K to 10K.
- DNPToggle marks or unmarks each part according to its current prefix. Two toggles normally restore the original Value.
- Full-design scan lists reference, page and Value for marked parts.

The default prefix is `*`. A nonempty custom prefix, including multiple characters, can be entered in the panel. DNP detection uses the beginning of Value, not the DNP property. The default also writes `DNP=YES`; unmarking clears it. If the option is disabled, only Value changes and existing DNP data remains untouched.

No parts are deleted, wires are unchanged, and CIS Variant fitted status is not managed. BOM exclusion depends on explicit BOM filtering by the DNP property or prefix. A Value originally beginning with the configured prefix is also treated as DNP.

Value and DNP are separate writes; verify both after execution instead of relying only on success counts. Occurrence overrides can affect display and BOM; inspect instance and occurrence values.

## Acceptance checklist

On a copy, check panels, scans, one replacement, footprint/voltage labels, layout, mark/unmark, full-design DNP scan, references, positions and wires. See README for actual validation scope. Mock tests are not product compatibility certification.
