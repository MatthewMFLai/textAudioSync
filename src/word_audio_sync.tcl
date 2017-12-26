text      .t -font [list {Times New Roman} 18] -yscrollcommand {.s set}
scrollbar .s -command        {.t yview}
pack .s -side right -fill y
pack .t -side left -fill both -expand 1

set fd [open text_audio_capture.dat w]
bind .t <ButtonRelease-1> {
    set idx [.t index insert] 
    set sndidx [s1 current_position]
	puts "$idx $sndidx"
	puts $fd "$idx $sndidx"
}

set filename "test.out"
set f [open $filename r]
set data [read $f]
close $f

.t delete 0.0 end
.t insert 0.0 $data

lappend auto_path C:/textAudioSync/bin/windows
package require snack 
set mp3file 26574-01.mp3
snack::sound s1 -file $mp3file
