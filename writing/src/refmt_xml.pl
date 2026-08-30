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

my $COLS = 75;

my $indent;
my $bld_ln;

#########################################################################
#	Dump string built up in $bld_ln and print it out as if it had	#
#	run through fmt, but honoring spacing over in $indent.		#
#########################################################################
sub dump_so_far
    {
    return if( ! defined( $bld_ln ) );

    $indent =~ s/\t/        /g;
    my $spaceout = length( $indent );

    my $pos = 10000;
    my $need_cr = "";
    foreach my $tok ( split(/\s/,$bld_ln) )
        {
	my $l = length($tok);
	if( ($pos + $l) > $COLS )
	    {
	    print $need_cr, $indent, $tok;
	    $need_cr = "\n";
	    $pos = $spaceout + $l;
	    }
	else
	    {
	    print " ", $tok;
	    $pos += (1 + $l);
	    }
	}
    print $need_cr;
    undef $bld_ln;
    }


#########################################################################
#	Main								#
#########################################################################
while( my $ln = <STDIN> )
    {
    chomp( $ln );
    $ln =~ s/\s*$//g;
    if( $ln =~ /^\s*</ || $ln =~ /^\s*$/ )
        {
	&dump_so_far();
	print $ln, "\n";
	if( $ln =~ /</ && $ln !~ />\s*$/ )
	    {
	    while( $ln = <STDIN> )
	        {
		chomp( $ln );
		print $ln, "\n";
		last if( $ln =~ />/ );
		}
	    }
	}
    elsif( $ln =~ /^(\s*)([^\s].*)/ )
        {
	if( defined($bld_ln) )
	    { $bld_ln .= " " . $2; }
	else
	    { $bld_ln = $2; }
	$indent = $1;
	}
    else
        {
	print STDERR "No idea what to do with [$ln].\n";
	}
    }
&dump_so_far();
exit(0);
