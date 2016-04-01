package DpAlignment{
    use strict;
    use Moose;
    STDOUT->autoflush(1);
    use constant {
        MOVE_GAP_RIGHT  => -1,
        MOVE_GAP_DOWN => 0,
        MOVE_MATCH  => 1,
        MOVE_MISS => 2,

        GAP_INITAL => 1 << 0,
        GAP_TERMINAL=> 1<<1,
        GAP_INSIDE => 1<<2
    };


    # hash with scores
    has 'scores'=> ( is => 'rw' );

    # private dont use
    has '__mat'=> ( is => 'rw' );
    has '__back'=>( is => 'rw' );
    has '__pair'=> ( is => 'rw' );
    has '__algo'=> ( is => 'rw' );
    has '__rows'=> ( is => 'rw' );
    has '__cols'=> ( is => 'rw' );
    has '__max_cell_score' => ( is => 'rw' );

    sub align{
        my $self = shift;
        # first argument is a pair object
        my $pair = shift;
        # second argument the alignment algorithm object
        my $algo = shift;

        #save data for later operations
        $self->__mat([]);
        $self->__back([]);
        $self->__pair($pair);
        $self->__algo($algo);
        $self ->__rows(length($pair->second)+1 );
        $self ->__cols(length($pair->first)+1);

        # start operations
        $self->__initialize();
        $self->__calculateScores();
        $self->__backtrack();
    };

    # Initialize the first row and first column
    sub __initialize {
        my $self = shift;

        my $max_cell;
        my @max_cell;

        $self->__mat->[0][0] = 0;
        $self->__back->[0][0] = MOVE_MATCH;

        #initialize first row
        for(my $c = 1; $c < $self->__cols; $c++)
        {
            # get score of matching the first sequence letter at position $c with a gap
            # indicate that we are in an intiatal gap also a temrinal gap
            $self->__mat->[0][$c] = $self->__algo->score_gap(substr( $self->__pair->first, $c-1, 1),
                GAP_INITAL|GAP_TERMINAL) + $self->__mat->[0][$c-1];
            $self->__back->[0][$c] = MOVE_GAP_RIGHT;

            # save cell with maximum score
            if(not defined $max_cell)
            {
                $max_cell = $self->__mat->[0][$c];
                @max_cell = (0,$c);
            }
            else
            {
                if($self->__mat->[0][$c] > $max_cell)
                {
                    $max_cell = $self->__mat->[0][$c];
                    @max_cell = (0,$c);
                }
            }
        }

        #initialize first column
        for(my $r = 1; $r < $self->__rows; $r++)
        {
            # get score of matching the second sequence letter at position $r with a gap
            # indicate that we are in an intiatal gap also a temrinal gap
            $self->__mat->[$r][0] = $self->__algo->score_gap(substr($self->__pair->second, $r-1, 1),
                GAP_INITAL|GAP_TERMINAL) + $self->__mat->[$r-1][0];
            $self->__back->[$r][0] = MOVE_GAP_DOWN;

            # save cell with maximum score
            if($self->__mat->[$r][0] > $max_cell)
            {
                $max_cell = $self->__mat->[$r][0];
                @max_cell = ($r,0);
            }
        }

        $self->__max_cell_score(\@max_cell);
    };

    sub __calculateScores{
        my $self = shift;
        my @max_cell = @{$self->__max_cell_score};
        my $max_cell = $self->__mat->[$max_cell[0]]->[$max_cell[1]];

        for(my $r = 1; $r < $self->__rows; $r++)
        {
            for(my $c = 1; $c < $self->__cols; $c++){

                my $first_char = substr($self->__pair->first, $c-1, 1);
                my $second_char= substr($self->__pair->second, $r-1, 1);

                # check if 2 letters match
                my $is_match = $first_char eq $second_char;

                my $cur_score;
                my $move_type;
                my $tmp;

                #### first check score for match/miss ####
                if(not $is_match)
                {
                    $cur_score = $self->__algo->score_miss($first_char, $second_char);
                    $move_type = MOVE_MISS;
                }
                else
                {
                    $cur_score = $self->__algo->score_match($first_char);
                    $move_type = MOVE_MATCH;
                }
                # add prev
                $cur_score += $self->__mat->[$r-1][$c-1];

                #### Gap score : right ####
                $tmp = $self->__algo->score_gap($first_char, ($r == $self->__rows-1) ? GAP_TERMINAL: GAP_INSIDE);
                # add prev
                $tmp += $self->__mat->[$r][$c-1];
                #should we replace?
                if($tmp > $cur_score)
                {
                    $cur_score = $tmp;
                    $move_type = MOVE_GAP_RIGHT;
                }

                #### Gap scroe: down ####
                $tmp = $self->__algo->score_gap($second_char, ($c == $self->__cols-1) ? GAP_TERMINAL: GAP_INSIDE);
                # add prev
                $tmp += $self->__mat->[$r-1][$c];
                #should we replace?
                if($tmp > $cur_score)
                {
                    $cur_score = $tmp;
                    $move_type = MOVE_GAP_DOWN;
                }

                ## give the current scroe to algorithm to check if it needs to change
                $cur_score = $self->__algo->extra_compare($cur_score);

                # save scroe
                $self->__mat->[$r][$c] = $cur_score;

                # save backtrack info
                $self->__back->[$r][$c] = $move_type;

                #save max
                if($cur_score > $max_cell)
                {
                    $max_cell = $cur_score;
                    @max_cell = ($r,$c);
                }
            }
        }
        $self->__max_cell_score(\@max_cell);
    };

    sub __backtrack{
        my $self = shift;

        my ($first_line,$symbol_line,$second_line)  = ("","","","");

        #get start location
        my $r = $self->__algo->should_backtrack_max ? $self->__max_cell_score->[0]:$self->__rows -1;
        my $c = $self->__algo->should_backtrack_max ? $self->__max_cell_score->[1]: $self->__cols -1;

        my @start_loc = ($r,$c);
        my @end_loc = ($r,$c);
        my %moves_count = ('gap' => 0, 'miss'=> 0, 'match' => 0, 'term_gap' =>0 );

        my $score = $self->__mat->[$r][$c];

        while(1)
        {
            # get and save some data
            my $move_type = $self->__back->[$r][$c];
            my $first_char = substr($self->__pair->first, $c-1, 1);
            my $second_char = substr($self->__pair->second, $r-1, 1);
            my $score = $self->__mat->[$r][$c];

            # if reached cell [0,0] or reached a zero score and algorithm indicate stop here then break out
            if(($r == 0 and $c == 0) or ($self->__algo->should_stop_at_zero() and $score == 0))
            {
                last;
            }

            if($move_type == MOVE_GAP_DOWN)
            {
                substr($first_line,0,0) = "-";
                substr($second_line,0,0) = $second_char;
                substr($symbol_line,0,0) = " ";
                $r -= 1;

                if($r == 0 || $r == $self->__rows -1 || $c == 0 || $c == $self->__cols -1)
                {
                    $moves_count{'term_gap'}++;
                }
                else
                {
                    $moves_count{'gap'}++;
                }
            }
            elsif ($move_type == MOVE_GAP_RIGHT)
            {
                substr($first_line,0,0) = $first_char;
                substr($second_line,0,0) = "-";
                substr($symbol_line,0,0) = " ";
                $c -= 1;
                if($r == 0 || $r == $self->__rows -1 || $c == 0 || $c == $self->__cols -1)
                {
                    $moves_count{'term_gap'}++;
                }
                else
                {
                    $moves_count{'gap'}++;
                }

            }
            else # match and miss
            {

                substr($first_line,0,0) = $first_char;
                substr($second_line,0,0) = $second_char;
                substr($symbol_line,0,0) = $move_type == MOVE_MATCH ?"|":".";
                $r -= 1;
                $c -= 1;
                my $type = $move_type == MOVE_MATCH ? 'match' : 'miss';
                $moves_count{$type}++;
            }
        }

        @end_loc = ($r,$c);

        # save alignment result to pair object
        $self->__pair->alignment_results->{$self->__algo->name} = $self->__algo->getPrintableAlignment(
            $self->__pair->first, $self->__pair->second, $first_line, $symbol_line, $second_line,$score, \%moves_count,
            $end_loc[0], $end_loc[1], $start_loc[0], $start_loc[1]
        );
    };
};

1;