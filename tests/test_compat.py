"""Run with python -m unittest discover -s tests (uses Tcl via tkinter)."""
from pathlib import Path
import tkinter
import unittest

ROOT = Path(__file__).resolve().parents[1]


class CompatibilityTests(unittest.TestCase):
    def setUp(self):
        self.tcl = tkinter.Tcl()
        self.tcl.eval('proc puts {args} {}')

    def source(self, name):
        self.tcl.call('source', '-encoding', 'utf-8', str(ROOT / name))

    def test_dnp_mark_unmark_toggle_and_scan(self):
        self.source('dnp_annotator.tcl')
        self.tcl.eval('''
            array set props {Value 10K DNP ""}
            proc DboState {} {return state}
            proc ::OrcadTools::getRefDes {part} {return R1}
            proc ::OrcadTools::getPartPropValue {part name} {return $::props($name)}
            proc ::OrcadTools::setPartPropValue {part name value} {
                set ::props($name) $value; return 0
            }
            proc ::OrcadTools::getSelectedParts {} {return part}
            proc ::OrcadTools::msgBox {args} {}
            proc ::OrcadTools::getActiveDesign {} {return design}
            proc ::OrcadTools::forEachPage {design callback} {uplevel 1 [concat $callback {page 0}]}
            proc ::OrcadTools::forEachPart {page callback} {uplevel 1 [concat $callback {part}]}
            proc ::OrcadTools::makeCString {value} {return name}
            proc ::OrcadTools::getCString {value} {return TEST_PAGE}
            proc page {method output} {}
        ''')
        self.assertEqual(self.tcl.eval('::OrcadTools::DNP::markDNP part'), '1')
        self.assertEqual(self.tcl.eval('set props(Value)'), '*10K')
        self.assertEqual(self.tcl.eval('set props(DNP)'), 'YES')
        self.assertEqual(self.tcl.eval('::OrcadTools::DNP::markDNP part'), '0')
        self.assertEqual(self.tcl.eval('::OrcadTools::DNP::scanAllDNP'), '{R1 TEST_PAGE *10K}')
        self.tcl.eval('DNPToggle')
        self.assertEqual(self.tcl.eval('set props(Value)'), '10K')
        self.assertEqual(self.tcl.eval('set props(DNP)'), '')
        self.assertEqual(self.tcl.eval('::OrcadTools::DNP::scanAllDNP'), '')
        self.tcl.eval('set ::OrcadTools::DNP::DNP_PREFIX {DNP:}; DNPMark; DNPMark')
        self.assertEqual(self.tcl.eval('set props(Value)'), 'DNP:10K')
        self.tcl.eval('DNPUnmark')
        self.assertEqual(self.tcl.eval('set props(Value)'), '10K')
        self.tcl.eval('set ::OrcadTools::DNP::DNP_PREFIX {}')
        with self.assertRaisesRegex(tkinter.TclError, 'must not be empty'):
            self.tcl.eval('DNPMark')

    def test_bulk_scan_and_replace_across_pages(self):
        self.source('bulk_replace_part.tcl')
        self.tcl.eval('''
            proc ::OrcadTools::getActiveDesign {} {return design}
            proc ::OrcadTools::forEachPage {design callback} {
                uplevel 1 [concat $callback {pageA 0}]
                uplevel 1 [concat $callback {pageB 1}]
            }
            proc ::OrcadTools::forEachPart {page callback} {
                if {$page eq "pageA"} {set parts {r1 r2}} else {set parts {r3}}
                foreach part $parts {uplevel 1 [concat $callback [list $part]]}
            }
            proc ::OrcadTools::makeCString {value} {return output}
            proc ::OrcadTools::getCString {value} {return $::pageName}
            proc pageA {method output} {set ::pageName A}
            proc pageB {method output} {set ::pageName B}
            array set values {r1 10K r2 100K r3 10K}
            proc ::OrcadTools::getPartPropValue {part prop} {return $::values($part)}
            proc ::OrcadTools::getRefDes {part} {return [string toupper $part]}
            set writes {}
            proc ::OrcadTools::setPartPropValue {part prop value} {
                if {$part eq "r3"} {error "read-only part"}
                lappend ::writes [list $part $prop $value]
                set ::values($part) $value
                return 0
            }
        ''')
        self.assertEqual(self.tcl.eval('::OrcadTools::BulkReplace::scanDesign Value 10K'), '{R1 A 10K r1} {R3 B 10K r3}')
        self.assertEqual(self.tcl.eval('set writes'), '')
        self.assertEqual(self.tcl.eval('::OrcadTools::BulkReplace::executeReplace Value 10K 22K'), '1')
        self.assertEqual(self.tcl.eval('set writes'), '{r1 Value 22K}')
        self.assertEqual(self.tcl.eval('llength $::OrcadTools::BulkReplace::replaceLog'), '2')
        self.assertEqual(self.tcl.eval('lindex $::OrcadTools::BulkReplace::replaceLog 1 4'), '失败')
        self.tcl.eval('''
            set values(r1) CC0805; set values(r2) CC0402; set values(r3) CC0805
            set writes {}; set reads {}
            proc ::OrcadTools::getPartPropValue {part prop} {
                lappend ::reads $prop
                return $::values($part)
            }
        ''')
        self.assertEqual(self.tcl.eval('::OrcadTools::BulkReplace::scanDesign {PCB Footprint} CC0805'), '{R1 A CC0805 r1} {R3 B CC0805 r3}')
        self.assertEqual(self.tcl.eval('lsort -unique $reads'), '{PCB Footprint}')
        self.assertEqual(self.tcl.eval('::OrcadTools::BulkReplace::executeReplace {PCB Footprint} CC0805 CC0603'), '1')
        self.assertEqual(self.tcl.eval('set writes'), '{r1 {PCB Footprint} CC0603}')

    def test_menu_shape_callbacks_and_reload(self):
        self.tcl.eval('''
            set menus {}; set actions {}
            proc InsertXMLMenu {spec} {
                if {[llength $spec] != 5} {error "invalid menu specification"}
                lappend ::menus $spec
            }
            proc RegisterAction {name enable key callback context} {
                dict set ::actions $name $callback
            }
        ''')
        self.source('orcad_tools_menu.tcl')
        self.assertEqual(int(self.tcl.eval('llength $menus')), 9)
        self.assertEqual(int(self.tcl.eval('dict size $actions')), 8)
        self.tcl.eval('''
            foreach spec $menus {
                set item [lindex $spec 3]
                if {[lindex $item 0] eq "action"} {
                    foreach i {3 4} {
                        if {![dict exists $actions [lindex $item $i]]} {error "unregistered action"}
                    }
                }
            }
            proc ::ShowProperties {} {set ::invoked 1}
            eval [dict get $actions OrcadTools_ShowProperties] extra host arguments
        ''')
        self.assertEqual(self.tcl.eval('set invoked'), '1')
        self.source('orcad_tools_menu.tcl')
        self.assertEqual(int(self.tcl.eval('llength $menus')), 9)
        self.assertFalse((ROOT / '_menu_temp.xml').exists())

    def test_missing_menu_api_and_retry_after_partial_failure(self):
        self.source('orcad_tools_menu.tcl')
        self.assertEqual(self.tcl.eval('RegisterOrcadToolsMenu'), '0')
        self.tcl.eval('''
            set count 0
            proc RegisterAction {args} {}
            proc InsertXMLMenu {spec} {
                incr ::count
                if {$::count == 2} {error "not ready"}
            }
        ''')
        self.assertEqual(self.tcl.eval('RegisterOrcadToolsMenu'), '0')
        self.assertEqual(self.tcl.eval('RegisterOrcadToolsMenu'), '1')
        self.assertEqual(self.tcl.eval('set count'), '10')

    def test_gui_entrypoints_load_tk_before_winfo(self):
        self.source('orcad_tools_menu.tcl')
        self.tcl.eval('''
            rename package real_package
            set loads 0
            proc package {args} {
                incr ::loads
                proc ::winfo {args} {return 1}
                proc ::toplevel {args} {}
                proc ::wm {args} {lappend ::wmCalls $args}
                proc ::raise {args} {}
                proc ::tk_messageBox {args} {return yes}
                return 8.5
            }
        ''')
        for command in ('ShowProperties', 'BulkReplace', 'DNPTool', 'ShowAboutOrcadTools'):
            self.tcl.eval(command)
        self.assertEqual(self.tcl.eval('set loads'), '1')
        self.assertEqual(self.tcl.eval('lindex $wmCalls 0'), 'withdraw .')
        self.assertEqual(self.tcl.eval('llength [lsearch -all -exact $wmCalls {withdraw .}]'), '1')
        self.assertEqual(self.tcl.eval('::OrcadTools::msgBoxConfirm title message'), 'yes')

    def test_tk_failure_is_actionable_and_confirmation_fails_closed(self):
        self.source('utils.tcl')
        self.tcl.eval('rename package real_package; proc package {args} {error "Tk absent"}')
        with self.assertRaisesRegex(tkinter.TclError, 'Tk could not be loaded.*Tk absent'):
            self.tcl.eval('::OrcadTools::msgBoxConfirm title message')

    def test_utf8_loading_under_big5_system_encoding(self):
        self.tcl.eval('encoding system big5')
        self.source('orcad_tools_menu.tcl')
        self.assertIn('关于 OrCAD', self.tcl.eval('info body ShowAboutOrcadTools'))
        self.assertIn('请先选中', self.tcl.eval('info body ::OrcadTools::DNP::toggleSelectedDNP'))

    def test_capture_session_selection_and_iterators(self):
        self.source('utils.tcl')
        self.tcl.eval('''
            set ::DboSession_s_pDboSession session
            set ::DboBaseObject_PLACED_INSTANCE 42
            set ::IterDefs_SCHEMATICS 1
            proc DboSession {flag pointer} {set ::wrapped $pointer}
            proc session {method} {
                if {$method ne "GetActiveDesign"} {error "wrong method"}
                return design
            }
            proc GetSelectedObjects {} {return {part wire NULL}}
            proc part {method} {return 42}
            proc wire {method} {return 7}
            proc DboState {} {return status}
            proc design {method status kind} {
                if {$method ne "NewViewsIter"} {error "wrong design iterator"}
                set ::viewIndex 0; return views
            }
            proc views {method status} {
                if {$method ne "NextView"} {error "wrong view iterator"}
                if {[incr ::viewIndex] == 1} {return view}; return NULL
            }
            proc DboViewToDboSchematic {view} {return schematic}
            proc schematic {method status} {
                if {$method ne "NewPagesIter"} {error "wrong page iterator"}
                set ::pageIndex 0; return pages
            }
            proc pages {method status} {
                if {$method ne "NextPage"} {error "wrong page step"}
                if {[incr ::pageIndex] == 1} {return page}; return NULL
            }
            proc page {method status} {
                if {$method ne "NewPartInstsIter"} {error "wrong part iterator"}
                set ::partIndex 0; return parts
            }
            proc parts {method status} {
                if {$method ne "NextPartInst"} {error "wrong part step"}
                if {[incr ::partIndex] == 1} {return part}; return NULL
            }
            set deleted {}
            foreach type {DboPagePartInstsIter DboSchematicPagesIter DboLibViewsIter} {
                proc delete_$type {iter} {lappend ::deleted $iter}
            }
            proc visit {prefix page index} {
                lappend ::visited [list $prefix $page $index]
                ::OrcadTools::forEachPart $page [list apply {{part} {
                    lappend ::visited $part
                }}]
            }
        ''')
        self.assertEqual(self.tcl.eval('::OrcadTools::getActiveDesign'), 'design')
        self.assertEqual(self.tcl.eval('set wrapped'), 'session')
        self.assertEqual(self.tcl.eval('::OrcadTools::getSelectedParts'), 'part')
        self.assertEqual(self.tcl.eval('::OrcadTools::forEachPage design {visit prefix}'), '1')
        self.assertEqual(self.tcl.eval('set visited'), '{prefix page 0} part')
        self.assertEqual(self.tcl.eval('set deleted'), 'parts pages views')

    def test_property_output_cstring_and_display_creation(self):
        self.source('show_properties.tcl')
        self.tcl.eval('''
            set serial 0; set created 0; set mode 0
            proc DboTclHelper_sMakeCString {{value ""}} {
                set name str[incr ::serial]; set ::strings($name) $value; return $name
            }
            proc DboTclHelper_sGetConstCharPtr {name} {return $::strings($name)}
            proc DboState {} {return state}
            proc DboTclHelper_sGetCRectBottomRight {bounds} {return corner}
            proc DboTclHelper_sGetCRectTopLeft {bounds} {return corner}
            proc DboTclHelper_sGetCPointX {point} {return 20}
            proc DboTclHelper_sGetCPointY {point} {return 30}
            proc DboTclHelper_sMakeCPoint {x y} {return [list $x $y]}
            proc DboTclHelper_sMakeLOGFONT {} {return font}
            proc DboDisplayProp_sGetFont {anchor status} {return anchorFont}
            set anchorRotation 0
            proc part {method args} {
                switch -- $method {
                    GetReferenceDesignator {
                        set ::strings([lindex $args 0]) C1
                    }
                    GetEffectivePropStringValue {
                        set name $::strings([lindex $args 0])
                        if {$name eq "PCB Footprint"} {
                            set ::strings([lindex $args 1]) CC0805
                        }
                        return stateWrapper
                    }
                    GetDisplayProp {
                        if {$::strings([lindex $args 0]) eq "Value"} {return anchor}
                        if {$::created && $::strings([lindex $args 0]) eq "PCB Footprint"} {
                            return display
                        }
                        return NULL
                    }
                    GetBoundingBox {error "page bounding box must not be used for text"}
                    NewDisplayProp {
                        if {[llength $args] != 6} {error "invalid NewDisplayProp arguments"}
                        set ::creation $args; incr ::created; return display
                    }
                    default {error "unexpected method: $method"}
                }
            }
            proc display {method value} {
                switch -- $method {
                    GetDisplayType {return $::mode}
                    SetDisplayType {set ::mode $value}
                    SetLocation {set ::newLocation $value}
                    SetRotation {set ::newRotation $value}
                    SetFont {set ::newFont $value}
                    default {error "unexpected display method"}
                }
            }
            proc anchor {method {status ""}} {
                if {$method eq "GetRotation"} {return $::anchorRotation}
                if {$method eq "GetBoundingBox"} {return box}
                if {$method ne "GetLocation"} {error "wrong anchor method"}
                return localPoint
            }
            proc GetSelectedObjects {} {return part}
            set ::DboBaseObject_PLACED_INSTANCE 42
        ''')
        self.assertEqual(self.tcl.eval('::OrcadTools::getPartPropValue part {PCB Footprint}'), 'CC0805')
        self.assertEqual(self.tcl.eval('::OrcadTools::getRefDes part'), 'C1')
        self.assertEqual(self.tcl.eval('::OrcadTools::ShowProps::showPropsForPart part'), '1')
        self.assertEqual(self.tcl.eval('set mode'), '1')
        self.assertEqual(self.tcl.eval('lindex $creation 2'), '30 30')
        self.assertEqual(self.tcl.eval('::OrcadTools::ShowProps::showPropsForPart part'), '0')
        self.assertEqual(self.tcl.eval('set created'), '1')
        self.tcl.eval('set ::OrcadTools::ShowProps::DISPLAY_TYPE 2')
        self.assertEqual(self.tcl.eval('::OrcadTools::ShowProps::showPropsForPart part'), '1')
        self.assertEqual(self.tcl.eval('set mode'), '2')
        self.tcl.eval('rename part actualPart; proc part {method args} {if {$method eq "GetObjectType"} {return 42}; return [eval actualPart $method $args]}')
        self.assertEqual(self.tcl.eval('RepositionProperties'), '1')
        self.assertEqual(self.tcl.eval('set newLocation'), '30 30')
        for rotation, location in [(0, '30 30'), (1, '20 40'), (2, '10 30'), (3, '20 40')]:
            self.tcl.setvar('anchorRotation', rotation)
            self.assertEqual(self.tcl.eval('RepositionProperties'), '1')
            self.assertEqual(self.tcl.eval('set newLocation'), location)
            self.assertEqual(int(self.tcl.eval('set newRotation')), rotation)
            self.assertEqual(self.tcl.eval('set newFont'), 'anchorFont')
        self.assertEqual(self.tcl.eval('RepositionProperties 16'), '1')
        self.assertEqual(self.tcl.eval('set newLocation'), '20 46')
        with self.assertRaisesRegex(tkinter.TclError, 'Usage:'):
            self.tcl.eval('RepositionProperties -1')
        self.tcl.eval('''
            proc DboTclHelper_sGetCRectTopLeft {bounds} {return top}
            proc DboTclHelper_sGetCPointX {point} {
                if {$point eq "top"} {return 0}; return 20
            }
            proc DboTclHelper_sGetCPointY {point} {
                if {$point eq "top"} {return 22}; return 30
            }
            set anchorRotation 0
        ''')
        self.assertEqual(self.tcl.eval('RepositionProperties 0'), '1')
        self.assertEqual(self.tcl.eval('set newLocation'), '52 30')
        self.tcl.setvar('anchorRotation', 1)
        self.tcl.eval('RepositionProperties 0')
        self.assertEqual(self.tcl.eval('set newLocation'), '20 62')

    def test_voltage_parsing_and_existing_rating_preservation(self):
        self.source('show_properties.tcl')
        cases = {
            'C SMD CER 47uF 20% 6.3V X5R 0805 T1.25mm': '6.3V',
            'CAP 25 VDC': '25V', 'CAP 1KV': '1KV', 'CAP 2V5': '2.5V',
            'CAP 08V': '8V', 'CAP 25V / 25.0V': '25V',
            'CAP 6.3V / 10V': '', 'CAP 47uF 20% X5R': '',
            'PN ABC25VXYZ': '', 'CAP 0V': '',
        }
        for description, expected in cases.items():
            self.assertEqual(str(self.tcl.call('::OrcadTools::ShowProps::parseVoltage', description)), expected)
        self.tcl.eval('''
            set rating ""; set description "CAP 6.3V"; set writes 0
            proc ::OrcadTools::getPartPropValue {part name} {
                switch -- $name {
                    VOLTAGE_RATING {return $::rating}
                    Description {return $::description}
                    default {return ""}
                }
            }
            proc ::OrcadTools::setPartPropValue {part name value} {
                incr ::writes; set ::rating $value; return 0
            }
        ''')
        self.assertEqual(self.tcl.eval('::OrcadTools::ShowProps::populateVoltage part C1'), '6.3V')
        self.tcl.eval('set description "CAP 10V"')
        self.assertEqual(self.tcl.eval('::OrcadTools::ShowProps::populateVoltage part C1'), '6.3V')
        self.assertEqual(self.tcl.eval('set writes'), '1')

        self.assertEqual(self.tcl.eval('::OrcadTools::ShowProps::populateVoltage part R1'), '')
        self.assertEqual(self.tcl.eval('::OrcadTools::ShowProps::isCapacitor part R1'), '0')
        self.assertEqual(self.tcl.eval('::OrcadTools::ShowProps::isCapacitor part C1'), '1')
        self.tcl.eval('set rating ""')
        self.assertEqual(self.tcl.eval('::OrcadTools::ShowProps::populateVoltage part U5'), '')
        self.tcl.eval('set description "CAP 6.3V 10V"')
        self.assertEqual(self.tcl.eval('::OrcadTools::ShowProps::populateVoltage part C1'), '')
        self.assertEqual(self.tcl.eval('set writes'), '1')

    def test_capacitor_combined_label_preserves_sources(self):
        self.source('show_properties.tcl')
        self.tcl.eval('''
            array set props {"PCB Footprint" CC0805 VOLTAGE_RATING 6.3V}
            proc ::OrcadTools::getPartPropValue {part name} {
                if {[info exists ::props($name)]} {return $::props($name)}
                return ""
            }
            proc ::OrcadTools::setPartPropValue {part name value} {
                set ::props($name) $value; return 0
            }
            proc ::OrcadTools::makeCString {value} {return $value}
            proc part {method name status} {
                if {$method ne "GetDisplayProp"} {error "unexpected method"}
                if {$name eq "PCB Footprint"} {return oldFootprint}
                if {$name eq "VOLTAGE_RATING"} {return oldVoltage}
                return NULL
            }
            proc oldFootprint {method value} {set ::footprintMode $value}
            proc oldVoltage {method value} {set ::voltageMode $value}
        ''')
        self.tcl.eval('::OrcadTools::ShowProps::prepareCombinedLabel part C1 status')
        self.assertEqual(self.tcl.eval('set props(CAP_PACKAGE_VOLTAGE)'), 'CC0805/6.3V')
        self.assertEqual(self.tcl.eval('set {props(PCB Footprint)}'), 'CC0805')
        self.assertEqual(self.tcl.eval('set props(VOLTAGE_RATING)'), '6.3V')
        self.assertEqual(self.tcl.eval('set footprintMode'), '0')
        self.assertEqual(self.tcl.eval('set voltageMode'), '0')
        self.assertEqual(self.tcl.eval('::OrcadTools::ShowProps::displayNames part C1'), 'CAP_PACKAGE_VOLTAGE')
        self.assertEqual(self.tcl.eval('::OrcadTools::ShowProps::usesCombinedLabel part R1'), '0')
        self.tcl.eval('set props(VOLTAGE_RATING) 10V; ::OrcadTools::ShowProps::prepareCombinedLabel part C1 status')
        self.assertEqual(self.tcl.eval('set props(CAP_PACKAGE_VOLTAGE)'), 'CC0805/10V')



if __name__ == '__main__':
    unittest.main()
