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
    set lower [string tolower $c]
    radiobutton $w.justif.$lower -text $c -variable just \
        -relief flat -value $lower -anchor w \
        -command "$w.frame.list configure -justify \$just"
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

if {0} {
$w.frame.list insert 0 "Don't speculate, measure" "Waste not, want not" "Early to bed and early to rise makes a man healthy, wealthy, and wise" "Ask not what your country can do for you, ask what you can do for your country" "I shall return" "NOT" "A picture is worth a thousand words" "User interfaces are hard to build" "Thou shalt not steal" "A penny for your thoughts" "Fool me once, shame on you;  fool me twice, shame on me" "Every cloud has a silver lining" "Where there's smoke there's fire" "It takes one to know one" "Curiosity killed the cat" "Take this job and shove it" "Up a creek without a paddle" "I'm mad as hell and I'm not going to take it any more" "An apple a day keeps the doctor away" "Don't look a gift horse in the mouth" "Measure twice, cut once"
}

proc fileDialog {w} {
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