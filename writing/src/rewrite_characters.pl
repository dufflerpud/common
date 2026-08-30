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
use lib "/usr/local/lib/perl";

use cpi_file qw( fatal read_file write_file );
use cpi_arguments qw( parse_arguments );

# Put constants here

my $TMP = "/tmp/$cpi_vars::PROG.$$";
#my $TMP = "/tmp/$cpi_vars::PROG";

our %ONLY_ONE_DEFAULTS =
    (
    "i"	=>	"/dev/stdin",
    "o"	=>	"/dev/stdout",
    "f"	=>	"new1",
    "v"	=>	""
    );

# Put variables here.

my @problems;
our %ARGS;
our @files;
my $exit_stat = 0;

# Variables and fields not mentioned will be output in sort order
my @VAR_ORDER = qw(
    HERO HEROINE VILLAIN OLD_MAN OLD_WOMAN BRUTE
    BOY GIRL M0 M1 M2 M3 M4 F0 F1 F2 F3 F4 );
my @FLD_ORDER = qw( TITLE FIRST MIDDLE LAST GENDER JOB REF MEANING );

#########################################################################
#	Setup arguments if CGI.						#
#########################################################################
sub CGI_arguments
    {
    &CGIreceive();
    }

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <possible arguments>","",
	"where <possible arguments> is:",
	"    -i <input file>",
	"    -o <output file>"
	);
    }

#########################################################################
#	Remove duplicate entries from a list preserving order.		#
#########################################################################
sub remove_dups
    {
    my %seen;
    return grep( !$seen{$_}++, @_ );
    }

#########################################################################
#	Read a character file (in one of two formats)			#
#########################################################################
my $cleardefs = 0;
my %vars;
sub read_characters
    {
    my $variable_fmt_old;
    my $defining_variable;
    foreach my $piece ( split( m:(<.*?>):,&read_file($ARGS{i})) )
        {
	if( $piece =~ /^<cleardefs\s*\/>$/ )
	    { $cleardefs = 1; }
	elsif( $piece =~ m:^<setvar\s+name="(.*?)"\s+modifier="(.*?)"\s+value="(.*?)"\s*/>$:ms )
	    { $vars{$1}{$2} = $3; }
	elsif( $piece =~ m:^<setvar\s+name="(.*?)">:ms )
	    { $defining_variable = $1; }
	elsif( $piece =~ m:^</setvar>:ms )
	    { undef $defining_variable; }
	elsif( $defining_variable )
	    { $vars{$defining_variable}{$1} = $2; }
	}
    }

#########################################################################
#	Write character file out in either format.			#
#########################################################################
sub write_characters
    {
    my( $fmt ) = @_;
    my @out;
    push( @out, "<cleardefs/>\n\n" ) if( $cleardefs );

    my $sep = "";
    foreach my $var ( &remove_dups( @VAR_ORDER, sort keys %vars ) )
        {
	next if( ! $vars{$var} );
	push( @out, $sep );
	if( $fmt eq "new0" )
	    { push( @out, "<setvar name=\"$var\">" ); }
	elsif( $fmt eq "new1" )
	    { push( @out, "<setvar name=\"$var\"" ); }

	foreach my $fld ( &remove_dups( @FLD_ORDER, sort keys %{$vars{$var}} ) )
	    {
	    next if( ! $vars{$var}{$fld} );
	    if( $fmt eq "old" )
		{ push(@out, "\n<setvar name=\"$var\" modifer=\"$fld\" value=\"$vars{$var}{$fld}\">"); }
	    else
		{ push(@out, "\n\t$fld=\"$vars{$var}{$fld}\""); }
	    }
	if( $fmt eq "new0" )
	    { push(@out, "\n</setvar>\n"); }
	elsif( $fmt eq "new1" )
	    { push(@out, " />\n"); }
	$sep = "\n";
	}
    &write_file( $ARGS{o}, @out );
    }

#########################################################################
#	Main								#
#########################################################################

if( 0 && $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { %ARGS = &parse_arguments({switches=>\%ONLY_ONE_DEFAULTS,non_switches=>\@files}); }

#print join("\n\t","Args:",map{"$_:\t$ARGS{$_}"} sort keys %ARGS), "\n";

&read_characters();
&write_characters($ARGS{f});

exec("rm -rf $TMP");

