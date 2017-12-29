source txtaudio_mapper.tcl

#-----------------------------------------
text      .t -font [list {Times New Roman} 18] -yscrollcommand {.s set}
scrollbar .s -command        {.t yview}
pack .s -side right -fill y
pack .t -side left -fill both -expand 1

bind .t <ButtonRelease-1> {
    set idx [.t index insert] 
    set sndidx [s1 current_position]
	TxtAudioModel::update_mapper "$idx $sndidx"
	
	set lastidx [$w.frame.list size]
	incr lastidx -1
	$w.frame.list delete 0 $lastidx
	foreach segment [TxtAudioModel::gen_segments] {
        $w.frame.list insert end $segment
	}	
}

lappend auto_path C:/textAudioSync/bin/windows
package require snack 
#-----------------------------------------

set w .sayings
catch {destroy $w}
toplevel $w
wm title $w "Listbox Demonstration (well-known sayings)"
wm iconname $w "sayings"
#positionWindow $w

label $w.msg -wraplength 4i -justify left -text "The listbox below contains a collection of well-known sayings.  You can scan the list using either of the scrollbars or by dragging in the listbox window with button 2 pressed."
pack $w.msg -side top

labelframe $w.justif -text Justification
foreach c {Left Center Right} {
    global g_sound
    set lower [string tolower $c]
    radiobutton $w.justif.$lower -text $c -variable just \
        -relief flat -value $lower -anchor w \
        -command "stop_audio"
    pack $w.justif.$lower -side left -pady 2 -fill x
}
pack $w.justif

button $w.but -text "Load" -command "fileDialog $w"
pack $w.but -side left

frame $w.frame -borderwidth 10
pack $w.frame -side top -expand yes -fill both -padx 1c


scrollbar $w.frame.yscroll -command "$w.frame.list yview"
scrollbar $w.frame.xscroll -orient horizontal \
    -command "$w.frame.list xview"
listbox $w.frame.list -width 20 -height 10 -setgrid 1 \
    -yscroll "$w.frame.yscroll set" -xscroll "$w.frame.xscroll set"

grid $w.frame.list -row 0 -column 0 -rowspan 1 -columnspan 1 -sticky news
grid $w.frame.yscroll -row 0 -column 1 -rowspan 1 -columnspan 1 -sticky news
grid $w.frame.xscroll -row 1 -column 0 -rowspan 1 -columnspan 1 -sticky news
grid rowconfig    $w.frame 0 -weight 1 -minsize 0
grid columnconfig $w.frame 0 -weight 1 -minsize 0

bind $w.frame.list <ButtonRelease-1> {
    set tokens [selection get]
	set start_txt [lindex $tokens 0]
	set start_audio [lindex $tokens 1]
	set end_txt [lindex $tokens 2]
	set end_audio [lindex $tokens 3]
	
    # Underline the word in the text box.
    .t tag delete t_underline
    .t tag configure t_underline -underline 1
    .t tag add t_underline $start_txt $end_txt
    .t see $start_txt
}

bind $w.frame.list <Double-1> {
    set tokens [selection get]
	set start_txt [lindex $tokens 0]
	set start_audio [lindex $tokens 1]
	set end_txt [lindex $tokens 2]
	set end_audio [lindex $tokens 3]
	global g_sound
	$g_sound stop
	$g_sound play -start $start_audio -blocking 0
}

bind $w.frame.list <Control-1> {
    set tokens [selection get]
	set start_txt [lindex $tokens 0]
	set start_audio [lindex $tokens 1]
	set end_txt [lindex $tokens 2]
	set end_audio [lindex $tokens 3]
	global g_sound
	$g_sound stop

	TxtAudioModel::delete_mapper "$end_txt $end_audio"
	
	set lastidx [$w.frame.list size]
	incr lastidx -1
	$w.frame.list delete 0 $lastidx
	foreach segment [TxtAudioModel::gen_segments] {
        $w.frame.list insert end $segment
	}    
}

proc fileDialog {w} {
    global g_sound
	
    #   Type names		Extension(s)	Mac File Type(s)
    #
    #---------------------------------------------------------
    set types {
	{"Sound Files"		{.mp3 .wav}	}
    }

	set filename [tk_getOpenFile -filetypes $types]
	if {$filename == ""} {
	    return
	}
	
	set prefix_dot "."
	set prefix_txt "txt"
	set prefix_dat "dat"
    
	set idx [string last $prefix_dot $filename]
	if {$idx == -1} {
	    puts "$filename has no dot!"
		return
	} else {
	    set filenameroot [string range $filename 0 $idx]
	}
	
	if {![file exists $filenameroot$prefix_txt]} {
	    puts "$filename has no text file!"
		return	
	}
	
	snack::sound s1 -file $filename
	set g_sound s1
	set f [open $filenameroot$prefix_txt r]
	set data [read $f]
	close $f	
	.t delete 0.0 end
	.t insert 0.0 $data
	
	if {![file exists $filenameroot$prefix_dat]} {
	    set end_txt [.t index end]
		set end_audio [s1 lastIndex]
		TxtAudioModel::Init $filename $filenameroot$prefix_txt $filenameroot$prefix_dat $end_txt $end_audio
	} else {
		TxtAudioModel::Reload $filename $filenameroot$prefix_txt $filenameroot$prefix_dat	
	}
	foreach segment [TxtAudioModel::gen_segments] {
        $w.frame.list insert end $segment
	}
}

proc stop_audio {} {
    global g_sound
	
	$g_sound stop
	return
}