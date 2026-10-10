# ASCII bootstrap: safe to source with a legacy Windows system encoding.
namespace eval ::OrcadTools {
    if {![info exists SCRIPT_ENCODING]} { variable SCRIPT_ENCODING utf-8 }

    proc sourceScript {path} {
        variable SCRIPT_ENCODING
        uplevel #0 [list source -encoding $SCRIPT_ENCODING $path]
    }

    # Capture may start with Tcl only. Load Tk on demand, before any Tk call.
    proc ensureTk {} {
        set loadedHere 0
        if {![llength [info commands ::winfo]]} {
            if {[catch {package require Tk} reason]} {
                error "OrCAD Tools: Tk could not be loaded: $reason. Check Capture's Tcl/Tk installation and auto_path."
            }
            set loadedHere 1
        }
        foreach command {winfo toplevel wm tk_messageBox} {
            if {![llength [info commands ::$command]]} {
                error "OrCAD Tools: Tk initialization is incomplete (missing $command)."
            }
        }
        # Tk creates an empty root window. Hide only the root we initialized;
        # leave any existing host/third-party Tk interface alone.
        if {$loadedHere} { wm withdraw . }
    }
}
