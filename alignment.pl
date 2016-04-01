#!/usr/bin/perl
use strict;
#Flush output as soon as print is called
STDOUT->autoflush(1);

#import class files
use DpAlignment;
use Pair;
use AlignAlgorithm;
use Reader;

my %scores = ('int_gap' => -5, 'term_gap' => 0, 'match' => 5, 'miss' => -4);

#initialize different algorithms
my $global_algo = AlignAlgorithm->new(
    name=>"global alignment",
    score => \%scores,
    global => 1
);

my $semi_global_algo = AlignAlgorithm->new(
    name=>"semi-global alignment",
    score => \%scores,
    semi => 1
);
my $local_algo = AlignAlgorithm->new(
    name=>"local alignment",
    score => \%scores,
    local => 1
);


# read pairs from file
my $pairs = Reader->getPairsFromFile("seq/Sequence_Pair_1.txt","seq/Sequence_Pair_2.txt","seq/Sequence_Pair_3.txt");
# initialize the dp algoritm
my $dp = DpAlignment->new(scores => \%scores);

# align
foreach my $pair (@$pairs)
{
    # align with global alignment
    $dp->align($pair, $global_algo);
    # align with semi global alignment
    $dp->align($pair, $semi_global_algo);
    # align with local  alignment
    $dp->align($pair, $local_algo);
}


# print results
open(my $fh, '>', 'alignment_output.txt') or die "couldnt create output file: $!\n";
foreach my $pair (@$pairs)
{
    print $fh $pair->name . ":\n\n\n";
    foreach my $key (sort keys%{$pair->alignment_results})
    {
        print $fh "#"x(length($key)+10)."\n###  $key  ###\n"."#"x(length ($key)+10)."\n\n".$pair->alignment_results->{$key} ;
        print $fh "\n\n";
    }

    print $fh "\n\n\n";
}

close $fh;

