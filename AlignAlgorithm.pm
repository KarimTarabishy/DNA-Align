package AlignAlgorithm
{
    use strict;
    use Moose;
    use DpAlignment;
    use List::Util qw[min max];

    has 'name'=> ( is => 'rw' );
    has 'score' => (is=>'rw');

    has 'global'=> (is =>'rw');
    has 'semi'=> (is =>'rw');
    has 'local'=> (is =>'rw');

    #
    # Get the score for a gap
    #
    # Input:
    #   - string: letter matched with the gap
    #   - int: gap type bit set
    # Returns:
    #   - int: score
    #
    sub score_gap{
        my $self = shift;
        my $letter = shift;
        my $gap_type = shift;

        if(($gap_type & DpAlignment->GAP_INITAL) and defined $self->local)
        {
            return 0;
        }

        if(($gap_type & DpAlignment->GAP_TERMINAL) and defined $self->semi)
        {
            return $self->score->{'term_gap'};
        }

        return $self->score->{'int_gap'};
    }

    #
    # Get the score for a miss
    #
    # Input:
    #   - string: first letter
    #   - string: second letter
    # Returns:
    #   - int: score
    #
    sub score_miss{
        my $self = shift;
        my $letter1 = shift;
        my $letter2 = shift;

        return $self->score->{'miss'};
    }

    #
    # Get the score for a match
    #
    # Input:
    #   - string: letter matched
    # Returns:
    #   - int: score
    #
    sub score_match{
        my $self = shift;
        my $letter = shift;

        return $self->score->{'match'};
    }

    # used to compare current score with 0 in local alignment and return 0
    # if 0 is bigger.
    #
    # Input:
    #   - int: cur score in dp algorithm
    # Returns:
    #   - int: new score
    #
    sub extra_compare{
        my $self = shift;
        my $score = shift;

        if(defined $self->local)
        {
            if(0 > $score)
            {
                return 0;
            }
        }
        return $score;
    }

    #
    # Indicate whether backtack should stop when it finds a zero, used in local alignment
    #
    sub should_stop_at_zero{
        my $self = shift;
        return defined $self->local;
    }

    #
    # Indicate whether backtack should start from maximum, used in local alignment
    #
    sub should_backtrack_max{
        my $self = shift;
        return defined $self->local;
    }


    #
    # Takes alignment data and output a string with printable format according to the alignment
    # algorithm.
    #
    # Input:
    #   - string : first sequence
    #   - string : second sequence
    #   - string : matched characters in first sequence according to backtracking
    #   - string : symbol line indicate the match type
    #   - string : matched characters in second sequence according to backtracking
    #   - int: score
    #   - hash: moves counts 'gap','match','miss'
    #   - int: row start location
    #   - int: col start location
    #   - int: row end location
    #   - int: col end location
    # Returns:
    #   - string: alignment result and scores

    sub getPrintableAlignment{
        my $self = shift;
        my $first = shift;
        my $second = shift;
        my $first_line = shift;
        my $symbol_line = shift;
        my $second_line = shift;
        my $score = shift;
        my $moves_count = shift;
        my $row_start = shift;
        my $col_start = shift;
        my $row_end = shift;
        my $col_end = shift;

        my $result = "";
        if(defined $self->global or defined $self->semi)
        {
            $result = $first_line ."\n".$symbol_line."\n".$second_line."\n\n";
            if(defined $self->global){
                $result = $result .
                    "\t\t$$moves_count{'gap'} gaps, $$moves_count{'match'} matches, $$moves_count{'miss'} misses.\n";
            }else{
                $result = $result .
                    "\t\t$$moves_count{'gap'} internal gaps, ". "$$moves_count{'term_gap'} terminal gaps, ".
                    "$$moves_count{'match'} matches, $$moves_count{'miss'} misses.\n";
            }
            $result = $result ."\t\tscore: $score \n\n";
        }
        elsif(defined $self->local)
        {
            # handle case where no local matches
            my ($extra_up, $extra_down)=("","");
            if($row_start == $row_end && $col_start == $col_end)
            {
                $first_line = $first;
                $second_line = " "x length $first . $second;
            }
            else
            {
                my ($bigger, $bigger_line,$end_big,$id_big) = $row_start > $col_start ? ($second, $second_line,$row_end,2):
                    ($first, $first_line, $col_end,1);
                my ($smaller, $smaller_line,$end_small,$id_small) = $row_start > $col_start ? ($first, $first_line, $col_end,1):
                    ($second, $second_line,$row_end,2);

                my ($tmp_big_line, $tmp_small_line, $tmp_symbol_line) = ("","","");
                #fill the bigger first

                my $diff = abs($row_start-$col_start);
                for(  my $i = 0;$i < $diff;$i++)
                {
                    $tmp_big_line = $tmp_big_line .  substr($bigger,$i,1);
                    $tmp_small_line = $tmp_small_line .  " ";
                    $tmp_symbol_line = $tmp_symbol_line .  " ";
                    $extra_up = $extra_up .  " ";
                    $extra_down = $extra_down .  " ";
                }

                #fill both
                for( my $i = 0;$i<min($row_start,$col_start); $i++)
                {
                    $tmp_big_line = $tmp_big_line .  substr($bigger,$i+$diff,1);
                    $tmp_small_line = $tmp_small_line .  substr($smaller,$i,1);
                    $tmp_symbol_line = $tmp_symbol_line .  " ";
                    $extra_up = $extra_up .  " ";
                    $extra_down = $extra_down .  " ";
                }

                #put indicators
                $tmp_big_line = $tmp_big_line . " ";
                $tmp_small_line = $tmp_small_line .  " ";
                $tmp_symbol_line = $tmp_symbol_line .  " ";
                $extra_up = $extra_up .  " ";
                $extra_down = $extra_down .  " ";


                #add borders
                $extra_up = $extra_up . "*"x length $first_line;
                $extra_down = $extra_down . "*"x length $first_line;

                #append to tmp
                substr($bigger_line,0,0) = $tmp_big_line;
                substr($smaller_line,0,0) = $tmp_small_line;
                substr($symbol_line,0,0) = $tmp_symbol_line;

                $bigger_line .=  " ";
                $smaller_line .=  " ";
                $symbol_line .=  " ";
                $extra_up = $extra_up .  " ";
                $extra_down = $extra_down .  " ";

                # complete bigger
                for(my $i = $end_big; $i < length $bigger; $i++)
                {
                   $bigger_line.= substr($bigger,$i,1);
                }

                # complete smaller
                for(my $i = $end_small; $i < length $smaller; $i++)
                {
                    $smaller_line .= substr($smaller,$i,1);
                }

               $first_line = $id_big == 1 ? $bigger_line:$smaller_line;
               $second_line = $id_small == 1 ? $bigger_line:$smaller_line;

            }

            $result = $extra_up."\n".$first_line ."\n".$symbol_line."\n".$second_line."\n".$extra_down."\n\n";

            $result = $result .
                "\t\t$$moves_count{'gap'} gaps, $$moves_count{'match'} matches, $$moves_count{'miss'} misses.\n";
            $result = $result ."\t\tscore: $score \n\n";
        }


        return $result;
    }


}

1;