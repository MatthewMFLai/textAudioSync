source txtaudio_mapper.tcl

#-----------------------------------------
text      .t -font [list {Times New Roman} 18] -yscrollcommand {.s set}
scrollbar .s -command        {.t yview}
pack .s -side right -fill y
pack .t -side left -fill both -expand 1

bind .t <ButtonRelease-1> {
    global g_sound
	global g_idx
	
    if {[snack::audio active]} {
		stop_audio
	}
	set idx [.t index insert] 
	set g_idx [search_segments $idx]
	if {$g_idx > -1} {
	    audio_callback
    }	
}

lappend auto_path C:/textAudioSync/bin/windows
package require snack 
set g_sound ""
#-----------------------------------------

set w .sayings
catch {destroy $w}
toplevel $w
wm title $w "Text Audio Sync Player"
wm iconname $w "sayings"

button $w.but -text "Load" -command "fileDialog $w"
button $w.but2 -text "Stop" -command "stop_audio"
pack $w.but $w.but2 -side top

button $w.but3 -text "Exit" -command "exit"
pack $w.but3 -side top

proc fileDialog {w} {
    global g_sound
	global g_segments
	
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
	
	if {$g_sound != ""} {
	    $g_sound destroy
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
	
	set g_segments [TxtAudioModel::gen_segments]
	return
}

proc stop_audio {} {
    global g_sound
	
	$g_sound stop
	# Remove underline.
    .t tag delete t_underline
	return
}

proc search_segments {cursor} {
    global g_segments	

	set rc 0
    foreach segment $g_segments {
	    set start_txt [lindex $segment 0]
	    set end_txt [lindex $segment 2]	
		if {[.t compare $start_txt < $cursor] && [.t compare $cursor <= $end_txt]} {
		    puts "$start_txt $cursor $end_txt"
	        set start_audio [lindex $segment 1]
            return $rc
        }
		incr rc
    }
	return -1
}

proc audio_callback {} {
    global g_segments
    global g_idx
    global g_timelist
    global g_sound

	# Remove underline.
    .t tag delete t_underline
	
    if {$g_idx == [llength $g_segments]} {
        return
    }
    set tokens [lindex $g_segments $g_idx]
    set start [lindex $tokens 1]
    set stop [lindex $tokens 3]
    set start_txt [lindex $tokens 0]
    set stop_txt [lindex $tokens 2]
	incr g_idx
	
    .t tag configure t_underline -underline 1
    .t tag add t_underline $start_txt $stop_txt
    .t see $start_txt
	
    $g_sound play -start $start -end $stop -blocking 0 -command audio_callback
    return    
}
