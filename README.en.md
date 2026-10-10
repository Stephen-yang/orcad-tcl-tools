# OrCAD Capture Tcl Tools

Three practical schematic tools: show footprints and capacitor voltage ratings, replace properties in bulk, and annotate DNP parts.

[中文](README.md) · [Installation](install.en.md) · [User guide](usage.en.md) · [Release Notes](RELEASE_NOTES.en.md)

## Features

| Tool | Typical need | Result |
|---|---|---|
| ShowProperties | Footprint/rating is not visible on the schematic | Resistor: RC0402; capacitor: CC0805/6.3V |
| BulkReplace | Many parts need the same property change | Exact matching by Value, Part Number or PCB Footprint |
| DNPTool | Keep a part and its wiring but mark it unpopulated | Add/remove a Value prefix and optionally a DNP property |

**Validated baseline: OrCAD Capture CIS 17.4-2019 S037 (4108587), Windows 64-bit.** Detailed scope and other versions are listed below. The menu is **OrCAD Tools**; panels remain in Chinese. Bilingual documentation does not imply an English UI switch.

## Files

```text
orcad-tcl-tools/
  orcad_tools_menu.tcl       # Manual entry and menu registration
  orcad_tools_autoload.tcl   # Bootstrap placed at capAutoLoad top level
  compat.tcl                # Explicit encoding and Tk initialization
  utils.tcl                 # Capture iteration and property access
  show_properties.tcl       # Footprint/rating labels and layout
  bulk_replace_part.tcl     # Scan, replace and export
  dnp_annotator.tcl          # DNP mark, unmark and scan
  README.md / README.en.md
  install.md / install.en.md
  usage.md / usage.en.md
  RELEASE_NOTES.md / RELEASE_NOTES.en.md
  LICENSE
```

Developer tests and tools/build_release.py exist in source, but are excluded from the distribution ZIP.

## Quick installation

### Method 1: manual loading (recommended for first use)

1. Download the release ZIP from the repository's dist directory, or use the repository source.
2. Extract into a directory of your choice. `D:/orcad-tcl-tools/` below is a **generic example**. Confirm the actual location; extraction may create a nested folder.
3. Keep the entry, all three tools, utils.tcl and compat.tcl together in original UTF-8 encoding.
4. Open Capture → **View → Command Window**.
5. Enter this single line with your actual path:

```tcl
source -encoding utf-8 "D:/orcad-tcl-tools/orcad_tools_menu.tcl"
```

6. Check loading messages. Successful registration creates **OrCAD Tools**. If the menu is unavailable, commands ShowProperties, BulkReplace and DNPTool open panels directly.

The window already runs Tcl: **do not type tcl or Capture>** before commands. Use forward slashes and keep quotes. Python is not required to use the tools.

### Method 2: automatic loading

1. Locate tools/capture/tclscripts/capAutoLoad/ within your actual Capture installation.
2. Place only the bootstrap at the top level, with other runtime scripts in the subdirectory:

```text
capAutoLoad/
  orcad_tools_autoload.tcl
  orcad-tcl-tools/
    compat.tcl
    utils.tcl
    show_properties.tcl
    bulk_replace_part.tcl
    dnp_annotator.tcl
    orcad_tools_menu.tcl
```

3. Restart and check loading messages, menu and panels.

The ASCII bootstrap explicitly loads UTF-8. Do not put every module at the top level, where Capture may reload it with system encoding. Autoload still needs acceptance testing in the target installation. See [Installation](install.en.md) for updates, removal and Big5 notes.

## Tool 1: footprint and capacitor voltage display

Menu: **OrCAD Tools → Show Footprint / Voltage...**, or:

```tcl
ShowProperties
```

### Basic workflow

1. Open a design copy and schematic page. Select one part on the canvas first.
2. PCB Footprint and VOLTAGE_RATING are selected by default. Add other names using the custom-property field.
3. Choose value only (recommended), name and value, or name only.
4. Apply to selected parts first, then use current-page or all-pages processing. All-pages processing requests confirmation.
5. Check console messages, counts, references, text contents and positions.

Select parts on the schematic canvas, not just cells in Property Editor.

### Default results

| Part | Input | Added text |
|---|---|---|
| Resistor | PCB Footprint=RC0402 | RC0402 |
| Capacitor | PCB Footprint=CC0805, VOLTAGE_RATING=6.3V | CC0805/6.3V |
| Capacitor with no rating | Description contains one clear 6.3V token | Extract rating, store it, then show combined label |

With both defaults selected, capacitor combined text is stored in **CAP_PACKAGE_VOLTAGE**. Source data remains; separate source labels are hidden. Resistors do not display the default voltage item; existing voltage text is hidden without deleting its data.

### Extracting voltage from Description

```text
Description: CAP CER 47uF 20% 6.3V X5R
Extracted: VOLTAGE_RATING=6.3V
Combined: CC0805/6.3V
```

Supported forms include 25V, 25 VDC, 1KV and 2V5. Existing ratings are preserved. Missing or conflicting voltage tokens are skipped and logged. Capacitor detection uses C-plus-digits references or a Part Type starting with CAP; validate unusual naming conventions.

A complete combined label is not created without a rating. Selecting only one item does not remove every old combined label: inspect existing text and hide unwanted entries using Capture Display Properties when changing schemes.

### Layout and repair

New text reuses Value (or Reference) anchors, rotation and font. Horizontal labels continue along their row; vertical labels extend downward. Ordinary display preserves existing positions.

Select affected parts and run:

```tcl
RepositionProperties 0
```

Zero selects automatic spacing. A nonnegative integer sets a custom gap:

```tcl
RepositionProperties 4
```

Units are drawing coordinates, not millimeters. Test one part before a group. This is not a collision-aware engine; dense areas may need manual adjustment. Rerun ShowProperties after source values change to update combined labels.

## Tool 2: bulk property replacement

Menu: **OrCAD Tools → Bulk Replace...**, or:

```tcl
BulkReplace
```

### Match modes

| Mode | Example old value | Example new value | Property changed |
|---|---|---|---|
| Value | 10K | 22K | Value |
| Part Number | DEMO-PART-001 | DEMO-PART-002 | Part Number |
| PCB Footprint | CC0805 | CC0603 | PCB Footprint |

### Workflow

1. On a design copy, choose the mode and enter old/new values.
2. Click scan. Matching is exact and case-sensitive across all design pages.
3. Review REFDES, page, current value and match count.
4. Execute replacement and review the confirmation. Execution rescans the whole design; it does not replace just one selected results row.
5. Inspect schematic and Property Editor values. Optionally export CSV.

This edits properties, not complete parts. Changing Part Number does not synchronize Value, Description, footprint or vendor data from CIS. Changing PCB Footprint does not validate library availability. Symbols and wiring are not automatically replaced. The experimental full CIS relinking entry was removed.

Occurrence overrides may differ from instance values; inspect both. Individual write failures are logged and processing continues, so batches are not atomic. Undo is unverified; retain the original design copy.

CSV contains actual design data and uses simple comma separation. Inspect fields containing commas, quotes or newlines; do not rely on it for automated rollback.

## Tool 3: DNP annotation

Menu: **OrCAD Tools → DNP → DNP Panel...**, or:

```tcl
DNPTool
```

### Panel workflow

1. Select one or more parts on the schematic canvas.
2. Batch mark to add the prefix, default *.
3. Repeated marking does not duplicate it. Batch unmark restores Value.
4. Toggle acts independently: marked parts become unmarked, unmarked parts become marked.
5. Scan the full design to list reference, page and Value.

### Commands and effects

```tcl
DNPMark
DNPUnmark
DNPToggle
```

| Action | Example |
|---|---|
| Mark | 10K → *10K |
| Mark again | *10K remains unchanged |
| Unmark | *10K → 10K |

The optional DNP-property checkbox is enabled by default: marking writes DNP=YES; unmarking clears it. When disabled, only Value changes and existing DNP data remains. A nonempty multi-character prefix is supported. Detection uses the start of Value, not the DNP property.

No parts are deleted and CIS Variant fitted status is not managed. BOM exclusion needs an explicit filter. Value and DNP are independent writes: verify both and any occurrence overrides.

## Troubleshooting

| Symptom | Action |
|---|---|
| invalid command name "tcl" | Enter source or tool commands without tcl |
| couldn't read file | Replace the generic example with the actual script path |
| Missing menu | Check logs; run RegisterOrcadToolsMenu after initialization or use commands |
| Missing winfo | Close panels and load all current scripts; Tk initializes on demand |
| Tk could not be loaded | Check Capture Tcl/Tk and auto_path; Python Tk is not a substitute |
| Garbled Chinese | Use original UTF-8 with explicit source encoding; do not change global encoding system |
| Missing property | Check actual property names; voltage in Description is not already a rating property |
| Stale combined label | Run ShowProperties again |
| Invalid method | Reload all current scripts and capture the full stack trace |

Timestamps and Error messages are output, not commands. See [Installation](install.en.md) for Big5, updates and removal.

## Command reference

| Command | Purpose |
|---|---|
| ShowProperties | Property display panel |
| RepositionProperties 0 | Automatically reposition selected target labels |
| BulkReplace | Property replacement panel |
| DNPTool | DNP panel |
| DNPMark / DNPUnmark / DNPToggle | Mark / unmark / toggle selection |
| RegisterOrcadToolsMenu | Retry registration |

## Validated baseline

**OrCAD Capture CIS 17.4-2019 S037 (4108587), Windows SPB 64-bit Edition, Tcl 8.6.5**. Version details were checked in About. Validation date: 2026-10-10.

| Feature | Status |
|---|---|
| Manual UTF-8 loading and Chinese panels | Verified in Capture |
| ShowProperties | Footprints, capacitor voltage extraction, combined labels and repositioning verified in Capture |
| BulkReplace scan | Part Number scan and results verified in Capture |
| BulkReplace writes, export and PCB Footprint mode | Mock tests or code review only; Capture acceptance pending |
| DNP | Batch mark, unmark and full-design scan verified in Capture; Toggle covered by regression tests |
| Menu clicks and autoload | Full acceptance pending; command-based panel opening verified |

Mock tests are not Capture integration tests. Undo is unverified. Use a design copy before making changes.

## Compatibility

| Product / release | Status |
|---|---|
| Capture CIS 17.4-2019 S037 | Validated baseline within the scope above |
| Capture CIS 17.2-2016 S079 / S083 | Menu, Tk and encoding issues reported; targeted fixes implemented, but no retest on these hotfixes |
| Other Capture / CIS 17.4 hotfixes and 22.1 | Candidate through similar Capture APIs; untested |
| Allegro Design Entry Capture / CIS | Candidate in the Capture product family; untested |
| OrCAD X Capture / Capture CIS | Candidate only; APIs and context may differ; untested |
| Capture 16.x and earlier | Untested; no compatibility commitment |
| Allegro PCB Editor, OrCAD X Presto, Design Entry HDL, standalone PSpice | Outside the target runtime |

Candidate compatibility is an inference, not vendor certification. References: [Cadence Capture automation](https://support1.cadence.com/public/docs/content/20469530.html), [Capture API documentation](https://www.ema-eda.com/wp-content/uploads/files/resources/files/OrCAD_Capture_TclTk_Extensions.pdf).

## Scope

BulkReplace edits Value, Part Number or PCB Footprint only. It does not perform complete CIS relinking or database synchronization. The experimental CIS entry was removed. Occurrence overrides may differ from instance properties; inspect both. DNP prefixes and properties do not control CIS Variant fitted status.

## Downloads and documentation

Download the package from repository Releases. See [Installation](install.en.md), [User guide](usage.en.md) and [Release Notes](RELEASE_NOTES.en.md). Python is not required to run the tools.

## License

This project uses the [MIT License](LICENSE).
