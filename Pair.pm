package Pair
{
    use strict;
    use Moose;

    has 'name'=> ( is => 'rw' );
    has 'first'=> ( is => 'rw' );
    has 'second'=> ( is => 'rw' );

    has 'alignment_results'=> ( is => 'rw' , default => sub {{}});


    sub check{
        my $self = shift;
        if(not defined $self->alignment_results)
        {
            print "not defined";
        }
        else
        {
            print "defined";
        }
    }
}

1;