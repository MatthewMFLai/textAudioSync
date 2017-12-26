set fd [open EXTRAORDINARY_ADVENTURES_OF_ARSENE_LUPIN.txt r]
set fd2 [open test.out w]
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
