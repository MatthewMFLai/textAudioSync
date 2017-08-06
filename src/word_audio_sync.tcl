text      .t -yscrollcommand {.s set}
scrollbar .s -command        {.t yview}
pack .s -side right -fill y
pack .t -side left -fill both -expand 1

bind .t <ButtonRelease-1> {
    set idx [.t index insert] 
    set sndidx [s1 current_position]
	puts "$idx $sndidx"
}

set filename "scandall-in-bohemia"
set f [open $filename r]
set data [read $f]
close $f

.t delete 0.0 end
.t insert 0.0 $data

lappend auto_path C:/textAudioync/bin/Windows
package require sound
set mp3file 9551-3201.mp3
snack::sound s1 -file $mp3file