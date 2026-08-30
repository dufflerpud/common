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

#########################################################################
#	Create a new.cgi in xml format from the existing index.cgi in	#
#	the old format.  Presumably you run this once per directory.	#
#########################################################################

use strict;

my $INFILE_NAME="index.ref";
my $OUTFILE_NAME="index.cgi";
my $CHAR_IN_NAME="characters.ref";
my $CHAR_OUT_NAME="characters.xml";
my $PROG = $0;

#########################################################################
#	Print a useful error message and exit.				#
#########################################################################
sub usage
    {
    return if( ! @_ );
    print STDERR join("\n",@_), "\n\nUsage:  $PROG\n";
    exit(1);
    }

#########################################################################
#	Suck in the old format CGI file and replace with XML format.	#
#########################################################################
sub index_file
    {
    my( $INFILE, $OUTFILE ) = @_;

    open( INF, $INFILE ) || die("Cannot open ${INFILE}:  $!");

    open( OUT, ">$OUTFILE" ) || die("Cannot write ${OUTFILE}:  $!");
    chmod( 0755, $OUTFILE ) || die("Cannot chmod 0755 ${OUTFILE}:  $!");
    print OUT "#!/usr/bin/perl common/writing/story_xml.pl\n";

    my $story_name;
    my $in_chapter;

    while( $_ = <INF> )
	{
	chomp( $_ );
	next if( /^#/ );

	if( /^INCLUDE\((.*)\)/ )
	    { print OUT "<include file=\"characters.xml\"/>\n"; }
	elsif( /^STORY_TITLE\((.*)\)/ )
	    { $story_name = $1; }
	elsif( /^COLORS\((.*)\)/ )
	    {
	    print OUT "<story name=\"$story_name\" colors=\"$1\">\n";
	    $story_name = "";
	    }
	elsif( /^CHAPTER\((.*)\)/ )
	    {
	    if( $story_name )
		{
		print OUT "<story name=\"$story_name\">\n";
		$story_name = "";
		}
	    print OUT "    </text></chapter>\n" if( $in_chapter++ );
	    print OUT "    <chapter name=\"$1\">\n";
	    print OUT "    <summary>Summary for $1</summary>\n";
	    print OUT "    <text>\n";
	    }
	elsif( /^COMMENT\((.*)\)/ )
	    { print OUT "<comment>$1</comment>\n"; }
	elsif( /^REFERENCE\((.*),(.*)\)/ )
	    {
	    print OUT "<reference href=\"$2\">$1</reference>\n";
	    }
	elsif( ! /^\s*$/ )
	    { print OUT "\t$_\n"; }
	else
	    { print OUT "\n"; }
	}
    print OUT "    </text></chapter>\n" if( $in_chapter );
    print OUT "</story>\n" if( defined($story_name) );

    close( INF );
    close( OUT );
    }

#########################################################################
#	Suck in the old format character file and replace with XML	#
#	format.								#
#########################################################################
sub character_file
    {
    my( $INFILE, $OUTFILE ) = @_;

    open( INF, $INFILE ) || die("Cannot open ${INFILE}:  $!");
    open( OUT, ">$OUTFILE" ) || die("Cannot write ${OUTFILE}:  $!");

    while( $_ = <INF> )
        {
	chomp( $_ );
	if( /^CLEARDEFS\(\)/ )
	    { print OUT "<cleardefs/>\n"; }
	elsif( /^=([^\s]+),([^\s]+)\s+(.*)$/ )
	    { print OUT "<setvar name=\"$1\" modifier=\"$2\" value=\"$3\"/>\n"; }
	else
	    { print OUT $_, "\n"; }
	}

    close( INF );
    close( OUT );
    }

#########################################################################
#	Main								#
#########################################################################

my @problems;

$PROG =~ s+.*/++;

push( @problems, "$INFILE_NAME does not exist." )	if(! -r $INFILE_NAME);
#push( @problems, "$OUTFILE_NAME already exists." )	if(-e $OUTFILE_NAME);
push( @problems, "$CHAR_IN_NAME does not exist." )	if(! -r $CHAR_IN_NAME);
#push( @problems, "$CHAR_OUT_NAME already exists." )	if(-e $CHAR_OUT_NAME);

&usage( @problems );

&index_file( $INFILE_NAME, $OUTFILE_NAME );
&character_file( $CHAR_IN_NAME, $CHAR_OUT_NAME );
