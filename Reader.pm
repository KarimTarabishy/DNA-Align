package Reader{
    use strict;
    use Moose;
    use Pair;

    # Extract sequences from given files into Pair objects and returns them
    #
    # Arguments:
    #       - strings of file names
    # Returns:
    #       - array of Pair objects
    #
    sub getPairsFromFile{
        my $self = shift;

        my @pairs = ();
        # loop over arguments
        foreach my $file_name (@_)
        {
            #read sequence pair
            my ($error, $first, $second) = __readSequencePair($file_name);

            #check for errors
            if(length $error)
            {
                die "Error: $error\n";
            }

            #create a pair object with this data
            my $pair = Pair->new(name => $file_name, first=>$first, second => $second);
            # then save it
            push @pairs, $pair;
        }

        return \@pairs;
    }

    # Takes a file name and read it checks that there exists 2 sequences inside and extract them.
    #
    # Arguments:
    #       - string of file name
    # Returns:
    #       - string: contains an error msg if there is an error
    #       - string: contains first sequence found
    #       - string: contains second sequence found
    #
    sub __readSequencePair{
        # file name
        my $file_name = shift();

        #return values
        my ($seq1, $seq2, $error) = ("","", "");

        #open the file in read mode
        my $file_handle;
        # variable to use to know or file didnt open
        my $file_is_opened = 1;
        if(not open($file_handle, "<", $file_name))
        {
            $error = "Couldn't open file $file_name: $!";
            $file_is_opened = 0;
            goto END;
        }

        #holds amount of valid sequences we have read
        my @valid_sequences=();

        #read lines
        while(my $line = <$file_handle>)
        {
            # remove all space characters
            $line =~ s/\s+//g;
            # only check the line if it contains any non space character
            if (length $line)
            {
                # does line contain any invalid characters?
                if($line =~ /([^ACGT])/)
                {
                    $error = "Invalid character '$1' was found in given sequence: \n$line\n";
                    goto END;
                }

                push @valid_sequences, $line;
            }
        }

        # Check we found correct sequences count
        if(scalar @valid_sequences != 2)
        {
            $error = "Expecting 2 sequences in file, found " . scalar @valid_sequences . " instead.\n";
            goto END;
        }

        # save the 2 sequences
        ($seq1,$seq2) = @valid_sequences;

        END:
        #close the file
        if(!fileno $file_handle and $file_is_opened)
        {
            close($file_handle) or warn "Couldn't close file $file_name.\n";
        }

        return ($error, $seq1,$seq2);
    }

}

1;