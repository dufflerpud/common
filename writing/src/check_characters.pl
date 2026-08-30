#!/usr/bin/perl -w
#@HDR@	$Id$
#@HDR@		Copyright 2024 by
#@HDR@		Christopher Caldwell/Brightsands
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of Brightsands and may not be used, copied or made available
#@HDR@	to anyone, except in accordance with the license under which
#@HDR@	it is furnished.

use strict;

my %varvals;

foreach my $pc ( split(/(<[^<]*)/,join("",<STDIN>)) )
    {
    if( $pc !~ m:^<(.*)/>\s*$:ms )
        {
	#print "Ignoring=[$pc]\n";
	next;
	}
    else
        {
	my $triad = $1;
	#print "Triad was [$triad]\n";
        if( $triad eq "cleardefs" )
	    {
	    %varvals = ();
	    next;
	    }

	if( $triad !~ m:^\s*setvar\s+name="(.*)"\s+modifier="(.*)"\s+value="(.*)"\s*$: )
	    {
	    print "Badly composed triad:  [$triad]\n";
	    next;
	    }
	else
	    {
	    my( $name, $modifier, $value ) = ( $1, $2, $3 );
	    if( $name !~ /^[A-Z0-9_]+$/ )
		{
		print "$name is not all capital letters in <$triad/>\n";
		next;
		}
	    if( $modifier !~ /^[A-Z0-9_]+$/ )
		{
		print "$modifier is not all capital letters in <$triad/>\n";
		next;
		}
	    if( $varvals{$name}{$modifier} )
		{
		print "$name,$modifier already defined with <$triad/>\n";
		next;
		}
	    if( $modifier eq "SYNONYM" )
		{
		if( ! $varvals{$value} )
		    {
		    print "$name,$modifier points to non-existant definition $value with <$triad/>\n";
		    next;
		    }
		$varvals{$value}{$modifier} = $value;
		next;
		}
	    $varvals{$value}{$modifier} = $value;
	    }
	}
    }
