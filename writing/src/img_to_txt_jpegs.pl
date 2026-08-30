#!/usr/bin/perl -w

use strict;

my $jpg;
my $contains;

my $CVT = "nene";

while( $_ = <STDIN> )
    {
    chomp( $_ );
    if( /src='(.*?)'/ )
	{ $jpg=$1; }
    if( /contains="(.*?)"/ )
	{
	my $contains=$1;
	if( -s $jpg )
	    {
	    #print "$jpg skipped.\n";
	    }
	else
	    {
	    open( OUT, "| fmt -40 | $CVT -.txt $jpg" ) ||
	        die("Cannot run format or $CVT:  $!");
	    print OUT $contains, "\n";
	    close( OUT );
	    print "$jpg created.\n";
	    }
	}
    }
