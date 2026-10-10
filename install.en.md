# Installation

[中文](install.md) · [User guide](usage.en.md) · [Validation](README.en.md)

## Manual loading

Recommended for first validation. Extract the ZIP and keep these original UTF-8 files together: compat.tcl, utils.tcl, show_properties.tcl, bulk_replace_part.tcl, dnp_annotator.tcl, orcad_tools_menu.tcl.

Open Capture → View → Command Window. Replace this generic example path with your actual directory:

```tcl
source -encoding utf-8 "D:/orcad-tcl-tools/orcad_tools_menu.tcl"
```

Do not type tcl or Capture> before the command. Use forward slashes and quotes. The menu is **OrCAD Tools**. Commands ShowProperties, BulkReplace and DNPTool open panels directly. Capture database Tcl APIs and working Tk are required; Python is not.

## Automatic loading

Find `<Capture installation root>/tools/capture/tclscripts/capAutoLoad/` and deploy:

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

The ASCII bootstrap loads the entry explicitly as UTF-8. Do not put every module at the top level, where Capture may reload it using system encoding. Write permission is needed. Restart and check logs, menu and panels. Full autoload acceptance remains pending.

## Updates and removal

Close panels before replacing all scripts together, then restart. For temporary tests, source the entry again and reopen panels. Loading restores some defaults: recheck property selections, display mode and DNP prefix.

Uninstall by closing Capture and removing the bootstrap and tool subdirectory. For manual loading, stop sourcing after restart. Uninstalling does not undo existing design changes or text positions.

## Troubleshooting

| Symptom | Action |
|---|---|
| invalid command name "tcl" | Remove the tcl prefix |
| couldn't read file | Use the actual extraction path; examples are not created automatically |
| Missing winfo | Load all current files; Tk initializes on demand |
| Tk could not be loaded | Check Capture Tcl/Tk and auto_path; standalone Python Tk is not a substitute |
| Missing menu | Read logs; run RegisterOrcadToolsMenu after initialization or use commands |
| Garbled Chinese | Keep UTF-8 and explicit source encoding; do not change global encoding system |
| Invalid method | Reload current files and collect full errorInfo stack |
| Empty tk window | Current code hides the root it initializes. In an old session, wm withdraw . hides the root; first ensure another tool is not using it |

A 17.2 S079 Traditional Chinese report found Big5 conversion helped text, but it did not fix menus or Tk. Prefer original UTF-8. If all non-ASCII scripts were intentionally converted to Big5, manually run:

```tcl
namespace eval ::OrcadTools { variable SCRIPT_ENCODING big5 }
source -encoding big5 "D:/orcad-tcl-tools/orcad_tools_menu.tcl"
```

Do not mix encodings. The default bootstrap is for UTF-8 only. Big5 may lose some characters or symbols; 17.2 still needs an integration retest.

## Acceptance

Follow the user guide on a design copy. Timestamps and Error output are not commands. Remove design-specific information before sharing logs.
