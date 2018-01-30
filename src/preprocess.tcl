#-----------------------------------------
text      .t -font [list {Times New Roman} 18] -yscrollcommand {.s set}
scrollbar .s -command        {.t yview}
pack .s -side right -fill y
pack .t -side left -fill both -expand 1

bind .t <ButtonRelease-1> {
    global g_state
    if {$g_state == "STATE_PAUSE"} {
	    global g_segments
        global g_datafile
		global g_delay

		set idx [.t index insert] 
		set sndidx [lindex $g_delay 0]
        lappend g_segments "$idx $sndidx"
		
		set g_delay [lrange $g_delay 1 end]
		if {$g_delay != ""} {
			sound_refresh
			resume_audio $sndidx [lindex $g_delay 0]
			
			set fd [open $g_datafile a]
			puts $fd "$idx $sndidx"
			close $fd
			
			set lastidx [$w.frame.list size]
			incr lastidx -1
			$w.frame.list delete 0 $lastidx
			foreach segment $g_segments {
				$w.frame.list insert end $segment
			}
		}
    }	
}

lappend auto_path C:/textAudioSync/bin/windows
package require snack 
set g_sound ""
#-----------------------------------------

global w
set w .sayings
catch {destroy $w}
toplevel $w
wm title $w "Text Audio Sync Controller"
wm iconname $w "sayings"

button $w.but -text "Load" -command "fileDialog $w"
button $w.but2 -text "Stop" -command "stop_audio"
pack $w.but $w.but2 -side top

frame $w.frame -borderwidth 10
pack $w.frame -side top -expand yes -fill both -padx 1c


scrollbar $w.frame.yscroll -command "$w.frame.list yview"
scrollbar $w.frame.xscroll -orient horizontal \
    -command "$w.frame.list xview"
listbox $w.frame.list -width 30 -height 30 -setgrid 1 \
    -yscroll "$w.frame.yscroll set" -xscroll "$w.frame.xscroll set"

grid $w.frame.list -row 0 -column 0 -rowspan 1 -columnspan 1 -sticky news
grid $w.frame.yscroll -row 0 -column 1 -rowspan 1 -columnspan 1 -sticky news
grid $w.frame.xscroll -row 1 -column 0 -rowspan 1 -columnspan 1 -sticky news
grid rowconfig    $w.frame 0 -weight 1 -minsize 0
grid columnconfig $w.frame 0 -weight 1 -minsize 0

button $w.but3 -text "Exit" -command "exit"
pack $w.but3 -side top

proc fileDialog {w} {
    global g_sound
	global g_segments
	global g_filename
	global g_datafile
	global g_delay
	
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
	set prefix_labels "labels"
	set prefix_dat "dat"
    
	set idx [string last $prefix_dot $filename]
	if {$idx == -1} {
	    puts "$filename has no dot!"
		return
	} else {
	    set filenameroot [string range $filename 0 $idx]
	}

	if {![file exists $filenameroot$prefix_labels]} {
	    puts "$filenameroot$prefix_labels not found"
	    puts "$filename has no label file!"
		return	
	}
	
	if {![file exists $filenameroot$prefix_txt]} {
	    puts "$filename has no text file!"
		return	
	}
	set g_filename $filename
	
	if {$g_sound != ""} {
	    $g_sound destroy
	}
	snack::sound s1 -load $filename
	set g_sound s1
	set f [open $filenameroot$prefix_txt r]
	set data [read $f]
	close $f	
	.t delete 0.0 end
	.t insert 0.0 $data

	set g_segments ""
	set g_datafile $filenameroot$prefix_dat
	convert_delay $filenameroot$prefix_labels
	
	resume_audio 0 [lindex $g_delay 0]
	
	return
}

proc convert_delay {delayfile} {
    global g_delay
	global g_sound
	
	# Compute the delay period between each potential silence time marker.
	# File data should look like
    # 2.882766	2.882766	S
    # 4.948073	4.948073	S
    # 10.016553	10.016553	S
	
	# make sure the g_sound is the sound object constructed with the -load option,
	# or else the info returns nothing useful.
    set g_delay ""
	set totaltime [$g_sound length -unit SECONDS]
	set totalsamples [lindex [$g_sound info] 0]
	set fd [open $delayfile r]
	while {[gets $fd line] > -1} {
        set time_cur [lindex $line 0]
		set time_cur [expr ($time_cur * $totalsamples) / $totaltime]
		lappend g_delay [expr int($time_cur)]
	}
	close $fd
}

proc pause_audio {} {
    global g_state
	
	set g_state STATE_PAUSE
	puts "click?"
	return
}

proc stop_audio {} {
    global g_sound
	
	$g_sound stop
	return
}

proc resume_audio {start_idx stop_idx} {
    global g_sound
	global g_delay
	global g_state

	if {$g_delay == ""} {
	    return
	}
	set g_state STATE_PLAY
	$g_sound play -start $start_idx -end $stop_idx -blocking 0 -command "pause_audio"
}

proc sound_refresh {} {
    global g_sound
	global g_filename
	
	if {$g_sound != ""} {
	    $g_sound destroy
	}
	snack::sound $g_sound -file $g_filename
	return
}