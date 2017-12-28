proc audio_callback {} {
    global g_idx
    global g_timelist
    global g_sound

    puts $g_idx
    if {[expr $g_idx + 1 ] == [llength $g_timelist]} {
        return
    }

    set start [lindex $g_timelist $g_idx]
    incr start
    incr g_idx
    set stop [lindex $g_timelist $g_idx]
     
    $g_sound play -start $start -end $stop -blocking 0 -command audio_callback
    return    
}
