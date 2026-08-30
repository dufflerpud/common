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

my @VERBS =
    (
    "line",
    "action",
    "description",
    "camera",
    "summary",
    "comment"
    );

my @DEFAULT_EPISODES =
   (
   "e1","e1-bonus",
   "e2","e3","e4","e5","e6","e7",
   "e10","e11","e12",
   "e14",
   "trash","ziggy"
   #"e13","e13_from_orbit","e13_missile",
   );

my $WRITING_BASE = "/home/chris/public_html/writing";
my $OLD_GEO7_BASE = "$WRITING_BASE/Geo7/ref";
my $NEW_GEO7_BASE = "$WRITING_BASE/Geo7/episodes";
my $outdir;
my $OUTFILE = "index.cgi";
my $OKLIST = "index.ok";
my $CHARACTERS = "characters.xml";
my $CHARACTERS_SOURCE = "../../$CHARACTERS";
my $MAKEFILE_SOURCE = "common/writing/Makefile.stories";

my $PROG = $0;	$PROG =~ s+.*/++;
my $contents;
my @sublist;

#########################################################################
#	Print a useful error message and exit.				#
#########################################################################
sub usage
    {
    return if( ! @_ );
    print STDERR join("\n",@_), "\n\nUsage:  $PROG eNN\n";
    exit(1);
    }

#########################################################################
#	Take first and last name and index.  Do search and replace	#
#	for full and schedule first and last.				#
#########################################################################
sub first_last
    {
    my( $ind, $first, $lastn, $nick ) = @_;
    $contents =~ s+$first $lastn+{$ind,FULL}+gi;
    if( $nick )
	{
	$contents =~ s+$nick $lastn+{$ind,NICKFULL}+gi;
	push( @sublist, $nick );
	push( @sublist, "{$ind,NICK}" );
	}
    push( @sublist, $first );
    push( @sublist, "{$ind,FIRST}" );
    push( @sublist, $lastn );
    push( @sublist, "{$ind,LAST}" );
    }

#########################################################################
#	Completely setup one episode
#########################################################################
sub do_one_episode
    {
    my( $inepisode ) = @_;

    my $infile = "$OLD_GEO7_BASE/$inepisode.cgi";
    print "Processing $infile...\n";

    open( INF, $infile ) || die("Cannot open ${infile}:  $!");
    $contents = join("",<INF>);
    close( INF );

    $contents =~ s+old_geo7_script_lib.cgi+common/writing/story_xml.pl+;
    $contents =~ s+BEGIN\((.*?),(.*?),(.*?),(.*?),(.*?)\)+<story name="$2" episode="$1" author="$3">\n<include file="characters.xml"/>\n<summary>\n$5\n</summary>\n+gs;
    $contents =~ s+PLOT\s*(.*)+<summary>$1+g;
    $contents =~ s+AUTHORS_NOTES\s*(.*)+<comment>$1+g;
    $contents =~ s+SCENE\((.*?),(.*?)\)+<chapter name="$2" time="$1">+g;
    $contents =~ s+SCENE\((.*?)\)+<chapter name="$1">+g;
    $contents =~ s+PAN\((.*?)\)+<camera action="PAN" where="$1">+g;
    $contents =~ s+CUTTO\((.*?)\)+<camera action="CUT TO" where="$1">+g;
    $contents =~ s+SLOWFADETO\((.*?)\)+<camera action="SLOW FADE TO" where="$1">+g;
    $contents =~ s+FASTFADETO\((.*?)\)+<camera action="FAST FADE TO" where="$1">+g;
    $contents =~ s+TITLES\((.*?)\)+<camera action="TITLES" where="$1">+g;
    $contents =~ s+COMMERCIALS\((.*?)\)+<camera action="COMMERCIALS" where="$1">+g;
    $contents =~ s+CREDITS\((.*?)\)+<camera action="CREDITS" where="$1">+g;
    $contents =~ s+LINE\((.*?)\)\s*\(<i>(.*?)</i>\)+<line name="$1" how="$2">+g;
    $contents =~ s+LINE\((.*?)\)+<line name="$1">+g;
    $contents =~ s+OFFSTAGE\((.*?)\)\s*\(<i>(.*?)</i>\)+<line name="$1" how="Offstage, $2">+g;
    $contents =~ s+OFFSTAGE\((.*?)\)+<line name="$1" how="Offstage">+g;
    $contents =~ s+VO\((.*?)\)\s*\(<i>(.*?)</i>\)+<line name="$1" how="Voiceover, $2">+g;
    $contents =~ s+VO\((.*?)\)+<line name="$1" how="Voiceover">+g;
    $contents =~ s+ACTION\((.*?)\)+<action name="$1">+g;
    $contents =~ s+DESCRIPTION+<description>+g;
    #$contents =~ s+END+</story>+g;
    $contents =~ s+^END\n++m;
    $contents =~ s+STATION+{STATION,NAME}+g;

    #&first_last("X","Ahmed","Davida");
    #&first_last("X","Chris","Barnard");
    #&first_last("X","Sandra","Danielson");
    #&first_last("X","Fred","Cummings");
    #&first_last("X","Grace","Martina");
    #&first_last("X","Stephen","Laird");
    #&first_last("X","Rudy","Polati");
    #&first_last("X","Sarah","Norman");
    #&first_last("X","Todd","Costa");
    #&first_last("X","Edward","Wilson");
    #&first_last("X","Anthony","Nelson");
    #&first_last("X","Blond","Avitar");
    #&first_last("X","Corporal");
    #&first_last("X","Edward","Wilson");
    #&first_last("X","Drake","Ravitz");
    #&first_last("X","Ground","Control");
    #&first_last("X","Guard","1");
    #&first_last("X","Guard","2");
    #&first_last("X","Interviewer");
    #&first_last("X","Juan","Malondo");
    #&first_last("X","Passenger");
    #&first_last("X","Powell","Approach");
    #&first_last("X","Teresa","Devorena");
    #&first_last("X","Timothy","Malone");
    #&first_last("X","Tower");
    #&first_last("X","World","Flight Authority");

    @sublist = ();
    &first_last("HEROINE","Ellison","Samuelson","Ellie");
    &first_last("OLD_MAN","Elijah","Samuelson");
    &first_last("VILLAIN","Ira","Scarpoa");
    &first_last("GIRL","Kelly","Falway");
    &first_last("OLD_WOMAN","Prudence","Varley");
    &first_last("HERO","Wallace","Kahn");
    &first_last("BRUTE","John","Norwin");

    while( my $frm = shift(@sublist) )
	{
	my $subto = shift(@sublist);
	$contents =~ s+$frm+$subto+g;
	}

    my @predicates = map { "<$_" } @VERBS; 
    my $srcstr = join("|",@predicates);

    my @new_contents;

    my $seen_chap;
    foreach my $opiece ( split( /(<chapter)/, $contents ) )
	{
	if( $opiece eq "<chapter" )
	    {
	    push( @new_contents, "</chapter>\n" ) if( $seen_chap++ );
	    push( @new_contents, $opiece );
	    }
	else
	    {
	    my $was_in;
	    foreach my $piece ( split(/($srcstr)/,$opiece) )
		{
		if( grep( $_ eq $piece, @predicates ) )
		    {
		    push( @new_contents, "</$1>\n" )
			if( $was_in && $was_in =~ /<(.*)/ );
		    $was_in = $piece;
		    }
		push( @new_contents, $piece );
		}
	    push( @new_contents, "</$1>\n" )
		if( $was_in && $was_in =~ /<(.*)/ );
	    }
	}
    push( @new_contents, "</chapter></story>\n" );

    $contents = join("",@new_contents);

    @new_contents = ();
    foreach my $piece ( split(/(<line name=".*?"|<action name=".*?"|<\/action>|<\/line>)/,$contents) )
	{
	if( $piece =~ /<line name="(.*)"/ )
	    { push( @new_contents, "<by name=\"$1\"><line" ); }
	elsif( $piece =~ /<action name="(.*)"/ )
	    { push( @new_contents, "<by name=\"$1\"><action" ); }
	elsif( $piece eq "</action>" || $piece eq "</line>" )
	    { push( @new_contents, $piece, "</by>" ); }
	else
	    { push( @new_contents, $piece ); }
	}

    $contents = join("",@new_contents);

    $outdir = "${NEW_GEO7_BASE}/$inepisode";
    system("rm -rf $outdir; mkdir -p $outdir/build $outdir/published");
    chdir( $outdir ) || die("Cannot chdir($outdir):  $!");

    open( OUT, "> $OUTFILE" ) || die("Cannot write ${OUTFILE}:  $!");
    print OUT $contents;
    close( OUT );

    system( join(";",
	"ln -s ../common common",
	"ln -s $CHARACTERS_SOURCE $CHARACTERS",
	"chmod 755 . $OUTFILE",
	"ln -s $MAKEFILE_SOURCE Makefile",
	#"ln -s ../../ref/$inepisode.ok index.ok",
	"ln -s ../../index.ok index.ok"
	#"cp ../../$inepisode.ok index.ok"
	) );
    }

#########################################################################
#	Main								#
#########################################################################

my @problems = ();

my @episodes;
while ( defined( $_ = shift(@ARGV) ) )
    {
    if( -f "$OLD_GEO7_BASE/$_.cgi" )
        {
#	push( @problems, "File already defined" )
#	    if( @episodes );
	push( @episodes, $_ );
	}
    elsif( $_ eq "all" )
        { @episodes = @DEFAULT_EPISODES; }
    else
        {
	push( @problems, "Unknown argument:  $_" );
	}
    }

push( @problems, "No input specified") if( ! @episodes );

&usage( @problems ) if( @problems );

foreach my $episode ( @episodes )
    {
    &do_one_episode( $episode );
    }
