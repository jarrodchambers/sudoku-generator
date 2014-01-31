#!/usr/bin/perl

my @values, @digits, @choices, @puzzle, @solution;

$MAX_ITERATIONS = 5000;
$MAX_NON_BLANKS = 28;

#For each digit...
my $m, $n, $p, $row, $col;

# Generate the solution matrix

initializeArray();

for ($n = 0; $n < 3; $n++) {
   for ($p = 0; $p < 3; $p++) { 
      for ($m = 1; $m < 10; $m++) {
         $counter = 0;
         do {

            # If we're stuck, reset everything and start over

            $counter++;
            if ($counter > 500) {
               $n = $p = $m = 0; 
               initializeArray();
               next;
            }

            $thisrow = rand() * 3 + ($n * 3);
            $thiscol = rand() * 3 + ($p * 3);
         } while (($digits[$thisrow][$thiscol][$m-1] == 1) && 
                  ($values[$thisrow][$thiscol] != $m));
         putValue ($thisrow, $thiscol, $m);
         do {
         } while (checkValues());
      }
   }
}

printArray();

# Now create the puzzle


copySolution();

$iterations = 0;

do {
   $iterations++;
   initializeArray();
#   print "Iteration: $iterations\n";

   $nonblanks = 0;
   $nextdigit = 1;

   do {
      $thisrow = rand() * 9;
      my $thiscol = -1;
      do {
         $thiscol++;
      } while ($solution[$thisrow][$thiscol] != $nextdigit);
      $nextdigit = int((rand() * 9) + 1);
  
      if (!$puzzle[$thisrow][$thiscol]) {
         $puzzle[$thisrow][$thiscol] = $solution[$thisrow][$thiscol];
         $nonblanks++;
         putValue($thisrow, $thiscol, $solution[$thisrow][$thiscol]);
         do {
         } while (checkValues());
      }
   } while (!areWeDone() && ($nonblanks < $MAX_NON_BLANKS));

} while (!areWeDone() && ($iterations < $MAX_ITERATIONS));

if (areWeDone()) {
   printMatrix("puzzle", puzzle);
   printMatrix("solution", solution);
   print "Iterations: $iterations\n";
}
else
{
   print "Couldn't find a good puzzle\n";
}



# Go through the array and check for any squares which only have
# 1 possibility left.  Set the value for that square and eliminate
# options; return TRUE if any action was taken

sub checkValues
{
   my $x, $y, $z, $digit = 0;
   my $k, $l;
   my $result = 0;

#   printDigits();
#   printChoices();

   # Check for any squares which only have one remaining option

   $result = checkSimple();

#   for ($x = 0; $x < 9; $x++) {
#      for ($y = 0; $y < 9; $y++) {
#         if ($choices[$x][$y] == 1) {
#            print $x, " ", $y, "\n";
#            $result = 1;
#            while ($digits[$x][$y][$digit] == 1) {
#               $digit++;
#            }
#            putValue($x, $y, $digit+1);
#            $digit = 0;
##            print "Check value $x $y $digit\n";
#         }
#      }
#   }
#
   # Check for any 3x3 square with one remaining position
   # for one of the nine digits.  That's a bit confusing,
   # so just look at the code.

   for ($x = 0; $x < 3; $x++) {
      for ($y = 0; $y < 3; $y++) {
         # Do this for each 3x3 square with top left corner at (x, y)
         my $row, $col, $found = 0;
         my $left = $x*3;
         my $right = $$left+3;
         my $top = $y*3;
         my $bottom = $top+3;
OUTER:   for ($digit = 0; $digit < 9; $digit++) {
            for ($k = $left; $k < $right; $k++) {
               for ($l = $top; $l < $bottom; $l++) {
#                  if (!$values[$k][$l]){
                     if ($digits[$k][$l][$digit] == 0) {
                        $row = $k;
                        $col = $l;
                        $found++;
                     }
                     if ($found > 1) {
                        next OUTER;
                     }
#                  }
               }
            }
            # If there was only one place for this digit, fill it in
            if (($found == 1) && ($values[$row][$col] == 0)) {
               putValue($row, $col, $digit+1);
               $result = 1;
            }
         }

         checkTwins($left, $right, $top, $bottom);
      }
   }

#   print "checkValues returning ", $result, "\n";
   return $result;
}
            

# Put a value in a square, mark all the digits unavailable, and
# eliminate that digit as an option in the row, col and square

sub putValue
{
   my $row = shift(@_);
   my $col = shift(@_);
   my $digit = shift(@_);
   my $x;

   $values[$row][$col] = $digit;
   
   for ($x = 0; $x < 9; $x++) {
      $digits[$row][$col][$x] = 1;
   }
   $choices[$row][$col] = 0;
   eliminateOptions($row, $col);
} 
   

sub eliminateOptions
{
   my $row = shift(@_);
   my $col = shift(@_);

   my $current = $values[$row][$col];
   my $i, $j;

   # Can't have the same digit in this row or column
   for ($i = 0; $i < 9; $i++) {
      if ($digits[$i][$col][$current-1] == 0) {
         $digits[$i][$col][$current-1] = 1;
         $choices[$i][$col]--;
      }
      if ($digits[$row][$i][$current-1] == 0) {
         $digits[$row][$i][$current-1] = 1;
         $choices[$row][$i]--;
      }
   }
      
   my $top = $row - ($row % 3);
   my $left = $col - ($col % 3);

   # Can't have the same digit in this 3x3 square
   for ($i = $top; $i < $top + 3; $i++) {
      for ($j = $left; $j < $left + 3; $j++) {
         if ($digits[$i][$j][$current-1] == 0) {
            $digits[$i][$j][$current-1] = 1;
            $choices[$i][$j]--;
         }
      }
   }
#   print "Exiting eliminateOptions\n";
}
      
  

sub initializeArray()
{
   my $x, $y, $z;
   for ($x = 0; $x < 9; $x++) {
      for ($y = 0; $y < 9; $y++) {
         $values[$x][$y] = 0;
         $puzzle[$x][$y] = 0;
         $choices[$x][$y] = 9;
         for ($z = 0; $z < 9; $z++) {
            $digits[$x][$y][$z] = 0;
         }
      }
   }
}

sub printArray()
{
   my $x, $y, $z;
   for ($x = 0; $x < 9; $x++) {
      for ($y = 0; $y < 9; $y++) {
         print $values[$x][$y], " ";
      }
      print "\n";
   }
}

sub printDigits()
{
   my $x, $y, $z;
   for ($x = 0; $x < 9; $x++) {
      for ($y = 0; $y < 9; $y++) {
         for ($z = 0; $z < 9; $z++) {
            print $x, " ", $y, " digit=", $z+1, " ", $digits[$x][$y][$z], "\n";
         }
      }
      print "\n";
   }
}

sub printChoices()
{
   my $x, $y, $z;
   for ($x = 0; $x < 9; $x++) {
      for ($y = 0; $y < 9; $y++) {
         print $choices[$x][$y], " ";
      }
      print "\n";
   }
}

sub areWeDone ()
{
   my $x, $y;
   for ($x = 0; $x < 9; $x++) {
      for ($y = 0; $y < 9; $y++) {
         if ($choices[$x][$y]) {
            return 0;
         }
      }
   }
   return 1;
}

# Given a 3x3 square (0 - 8) check
# for "twins", two squares with the
# same two choices

sub checkTwins ()
{
   my $left = shift(@_);
   my $right = shift(@_);
   my $top = shift(@_);
   my $bottom = shift(@_);

#   print "Debug: $left $right $top $bottom\n";
 
   my @twins = ();
   my $i = 0, $remaining = 0;

   for ($q = $left; $q < $right; $q++) {
      for ($r = $top; $r < $bottom; $r++) {
         $remaining += $choices[$q][$r];
      }
   }

   if ($remaining < 5) { return; }

   for ($q = $left; $q < $right; $q++) {
      for ($r = $top; $r < $bottom; $r++) {
         if ($choices[$q][$r] == 2) {
            $twins[$i] = "";
            for ($z = 0; $z < 9; $z++) {
               if (!$digits[$q][$r][$z]) {
                  $twins[$i] .= ($z+1);
               }
            }
            $twins[$i] .= $q;
            $twins[$i] .= $r;
#            print "Debug: $twins[$i]\n";
            $i++;
         }
      }
   }

   if ($#twins > 0) {
      sort(@twins);
      # If we find "twins", 2 squares with the same 2 numbers as the only choices
      # then eliminate those numbers from all the other squares in that 3x3
      for ($xx = 1; $xx < $#twins + 1; $xx++) {
         if (substr($twins[$xx-1],0,2) eq substr($twins[$xx],0,2)) {
            my $first = substr($twins[$xx],0,1) - 1;
            my $second = substr($twins[$xx],1,1) - 1;
            my $x1 = substr($twins[$xx-1],2,1);
            my $y1 = substr($twins[$xx-1],3,1);
            my $x2 = substr($twins[$xx],2,1);
            my $y2 = substr($twins[$xx],3,1);
            for ($mm = $left; $mm < $left + 3; $mm++) {
               for ($nn = $top; $nn < $top + 3; $nn++) {
                  if (($mm != $x1 || $nn != $y1) && ($mm != $x2 || $nn != $y2) && !$values[$mm][$nn]) {
                     if ($digits[$mm][$nn][$first] == 0) {
                        $digits[$mm][$nn][$first] = 1;
                        $choices[$mm][$nn]--;
                     }
                     if ($digits[$mm][$nn][$second] == 0) {
                        $digits[$mm][$nn][$second] = 1;
                        $choices[$mm][$nn]--;
                     }
                  }
               }
            }

            if ($x1 == $x2) {
               for ($nn = 0; $nn < 9; $nn++) {
                  if (!$values[$x1][$nn] && ($nn != $y1) && ($nn != $y2)) {
                     if ($digits[$x1][$nn][$first] == 0) {
                        $digits[$x1][$nn][$first] = 1;
                        $choices[$x1][$nn]--;
                     }
                     if ($digits[$x1][$nn][$second] == 0) {
                        $digits[$x1][$nn][$second] = 1;
                        $choices[$x1][$nn]--;
                     }
                  }
               }
            }

            if ($y1 == $y2) {
               for ($mm = 0; $mm < 9; $mm++) {
                  if (!$values[$mm][$y1] && ($mm != $x1) && ($mm != $x2)) {
                     if ($digits[$mm][$y1][$first] == 0) {
                        $digits[$mm][$y1][$first] = 1;
                        $choices[$mm][$y1]--;
                     }
                     if ($digits[$mm][$y1][$second] == 0) {
                        $digits[$mm][$y1][$second] = 1;
                        $choices[$mm][$y1]--;
                     }
                  }
               }
            }
         }
      }
   }

   return;
}

sub solutionToString()
{
   my $x, $y, $str;
   $str = "";
   for ($x = 0; $x < 9; $x++) {
      for ($y = 0; $y < 9; $y++) {
         $str .= $solution[$x][$y];
      }
   }
   return $str;
}

sub copySolution()
{
   my $x, $y;
   for ($x = 0; $x < 9; $x++) {
      for ($y = 0; $y < 9; $y++) {
         $solution[$x][$y] = $values[$x][$y];
      }
   }
}

sub printMatrix
{
   my $type = shift(@_);
   my (@matrix) = @{(shift)};

   my $title, $link;

   my @classes=(["tl", "tm", "tr"], ["ml", "m", "mr"], ["bl", "bm", "br"]);

   my $answer = solutionToString();

   my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
   $year += 1900;
   $mon++;
   if ($mday < 10) { $mday = "0$mday";}
   if ($mon < 10) { $mon = "0$mon";}
   $datestamp = "$mday$mon$year";

   if ($type eq "solution") {
      open(SUDOKU, ">solution_$datestamp.htm") || die "Can't open file: $!\n";
      $title = "Today\'s Solution";
      $link="Return to today\'s \<a href=sudoku_$datestamp\.htm\>puzzle\<\/a\>";
   }
   else {
      open(SUDOKU, ">sudoku_$datestamp.htm");
      $title = "Today\'s Sudoku";
      $link="Click \<a href=solution_$datestamp\.htm\>here\<\/a\> for solution";
   }

   my $date = localtime();
   $date =~ s/\d{1,2}:.*$//;
   $date =~ s/\s{1,}/ /g;
   $date =~ s/\s{1,}$//g;

   $date .= " $year";

   print SUDOKU <<ENDHTML;

<HEAD>
<SCRIPT>
function checkAnswer() {
   var i, j, s, val, answer, wrong, blank;
   answer = "$answer";
   s = "";
   wrong = blank = 0;
   for (i = 0; i < 9; i++) {
      for (j = 0; j < 9; j++) {
         val = document.puzzle["m"+i+j].value;
         val ? s += val : s += "x";
      }
   }
   i = 0;
   while (i < answer.length) {
      if (s.charAt(i) == "x") { blank++; }
      else {
         if (s.charAt(i) != answer.charAt(i)) { wrong++; }
      }
      i++;
   }
   if (wrong) {
      alert("You have "+wrong+" squares filled in incorrectly");
   }
   else {
      if (!blank) {
         alert("You got it!");
      }
      else {
         alert("So far so good!  Keep going.");
      }
   }
   return true;
}

function checkValue(square) {
   var t = document.puzzle[square].value;
   if (isNaN(t) || t < 1 || t > 9){
      document.puzzle[square].value = "";
   }
}
   
</SCRIPT>

<style type="text/css">
   table {border-collapse: collapse;}
   td {font-family: verdana;
       font-weight: bold;
       padding-left: 5pt;
       padding-right: 5pt;
       padding-top: 5pt;
       padding-bottom: 5pt;
       border: solid;
       border-color: blue;
       border-width: 2px;}
   h1 { font-family: Verdana;
        font-size: 1.5em;}
   .tl {border-top-width: 4px;
        border-left-width: 4px;}
   .tm {border-top-width: 4px;}
   .tr {border-top-width: 4px;
        border-right-width: 4px;}
   .ml {border-left-width: 4px;}
   .mr {border-right-width: 4px;}
   .bl {border-left-width: 4px;
        border-bottom-width: 4px;}
   .bm {border-bottom-width: 4px;}
   .br {border-right-width: 4px;
        border-bottom-width: 4px;}
   input.sdkuv, input.sdkuf {font-family: verdana;
          font-size: 0.8em;
          border: none;
          padding-top: 0.3em;
          width: 1.5em;
          height: 1.5em;
          text-align: center;}
   input.sdkuv {color: #FF00FF;}
   div#button {padding-top: 1.0em;}

</style>
</HEAD>
<BODY>
<BR>
<H1 align=center>$date</H1>
<FORM NAME="puzzle">
<TABLE align=center>

ENDHTML

   my $x, $y, $z;
   $z = 0;
   for ($x = 0; $x < 9; $x++) {
      print SUDOKU "<TR>\n";
      for ($y = 0; $y < 9; $y++) {
         $class = $classes[$x % 3][$y % 3];
         if ($matrix[$x][$y]) {
            print SUDOKU "<TD class=$class><INPUT TYPE=TEXT READONLY MAXLENGTH=1 VALUE=\"$matrix[$x][$y]\" NAME=\"m$x$y\" CLASS=\"SDKUF\"><\/TD>\n";
            $z++;
         }
         else {
            print SUDOKU "<TD class=$class><INPUT TYPE=TEXT MAXLENGTH=1 VALUE=\"\" NAME=\"m$x$y\" CLASS=\"SDKUV\" onChange=\"checkValue(\'m$x$y\')\"><\/TD>\n";
         }
      }
      print SUDOKU "\n<\/TR>\n";
   }
   print SUDOKU "<\/TABLE>\n";
   if ($type ne "solution") {
      print SUDOKU "<div id=\"button\" ALIGN=CENTER>\n";
      print SUDOKU "<INPUT TYPE=submit VALUE=\"Check Answer\" onClick =\"checkAnswer(); return false\">\n";
      print SUDOKU "<\/div>\n";
   }
   print SUDOKU <<FOOTER;

</FORM>
<H3 align=center>$link</H3>
</BODY>

FOOTER
   
}

sub checkSimple {

   my $x, $y, $z, $digit = 0;
   my $result = 0;
   
   for ($x = 0; $x < 9; $x++) {
      for ($y = 0; $y < 9; $y++) {
         if ($choices[$x][$y] == 1) {
#            print $x, " ", $y, "\n";
            $result = 1;
            while ($digits[$x][$y][$digit] == 1) {
               $digit++;
            }
            putValue($x, $y, $digit+1);
            $digit = 0;
#            print "Check value $x $y $digit\n";
         }
      }
   }

   return $result;
}
