#!/bin/sh
# the next line restarts using wish \
exec wish8.4 "$0" "$@"


if {[string equal $tcl_platform(platform) "windows"]} {
 package require registry
 set script [package ifneeded registry [package provide registry]]
 set dll [lindex $script 1]
 set tcllibdir [file dirname [file dirname $dll]]

 set dest $tcllibdir/snack2.2
 
 file mkdir $dest

 file copy -force bin/windows/libsnack.dll    $dest
 file copy -force bin/windows/libsound.dll    $dest
 file copy -force bin/windows/snack.tcl       $dest
 file copy -force bin/windows/pkgIndex.tcl    $dest
 file copy -force bin/windows/snackstub22.lib $dest
 file copy -force bin/windows/libsnackogg.dll $dest
 file copy -force bin/windows/libsnacksphere.dll $dest
}

tk_messageBox -message "Installed Snack v2.2.10 in $tcllibdir"

exit
