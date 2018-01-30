set infile [lindex $argv 0]
set outfile [lindex $argv 1]

set fd [open $infile r]
set fd2 [open $outfile w]
set paragraph ""
while {[gets $fd line] > -1} {
   if {$line == ""} {
     if {$paragraph != ""} {
         puts $fd2 [string range $paragraph 0 end-1]
	 puts $fd2 ""
         set paragraph ""
     }
   } else {
     append paragraph $line
     append paragraph " "
   }
}
if {$paragraph != ""} {
     puts $fd2 [string range $paragraph 0 end-1]
}
close $fd
close $fd2
