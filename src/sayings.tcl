source txtaudio_mapper.tcl

#-----------------------------------------
text      .t -font [list {Times New Roman} 18] -yscrollcommand {.s set}
scrollbar .s -command        {.t yview}
pack .s -side right -fill y
pack .t -side left -fill both -expand 1

bind .t <ButtonRelease-1> {
    if {[snack::audio active]} {
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

bind $w.frame.list <Control-1> {
    set tokens [selection get]
	set start_txt [lindex $tokens 0]
	set start_audio [lindex $tokens 1]
	set end_txt [lindex $tokens 2]
	set end_audio [lindex $tokens 3]
	
	global g_sound
	$g_sound stop
	$g_sound play -start $start_audio -end $end_audio -blocking 0 -command {set g_sentence_adjust(accept_slider) 1}
	
	adjustment_launch $end_txt 100000 $end_audio ".hscale"
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

bind $w.frame.list <Control-3> {
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
	
	set lastidx [$w.frame.list size]
	if {$lastidx} {
		incr lastidx -1
		$w.frame.list delete 0 $lastidx
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

proc adjustment_launch {end_txt interval end_audio win_name} {
    global g_sentence_adjust
	
	if {[info exists g_sentence_adjust]} {
	    unset g_sentence_adjust
	}
	set g_sentence_adjust(accept_slider) 0
	set g_sentence_adjust(debounce_check) 0
	set g_sentence_adjust(debounce_interval_sec) 2
	
	set g_sentence_adjust(end_txt) $end_txt
	set g_sentence_adjust(interval) $interval
	set g_sentence_adjust(end_audio) $end_audio
	set g_sentence_adjust(v) $win_name
	
	set v $win_name
	catch {destroy $v}
	toplevel $v
	wm title $v "Sentence Adjustment"

	frame $v.frame -borderwidth 10
	pack $v.frame -side top -fill x

	scale $v.frame.scale -orient horizontal -length 30020 -from -15000 -to 15000 \
		-command {adjustment_debounce} -tickinterval 3000
	pack $v.frame.scale -side bottom -expand yes -anchor n
	$v.frame.scale set 0
	
	button $v.b1 -text "Save" -width 10 \
		-command "adjustment_save $v"
	button $v.b2 -text "Quit" -width 10 \
		-command {adjustment_destroy}
	pack $v.b1 $v.b2 -side left -expand yes -pady 2
}

proc adjustment_debounce {decrement} {
    global g_sentence_adjust
	
    if {$g_sentence_adjust(accept_slider)} {
	    if {$g_sentence_adjust(debounce_check) == 0} {
		    set g_sentence_adjust(debounce_check) 1
			set debounce_interval $g_sentence_adjust(debounce_interval_sec)
			set g_sentence_adjust(debounce_id) [after $debounce_interval adjustment_debounce_check]
		}
		set g_sentence_adjust(decrement) $decrement
		set g_sentence_adjust(timestamp) [clock seconds]
	}
}

proc adjustment_debounce_check {} {
    global g_sentence_adjust

	set debounce_interval $g_sentence_adjust(debounce_interval_sec)
    if {[expr [clock seconds] - $g_sentence_adjust(timestamp)] < $debounce_interval} {
		set g_sentence_adjust(debounce_id) [after $debounce_interval adjustment_debounce_check]	    
	    return
	}
	set g_sentence_adjust(accept_slider) 0
	set g_sentence_adjust(debounce_check) 0

    adjustment_replay $g_sentence_adjust(decrement)
	return
}

proc adjustment_replay {decrement} {
	global g_sound
    global g_sentence_adjust
	
	$g_sound stop
	set interval $g_sentence_adjust(interval)
	set curr_stop [expr $g_sentence_adjust(end_audio) + $decrement]
	set curr_start [expr $curr_stop - $interval]
	$g_sound play -start $curr_start -end $curr_stop -blocking 1
	
	after 500
	
	set next_start [expr $curr_stop + 1]
	set next_stop [expr $next_start + $interval]
	$g_sound play -start $next_start -end $next_stop -blocking 1
	
    set g_sentence_adjust(accept_slider) 1
	return
}

proc adjustment_save {v} {
    global g_sentence_adjust
	global w
	
	set decrement [$v.frame.scale get]
	TxtAudioModel::delete_mapper "$g_sentence_adjust(end_txt) $g_sentence_adjust(end_audio)"
	TxtAudioModel::update_mapper "$g_sentence_adjust(end_txt) [expr $g_sentence_adjust(end_audio) + $decrement]"
	
	set lastidx [$w.frame.list size]
	incr lastidx -1
	$w.frame.list delete 0 $lastidx
	foreach segment [TxtAudioModel::gen_segments] {
		$w.frame.list insert end $segment
	}
	
	adjustment_destroy
}

proc adjustment_destroy {} {
    global g_sentence_adjust
	
	catch {destroy $g_sentence_adjust(v)}
    return
}