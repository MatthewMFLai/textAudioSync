# Copyright (C) 2017 by Matthew Lai, email : mmlai@sympatico.ca
#
# The author  hereby grants permission to use,  copy, modify, distribute,
# and  license this  software  and its  documentation  for any  purpose,
# provided that  existing copyright notices  are retained in  all copies
# and that  this notice  is included verbatim  in any  distributions. No
# written agreement, license, or royalty  fee is required for any of the
# authorized uses.  Modifications to this software may be copyrighted by
# their authors and need not  follow the licensing terms described here,
# provided that the new terms are clearly indicated on the first page of
# each file where they apply.
#
# IN NO  EVENT SHALL THE AUTHOR  OR DISTRIBUTORS BE LIABLE  TO ANY PARTY
# FOR  DIRECT, INDIRECT, SPECIAL,  INCIDENTAL, OR  CONSEQUENTIAL DAMAGES
# ARISING OUT  OF THE  USE OF THIS  SOFTWARE, ITS DOCUMENTATION,  OR ANY
# DERIVATIVES  THEREOF, EVEN  IF THE  AUTHOR  HAVE BEEN  ADVISED OF  THE
# POSSIBILITY OF SUCH DAMAGE.
#
# THE  AUTHOR  AND DISTRIBUTORS  SPECIFICALLY  DISCLAIM ANY  WARRANTIES,
# INCLUDING,   BUT   NOT  LIMITED   TO,   THE   IMPLIED  WARRANTIES   OF
# MERCHANTABILITY,  FITNESS   FOR  A  PARTICULAR   PURPOSE,  AND
# NON-INFRINGEMENT.  THIS  SOFTWARE IS PROVIDED  ON AN "AS  IS" BASIS,
# AND  THE  AUTHOR  AND  DISTRIBUTORS  HAVE  NO  OBLIGATION  TO  PROVIDE
# MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
namespace eval TxtAudioModel {

variable m_txt_file
variable m_audio_file
variable m_dat_file
variable m_mapper

proc Init {txt audio dat end_txt end_audio} {
    variable m_txt_file
    variable m_audio_file
    variable m_dat_file
    variable m_mapper

	if {![file exists $txt]} {
	    return
	}
	set m_txt_file $txt
	
	if {![file exists $audio]} {
	    return
	}	
	set m_audio_file $audio
	
	if {[file exists $dat]} {
	    return
	}
	set m_dat_file $dat
	set fd [open $m_dat_file w]
	puts $fd "$end_txt $end_audio"
	close $fd
	
	if {[info exists m_mapper]} {
	    unset m_mapper
	}
	array set m_mapper {}
	
	set fd [open $m_dat_file r]
	while {[gets $fd line] > -1} {
	    # Line format is 
		# <text location in text widget> <audio time sample value>
	    set m_mapper([lindex $line 1]) [lindex $line 0]
	}
	close $fd

    return
}

proc Reload {txt audio dat} {
    variable m_txt_file
    variable m_audio_file
    variable m_dat_file
    variable m_mapper

	if {![file exists $txt]} {
	    return
	}
	set m_txt_file $txt
	
	if {![file exists $audio]} {
	    return
	}	
	set m_audio_file $audio
	
	if {![file exists $dat]} {
	    return
	}
	set m_dat_file $dat
	
	if {[info exists m_mapper]} {
	    unset m_mapper
	}
	array set m_mapper {}
	
	set fd [open $m_dat_file r]
	while {[gets $fd line] > -1} {
	    # Line format is 
		# <text location in text widget> <audio time sample value>
	    set m_mapper([lindex $line 1]) [lindex $line 0]
	}
	close $fd

    return
}

proc update_mapper {endpt} {
	# Endpt format is 
    # {<text location in text widget> <audio time sample value>}
    variable m_dat_file
    variable m_mapper

	set end_txt [lindex $endpt 0]
	set end_audio [lindex $endpt 1]
	set timelist [lsort -integer [array names m_mapper]]
	if {[lsearch $timelist $end_audio] > -1} {
	    # Ignore duplicate
		return
	} else {
	    set m_mapper($end_audio) $end_txt
	}
	
    set fd [open $m_dat_file w]
    foreach point [lsort -integer [array names m_mapper]] {
	    puts $fd "$m_mapper($point) $point"
	}
    close $fd
	
    return
}

proc delete_mapper {endpt} {
	# Endpt format is 
    # {<text location in text widget> <audio time sample value>}
    variable m_dat_file
    variable m_mapper

	set end_audio [lindex $endpt 1]
	set timelist [lsort -integer [array names m_mapper]]
	if {[info exists m_mapper($end_audio)]} {
	    unset m_mapper($end_audio)
	}
	
    set fd [open $m_dat_file w]
    foreach point [lsort -integer [array names m_mapper]] {
	    puts $fd "$m_mapper($point) $point"
	}
    close $fd
	
    return
}

proc gen_segments {} {
	# Segment format is 
    # {<begin text location in text widget> <begin audio time sample value>
    # <end text location in text widget> <end audio time sample value>}
    variable m_mapper

	set rc ""
	set begin_txt 0.0
	set begin_audio 0
	
	foreach timevalue [lsort -integer [array names m_mapper]] {
	    set end_txt $m_mapper($timevalue)
		set end_audio $timevalue
		
		lappend rc "$begin_txt $begin_audio $end_txt $end_audio"
		set begin_txt $end_txt
		set begin_audio [expr $end_audio + 1]	
	}	
    return $rc
}
	
}

