# OrCAD Capture Tcl Tools

[中文](README.md) · [Installation](install.en.md) · [User guide](usage.en.md)

[Release Notes](RELEASE_NOTES.en.md)

Property display, bulk property replacement and DNP annotation. Menu: **OrCAD Tools**. Panels remain in Chinese; bilingual documentation does not imply an English UI switch.

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

## Distribution and privacy

The allowlisted ZIP contains runtime scripts, bilingual docs and LICENSE only. It excludes Git history, tests, screenshots, designs, databases, diagnostics, logs, caches and actual machine paths. Paths and sample values in docs are generic examples. ZIP timestamps are fixed with no extra local metadata.

Personal bylines were removed from scripts and About. The original MIT copyright notice remains in LICENSE as required. This is not an attribution-free license copy. Runtime logs and CSV exports can contain real references, page names and properties; inspect them before sharing.

Developer tests: `python -m unittest discover -s tests -v` (Python + tkinter). Build: `python tools/build_release.py`. Python is not required to run the tools. [MIT](LICENSE).
