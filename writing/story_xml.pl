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

my $STORY = $ENV{FILENAME} || `/bin/pwd`;
chomp( $STORY );
$STORY =~ s+/(index|app)\.cgi$++g;
$STORY =~ s+.*/++g;
my $stderr = "/var/log/stderr/$STORY";
close( STDERR );
open( STDERR, "> $stderr" ) || die("Cannot open ${stderr}:  $!");
chmod( 0666, $stderr );

my @TEXT_HELPERS	= qw( offset letter sender date receiver salutation contents
			    signature cc );
my @TEXT_PRIMITIVES	= ( qw( glossary footnote comment reference illustration thank ),
			    @TEXT_HELPERS );

my @PLURALIZED_TEXT_PRIMITIVES = (map {"${_}s"} @TEXT_PRIMITIVES);

my @KNOWN_CLAUSES	= ( qw( story creator_info dedication overview promotion related
			    chapter subchapter by line	action description camera
			    summary text book from setvar ), @TEXT_PRIMITIVES );

my @NON_DEBUG_SHOWS	= ( qw( browser toc subchapters subchapter_names text storyid
			    title story_summaries copyright dedication related
			    chapter_summaries overview promotion creator_info
			    subchapter_summaries color links cameras subs ),
			    @PLURALIZED_TEXT_PRIMITIVES );

my @DEBUG_SHOWS		= qw( vars objects flow );

my @SHOWS = ( @NON_DEBUG_SHOWS, @DEBUG_SHOWS );

my %SHOW_LISTS =
	(
	all		=>\@NON_DEBUG_SHOWS,
	none		=>[	],
	test		=>[	"toc","text","color","links",
				"subchapters", "subchapter_names",
				@PLURALIZED_TEXT_PRIMITIVES		],
	browser		=>[	"toc","text","color","links",
				@PLURALIZED_TEXT_PRIMITIVES		],
	pre_toc		=>[	"title","copyright","dedication"	],
	post_toc	=>[	"text","illustrations","references",
				"glossary",
				"trademarks",
				"thanks",
				"subchapters", "subchapter_names",
				"creator_info"				],
	reader		=>[	"links","title","copyright",
				"dedication","toc","text",
				"illustrations","references",
				"glossary","trademarks","thanks",
				"subchapters","subchapter_names",
				"creator_info"				],
	publisher	=>[	"overview","promotion","creator_info",
				"story_summaries","chapter_summaries",
				"subchapter_summaries"			],
	agent		=>[	"overview","promotion","creator_info",
				"short_text", "illustrations"		],
	summaries	=>[	"overview","story_summaries",
				"chapter_summaries",
				"subchapter_summaries"			],
	flow		=>[	"flow"					]
	);

my @COLOR_LIST		= qw( red green blue brown yellow purple cyan gray );

my %SHOW;
#grep( $SHOW{$_}=1, "references", "thanks", "toc", "text", "color", "title" );

my @PREFERED_VAR_ORDER	= qw( HERO HEROINE OLD_MAN OLD_WOMAN BRUTE VILLAIN BOY GIRL );
my @PREFERED_FIELD_ORDER= qw( FIRST MIDDLE LAST TITLE FULL FULLER FULLEST NICK CUTE );
my @FUNCS		= qw( METAUNITS UNITS PUNITS CHANGEUNITS PCHANGEUNITS CREF
			    TREF PHONETIC INITIAL UCFIRST GENDER_TITLE METRICENGLISH
			    TIMELINE );

my %MARK_TO_HTML = ( "trademark"=>"&trade;", "glossary"=>"&diam;" );

my $BASETYPE = "Metric";
my $UTYPE = $BASETYPE;
#my $UTYPE = "English";

my %SUBUNIT =
    (
    "English" =>
	{
	"kilometers per second"	=> "miles per second",
	"kilometers"		=> "miles",
	"meters"		=> "feet",
	"centimeters"		=> "inches",
	"decimeters"		=> "inches",
	"metric tonnes"		=> "tons"
	}
    );

my %PLURALS =
    (
    "kilometer"		=> "kilometers",
    "km"		=> "km",
    "knott"		=> "knotts",
    "meter"		=> "meters",
    "millimeter"	=> "millimeters",
    "centimeter"	=> "centimeters",
    "decimeter"		=> "decimeters",
    "cm"		=> "cm",
    "degree c"		=> "degrees c",
    "degree celsius"	=> "degrees celsius",
    "degree centigrade"	=> "degrees centigrade",
    "mile"		=> "miles",
    "inch"		=> "inches",
    "foot"		=> "feet",
    "degree fahrenheit"	=> "degrees fahrenheit",
    "metric ton"	=> "metric tonnes",
    "pound"		=> "pounds",
    "ton"		=> "tons"
    );
my %SINGULARS = map( ($PLURALS{$_}, $_), keys %PLURALS );

my %UTABLE =
    (
    "English" =>
	[
        { ounit=>"kilometer", minv=>3, maxv=>1000000,
		mul=>0.62137119, add=>0, nunit=>"mile" },
        { ounit=>"kilometer", minv=>0, maxv=>3,
		mul=>3280.8399, add=>0, nunit=>"foot" },
	{ ounit=>"meter", minv=>1, maxv=>10000000,
		mul=>3.2808399, add=>0, nunit=>"foot" },
	{ ounit=>"decimeter", minv=>0, maxv=>1000000,
		mul=>3.9370079, add=>0, nunit=>"inch" },
	{ ounit=>"centimeter", minv=>0, maxv=>1000000,
		mul=>0.39370079, add=>0, nunit=>"inch" },
	{ ounit=>"cm", minv=>0, maxv=>1000000,
		mul=>0.39370079, add=>0, nunit=>"inch" },
	{ ounit=>"degree centigrade", minv=>-1000000, maxv=>1000000,
		mul=>1.8, add=>32, nunit=>"degree fahrenheit" },
	{ ounit=>"degree celsius", minv=>-1000000, maxv=>1000000,
		mul=>1.8, add=>32, nunit=>"degree fahrenheit" },
	{ ounit=>"degree c", minv=>-1000000, maxv=>1000000,
		mul=>1.8, add=>32, nunit=>"degree fahrenheit" },
	{ ounit=>"metric ton", minv=>-1000000, maxv=>1000000,
		mul=>1.1023, add=>0, nunit=>"ton" },
	]
    );

my %PHONETICS =
	(
	"."=>"Decimal",	","=>"Comma",
	"0"=>"Zero",	"1"=>"One",	"2"=>"Two",	"3"=>"Three",
	"4"=>"Fower",	"5"=>"Fiver",	"6"=>"Six",	"7"=>"Seven",
	"8"=>"Eight",	"9"=>"Niner",
	"A"=>"Alpha",	"B"=>"Bravo",	"C"=>"Charlie",	"D"=>"Delta",
	"E"=>"Echo",	"F"=>"Fox-trot","G"=>"Golf",	"H"=>"Hotel",
	"I"=>"Indigo",	"J"=>"Juliet",	"K"=>"Kilo",	"L"=>"Lima",
	"M"=>"Mike",	"N"=>"November","O"=>"Oscar",	"P"=>"Papa",
	"Q"=>"Quebec",	"R"=>"Romeo",	"S"=>"Siera",	"T"=>"Tango",
	"W"=>"Whiskey",	"X"=>"X-Ray",	"Y"=>"Yankee",	"Z"=>"Zulu"
	);

my $STORY_TIME_FMT = undef;

my $verbose = 0;
my %timelines;

my $DIR = ".";
my $IS_CGI = ( $ENV{SCRIPT_NAME} ? 1 : 0 );
$IS_CGI=1;

$| = 1;

my $COLFLAG;

my $need_spacer = 0;
my $top_ptr;
my @errlist;

my $DEBUG_FILE = "/tmp/objects.$$";

my %has_clause_type;

my $current_timeline = "base";

use lib "/usr/local/lib/perl";
use COMMON;
$COMMON::PROG = $0;
$COMMON::PROG =~ s+.*/++;
$COMMON::PROG =~ s+\..*++;

#########################################################################
#	Verify that the supplied pointer is correct type.		#
#	If not, print message, stack dump, and exit.			#
#########################################################################
sub check_ref
    {
    my( $p, $txt ) = @_;
    my $r =
	( !defined($p)
	? "Undefined"
	: !ref($p)
	? "Simple variable $p"
	: ref($p)." pointer" );
    if( $r ne "$txt pointer" )
        {
	&COMMON::stack_trace("$r instead of $txt pointer");
	exit(1);
	}
    }

#########################################################################
#	Returns true if item is in list.  Prettier than straight grep	#
#########################################################################
sub in_list
    {
    my( $item, @lst ) = @_;
    return ( grep( $_ eq $item, @lst ) ? 1 : 0 );
    }

#########################################################################
#	Output debug information or not.				#
#########################################################################
sub debout
    {
    my( $lnum, $msg ) = @_;
    #print "\n#", $lnum, ":  ", $msg, "\n";
    }

#########################################################################
#	Return an array of tokens from supplied string according to:	#
#		Text within "s are returned as one token.		#
#		Groups of letters and digits are returned as one token.	#
#		Everything else except white space is returned as 1	#
#		    token per character.				#
#########################################################################
sub tokenize
    {
    my( $str ) = @_;
    my $inquote = 0;
    my $string_so_far="";
    my @ret;
    #&debout(__LINE__,"tokenize($str)");
    foreach my $c ( split(//,$str) )
	{
        if( $c eq "\"" )
	    { $inquote = 1 - $inquote; }
	elsif( $inquote )
	    { $string_so_far .= $c; }
	elsif( $c =~ /\s/ )
	    {
	    push( @ret, $string_so_far ) if( $string_so_far ne "" );
	    $string_so_far="";
	    }
	elsif( $c =~ /[A-Za-z0-9_]/ )
	    { $string_so_far .= $c; }
	else
	    {
	    push( @ret, $string_so_far ) if( $string_so_far ne "" );
	    push( @ret, $c );
	    $string_so_far = "";
	    }
	}
    push( @ret, $string_so_far ) if( $string_so_far ne "" );
    #&debout(__LINE__,"tokenize($str) returns [".join(",",@ret)."]");
    return @ret;
    }

#########################################################################
#	Converts double new lines to new paragraphs, little else.	#
#########################################################################
sub fix_html
    {
    my($ret,$chopflag) = @_;
    if( ! defined($ret) )
        { $ret = "[UNDEFINED]"; }
    else
        {
        #$ret =~ s/^\s*//g; $ret =~ s/\s*$// if( $chopflag );
	$ret =~ s/\n\n+/\n<p>/gs;
	}
    return $ret;
    }

#########################################################################
#	Go to the next page and create a header that will appear in	#
#	the printable table of contents.				#
#########################################################################
sub new_page
    {
    my( $text ) = @_;
    if( $ENV{HTTP_USER_AGENT} && $ENV{HTTP_USER_AGENT} =~ /wkhtmltopdf/ )
        {
	return join("",
	    "<center><table class=newpage width=70% border=0 cellspacing=0>",
	    "<tbody><tr><th><h1>",
	    $text,
	    "</h1></th></tr></tbody></table></center>" );
	}
    else
        { return join("","<hr><h1 class=chapter align=center>",$text,"</h1>\n"); }
    }

#########################################################################
#	Create HTML for a starting a centered table.			#
#########################################################################
sub centered_table_begin
    {
    my( $width ) = @_;
    &sub_buf("<center><table border=0 width=${width}><tbody>",
    		"<tr><td width=100%>");
    }

#########################################################################
#	Create HTML for a ending a centered table.			#
#########################################################################
sub centered_table_end
    {
    &sub_buf("</td></tr></tbody></table></center>");
    }

#########################################################################
#	Used for debug output to avoid errors going to STDERR.		#
#########################################################################
sub orundef
    {
    my( $thing ) = @_;
    return ( defined($thing) ? $thing : "UNDEF" );
    }

#########################################################################
#	Print an object, may recurse if array or hash.			#
#########################################################################
my %print_seen;
sub print_tree
    {
    my( $ptr, $name, $lvl ) = @_;
    $lvl || open(OUT,">$DEBUG_FILE") || die("Cannot write $DEBUG_FILE:  $!");
    print OUT "  "x$lvl, $name, " ";
    if( ! defined( $ptr ) )
        { print OUT "{UNDEFINED}\n"; }
    elsif( ref( $ptr ) eq "HASH" )
        {
	print OUT "HASH ",($ptr->{id}||$ptr),"\n";
	if( ! $print_seen{$ptr}++ )
	    {
	    my %print_seen_fld;
	    foreach my $f ( "id", "clause_type", sort keys %{$ptr} )
		{
		next if( $f eq "all" || $print_seen_fld{$f}++ );
		print_tree( $ptr->{$f}, $name."{".$f."}", $lvl+1 );
		}
	    }
	}
    elsif( ref( $ptr ) eq "ARRAY" )
        {
	print OUT "ARRAY ",$ptr,"\n";
	if( ! $print_seen{$ptr}++ )
	    {
	    my $i = 0;
	    foreach my $elem ( @{$ptr} )
		{
		print_tree( $elem, $name."[".$i++."]", $lvl+1 );
		}
	    }
	}
    else
        { print OUT "VALUE=(", $ptr, ")\n"; }
    $lvl || close( OUT );
    }

#########################################################################
#	Recursively go through token list creating tree of clauses.	#
#########################################################################
my $parse_file_ind = 0;
my @parse_file_pieces;
my $parse_file_opens;
my $parse_file_closes;
sub parse_file_recurse
    {
    my( $ptr, $l4, $lvl ) = @_;
    while( $parse_file_ind < @parse_file_pieces )
        {
	my $p = $parse_file_pieces[$parse_file_ind++];
	if( $p eq $l4 )
	    { last; }
	else
	    {
	    next if( $p =~ /^[\s]*$/ );	# Skip empty tokens
	    #my %node = ( data=>$p, id=>$parse_file_ind+10000 );
	    my %node = ( parent=>$ptr, id=>$parse_file_ind+10000 );
	    my $clause_type;
	    push( @{$ptr->{"all"}}, \%node );
	    if( $p !~ /$parse_file_opens/ || $p !~ /<([a-zA-Z0-9_]+)(.*?)>/s )
	        {
		$clause_type = "other";
		if( defined($ptr->{body}) )
		    { $ptr->{body} .= $p; }
		else
		    { $ptr->{body} = $p; }
		$node{text} = $p;
		}
	    else
		{
		$clause_type = $1;
		$node{descriptor_string} = $2;
		my @tokens = &tokenize( $2 );
		my $has_contents = 1;
		my $tok;
		while( defined( $tok = shift(@tokens) ) )
		    {
		    if( $tok eq "/" )
		        { $has_contents = 0; }
		    elsif( defined($tokens[0]) && $tokens[0] eq "=" )
		        {
			shift @tokens;
			push( @{$node{attribute_list}}, $tok );
			if( ! defined($node{$tok}) )
			    { $node{$tok} = shift(@tokens); }
			else
			    { $node{$tok} .= ("," . shift(@tokens)); }
			}
		    else
		        {
			push( @{$node{attribute_list}}, $tok );
			$node{$tok} = 1;
			}
		    }
		&parse_file_recurse(\%node,"</".$clause_type.">",$lvl+1)
		    if( $has_contents );
		}
	    $node{clause_type} = $clause_type;
	    push( @{$ptr->{$clause_type."s"}}, \%node );
	    $has_clause_type{$clause_type} = 1;
	    $ptr->{$clause_type} = \%node;
	    }
	}
    }

#########################################################################
#	Split file up on basis of clauses and then invoke recursive	#
#	tree generator.							#
#########################################################################
sub parse_file
    {
    my( $contents ) = @_;
    my %top = ( "id"=>"TOP", "clause_type"=>"TOP" );

    $parse_file_opens	= join( "|", map { "(<".$_."[^>]*>)" } @KNOWN_CLAUSES );
    $parse_file_closes	= join( "|", map { "(</$_>)" } @KNOWN_CLAUSES );

    @parse_file_pieces = grep(defined($_),
	split(/$parse_file_opens|$parse_file_closes/s,$contents));
    &parse_file_recurse( \%top, "mango", 0 );
    return \%top;
    }


#########################################################################
#	Add a new name to the name table.				#
#########################################################################
sub add_to_name_table
    {
    my( $bookp, $var, $modifier, $value ) = @_;
    if( !defined($bookp)
     || !defined($var) || ref($var) ne ""
     || !defined($modifier) || ref($modifier) ne ""
     || !defined($value) || ref($value) ne "" )
        {
	print STDERR
	    "bookp=",($bookp?"GOOD":"UNDEF"),
	    " var=",(!$var?"UNDEF":ref($var) ne ""?ref($var):"'$var'"),
	    " modifier=",(!$modifier?"UNDEF":ref($modifier) ne ""?ref($modifier):"'$modifier'"),
	    " value=",(!$value?"UNDEF":ref($value) ne ""?ref($value):"'$value'"),
	    "\nStack trace\n\t",
	    join("\n\t",&COMMON::get_trace()),
	    "\n";
	}
    #print "CMC Adding {$var,$modifier}=$value.\n";
    if( $var eq "timeline" )
	{
	$bookp->{vars}{$var}{$modifier} = $value;
	&parse_time_string("$modifier=$value");
	}
    elsif( $modifier =~ /^[A-Z_]\w*$/ || $modifier =~ /^\d+$/ )
	{ $bookp->{vars}{$var}{$modifier} = $value; }
    else
        {
	# &COMMON::fatal("Do not know how create '$modifier' value for '$var'.");
	}
    }

#########################################################################
#	Return phonetic version of supplied string.			#
#########################################################################
sub PHONETIC
    {
    my( @args ) = @_;
    return join("-",
		    map( (defined($PHONETICS{$_})?$PHONETICS{$_}:$_),
			split(//,join(",",@args))
		    )
		);
    }

#########################################################################
#	Supply whatever unit NAME is used where supplied name would be	#
#	used in metric.							#
#########################################################################
sub METAUNITS
    {
    my( $unit_name ) = @_;
    my $sval;
    if( $UTYPE eq $BASETYPE )
	{ $sval = $unit_name; }
    elsif( ! defined($sval = $SUBUNIT{$UTYPE}{$unit_name}) )
	{ $sval = "<font color=red><blink>$unit_name</blink></font>"; }
    else
        { $sval = $unit_name; }
    return $sval;
    }

#########################################################################
#	Return value with units converted to whatever unit type we're	#
#	displaying in.							#
#########################################################################
sub anyunit
    {
    my( $func, @args ) = @_;
    my ( $oldval ) = $args[0];
    my ( $oldunits ) = $args[1];
    my ( $cptr, $v, $u );
    my $bunit = $oldunits;
    my $rep;
    $bunit =~ tr/A-Z/a-z/;
    $bunit = $SINGULARS{$bunit} if( $SINGULARS{$bunit} );
    if( $func eq "METRICENGLISH" )
	{
	$rep = ( $UTYPE ne "Metric" ? $args[1] : $args[0] );
	}
    elsif( $UTYPE eq $BASETYPE )
	{
	$v = $oldval;
	$v = join("-",
	    map( (defined($PHONETICS{$_})?$PHONETICS{$_}:$_),
		split(//,$v)
	    )
	) if( $func =~ /^P/ );
	$rep = "$v $oldunits";
	}
    else
	{
	foreach $cptr ( @{$UTABLE{$UTYPE}} )
	    {
	    if( ($bunit eq ${$cptr}{ounit})	&&
		($oldval >= ${$cptr}{minv})	&&
		($oldval <= ${$cptr}{maxv})	)
		{
		$v = $oldval * ${$cptr}{mul};
		$v += ${$cptr}{add}
		    if( $func eq "UNITS" || $func eq "PUNITS" );
		$u = ${$cptr}{nunit};
		$u = $PLURALS{$u} if( $v != 1 );
		if( $v >= 1000000 )
		    { $v = int($v/10000)*10000; }
		elsif( $v >=100000 )
		    { $v = int($v/1000)*1000; }
		elsif( $v >=10000 )
		    { $v = int($v/100)*100; }
		elsif( $v >=1000 )
		    { $v = int($v/10)*10; }
		elsif( $v >=100 )
		    { $v = sprintf("%3.0f",$v); }
		elsif( $v >=10 )
		    { $v = sprintf("%4.1f",$v); }
		elsif( $v >=1 )
		    { $v = sprintf("%4.2f",$v); }
		elsif( $v >=0.1 )
		    { $v = sprintf("%4.3f",$v); }
		elsif( $v >=0.01 )
		    { $v = sprintf("%5.4f",$v); }
		elsif( $v >=0.001 )
		    { $v = sprintf("%6.5f",$v); }
		else
		    { $v = sprintf("%7.6f",$v); }
		$v = join("-",
		    map( (defined($PHONETICS{$_})?$PHONETICS{$_}:$_),
			split(//,$v)
		    )
		) if( $func =~ /^P/ );
		$rep =  "$v $u";
		last;
		}
	    }
	$rep = "<font color=red><blink>$oldval $oldunits</blink></font>"
		if( ! defined($rep) );
	}
    return $rep;
    }

#########################################################################
#	Some handy functions you can embed in your script.		#
#########################################################################
sub UNITS		{ return &anyunit("UNITS",@_); }
sub PUNITS		{ return &anyunit("PUNITS",@_); }
sub CHANGEUNITS		{ return &anyunit("CHANGEUNITS",@_); }
sub PCHANGEUNITS	{ return &anyunit("PCHANGEUNITS",@_); }
sub METRICENGLISH	{ return &anyunit("METRICENGLISH",@_); }
sub INITIAL		{ return uc( substr( $_[0], 0, 1 ) ); }
sub UCFIRST		{ return ucfirst( @_ ); }
sub GENDER_TITLE	{ return {male=>"Mr.",female=>"Ms."}->{$_[0]} || "Mx."; }
sub CREF		{ return $_[0]; }
sub TREF		{ return ( defined($_[1]) ? $_[1] : $_[0] ); }

#########################################################################
#	Do all substitutions on a string.				#
#########################################################################
sub do_subs
    {
    my( $bookp, $str ) = @_;

    my %subs;
    my @fmap = map { "$_\\(.*?\\)" } @FUNCS;
    grep( $subs{$_}="@", @fmap );
    #my $sstr = join("|","\\{.*?,.*?\\}",keys %subs);
    my $sstr = join("|",keys %subs);

#    print STDERR "FUNCS=[",join(",",@FUNCS),"]<br>\n";
#    print STDERR "fmap=[",join(",",@fmap),"]<br>\n";
#    print STDERR "subs=[",join(",",keys %subs),"]<br>\n";
#    print STDERR "sstr=[$sstr]\n";

    my @done;
    my @todo = split(/(\{\w+,\w+\})/,$str);
    while( @todo )
        {
	my $pc = shift(@todo);
	if( $pc !~ /^{(\w+),(\w+)}$/ )
	    { push( @done, $pc ); }
	else
	    {
	    my $variable = $1;
	    my $modifier = $2;

	    if( $variable eq "DUMP" && $modifier eq "DUMP" )
	        {
		push( @done, &var_dump($bookp) );
		next;
		}

	    my $found;
	    while( ! ($found=$bookp->{vars}{$variable}{$modifier})
		&& $bookp->{vars}{$variable}{SYNONYM} )
		{ $variable=$bookp->{vars}{$variable}{SYNONYM}; }

	    if( ! $found )
	        {
		$found =
		    {
		    # REALLY icky defaults
		    GENDER	=> "male",
		    JOB		=> "person",
		    FIRST	=> "John",
		    LAST	=> "Doe",

		    MIDDLE	=> " ",
		    FI_LAST	=> "INITIAL({$variable,FIRST}) {$variable,LAST}",
		    FI_MI_LAST	=> "INITIAL({$variable,FIRST}) INITIAL({$variable,MIDDLE}) {$variable,LAST}",
		    FULL	=> "{$variable,FIRST} {$variable,MIDDLE} {$variable,LAST}",
		    NICK	=> "{$variable,FIRST}",
		    NICKFULL	=> "{$variable,NICK} {$variable,MIDDLE} {$variable,LAST}",
		    FULLER	=> "{$variable,TITLE} {$variable,LAST}",
		    FULLEST	=> "{$variable,TITLE} {$variable,FULL}",
		    CUTE	=> "{$variable,TITLE} {$variable,NICK}",
		    TITLE	=> "GENDER_TITLE({$variable,GENDER})",
		    REF		=> "{$variable,FULL}" } -> {$modifier}
		}

	    if( defined($found) )
		{ unshift( @todo, split(/(\{\w+,\w+\})/,$found) ); }
	    else
		{ push( @done, "-U:$variable,$modifier-" ); }
	    }
	}

    my @newlist;
    my @args;
    foreach my $piece ( split(/($sstr)/ms,join("",@done) ) )
	{
	#print STDERR "piece=[$piece]<br>\n";
	my $res;
	if( !defined( $piece ) )		{ }
	elsif( defined($subs{$piece}) )		{ $res = $subs{$piece}; }
	elsif( $piece !~ /^(.*?)\((.*)\)/ || !&in_list($1,@FUNCS) )
	    					{ $res = $piece; }
	elsif( ! ( @args = split(/,/,&do_subs($bookp,$2)) ) )
	    					{ }
	elsif($1 eq "METAUNITS")		{ $res = &METAUNITS(@args); }
	elsif( &in_list($1,"UNITS","PUNITS","CHANGEUNITS","PCHANGEUNITS","METRICENGLISH") )
						{ $res = &anyunit($1,@args); }
	elsif($1 eq "TIMELINE")			{ $res = &timeline_ref(@args); }
	elsif($1 eq "UCFIRST")			{ $res = &UCFIRST(@args); }
	elsif($1 eq "INITIAL")			{ $res = &INITIAL(@args); }
	elsif($1 eq "GENDER_TITLE")		{ $res = &GENDER_TITLE(@args); }
	elsif($1 eq "CREF")			{ $res = &CREF(@args); }
	elsif($1 eq "TREF")			{ $res = &TREF(@args); }
	elsif($1 eq "PHONETIC")			{ $res = &PHONETIC(@args); }
	else
	    {
	    print "Something went wrong (don't recognize [$1]).\n";
	    exit(1);
	    }

	if( defined($res) )
	    { push( @newlist, $res ); }
	else
	    {
	    my $err = ( defined($piece) ? "[U:$piece]" : "[U]" );
	    push( @newlist, $err );
	    push( @errlist, "Undefined:  $err" );
	    }
	}
    return join("",@newlist);
    }

#########################################################################
#	Create tree for <text>s in either chapters or subchapters.	#
#########################################################################
sub parse_texts
    {
    my( $parent_ptr ) = @_;
    foreach my $child_ptr ( @{$parent_ptr->{texts}} )
	{
	$child_ptr->{color} ||= $parent_ptr->{color};
	foreach my $textp ( @{$child_ptr->{all}} )
	    {
	    $textp->{color} ||= $child_ptr->{color};
	    my $clause_type = $textp->{clause_type};
	    }
	#push( @{$parent_ptr->{ $clause_type }}, $textp );
	}
    }

#########################################################################
#########################################################################
sub traverse_tree
    {
    my( $lvl, $fnc, $parent_ptr, $my_ptr, @args ) = @_;

    #print "CMC traverse_tree(lvl=", $lvl, " parent=",$parent_ptr->{id},",",$my_ptr->{id},",",$my_ptr->{clause_type},",)<br>\n";
    &{$fnc}( $lvl, $parent_ptr, $my_ptr, 0, $my_ptr->{clause_type}, @args );

    if( defined( $my_ptr->{all} ) )
	{
	foreach my $kid_ptr ( @{$my_ptr->{all}} )
	    { &traverse_tree( $lvl+1, $fnc, $my_ptr, $kid_ptr, @args ); }
	}

    &{$fnc}( $lvl, $parent_ptr, $my_ptr, 1, $my_ptr->{clause_type}, @args );
    }

#########################################################################
#########################################################################
sub work_tree
    {
    my( $fnc, $top, @args ) = @_;
    #print "CMC Work_tree fnc=$fnc top=", $top->{id}, ".<br>\n";
    foreach my $workp ( &generate_work_list($top) )
        {
	my $my_ptr = $workp->{story};
	&traverse_tree(0,$fnc,$top,$my_ptr,@args);
	}
    #print "CMC End work_tree fnc=$fnc top=", $top->{id}, ".<br>\n";
    }

#########################################################################
#	Add useful fields to a node in a tree from the XML file.	#
#########################################################################
my $cameraid = 0;
my %default_colors = ( "colors"=>join(",",@COLOR_LIST) );
sub fix_tree_entry
    {
    my( $lvl, $parent_ptr, $my_ptr, $done_flag, $clause_type ) = @_;

    #print "CMC fix_tree_entry(lvl=",$lvl,",id=",$my_ptr->{id},",ct=",$my_ptr->{clause_type},",doneflag=",$done_flag,").<br>\n";

    return if( $done_flag );

    #print "CMC fix_tree_entry($clause_type) executing.<br>\n";
    
    my $colp;
    if( $my_ptr->{colors} )
        { $colp = $my_ptr; }
    elsif( $parent_ptr->{colorp} )
        { $colp = $parent_ptr->{colorp}; }
    else
        { $colp = \%default_colors; }
    $my_ptr->{colorp} = $colp;
    $my_ptr->{block_id} = $parent_ptr->{block_id};
    $my_ptr->{story_id} = $parent_ptr->{story_id};
    $my_ptr->{chapter_id} = $parent_ptr->{chapter_id};
    $my_ptr->{subchapter_id} = $parent_ptr->{subchapter_id};

    if( $clause_type eq "story" )
	{
	#print "CMC story logic, name=", $my_ptr->{name}, ".<br>\n";
	$my_ptr->{story_id} = $my_ptr->{block_id} = ++$parent_ptr->{story_ind};
	$my_ptr->{chapter_ind} = $my_ptr->{subchapter_ind} = 0;

	#print "CMC pre setvar add_to_name_table loop.<br>\n";
	foreach my $setvarp ( @{$my_ptr->{setvars}} )
	    {
	    #print "CMC [",(map{" $_=$setvarp->{$_}<br>"} keys %{$setvarp}),"]\n";
	    #foreach my $setvarpk ( keys %{$setvarp} )
	    foreach my $setvarpk ( @{$setvarp->{attribute_list}} )
	        {
		if( grep( $_ eq $setvarpk,
		    qw(id chapter_id subchapter_id colorp name parent descriptor_string clause_type) ) )
		    {}
		elsif( $setvarpk eq "modifier" )
		    {
		    &add_to_name_table(
			$my_ptr,
			$setvarp->{name},
			$setvarp->{modifier},
			$setvarp->{value}
			);
		    }
		elsif( $setvarpk eq "value" )
		    {}
		else
		    {
		    &add_to_name_table(
			$my_ptr,
			$setvarp->{name},
			$setvarpk,
			$setvarp->{$setvarpk}
			);
		    }
		}
	    }
	#print "CMC Post setvar add_to_name_table loop.<br>\n";
	}

    elsif( $clause_type eq "chapter" )
	{
	#print "CMC chapter logic.<br>\n";
	if( $my_ptr->{time} )
	    {
	    &parse_time_string($my_ptr->{time});
	    $my_ptr->{timestring} = &show_timeline( $STORY_TIME_FMT, $current_timeline );
	    }
	$my_ptr->{chapter_id} = ++($parent_ptr->{chapter_ind});
	$my_ptr->{subchapter_ind} = 0;
	$my_ptr->{block_id} =
	    ( $SHOW{storyid}
	    ? join(".",$my_ptr->{story_id},$my_ptr->{chapter_id})
	    : $my_ptr->{chapter_id}
	    );
	$my_ptr->{fullname} =
	    ( $my_ptr->{name}
	    ? $my_ptr->{block_id} . ":  " . $my_ptr->{name}
	    : $my_ptr->{block_id}
	    );
	#print "CMC setting chapter fullname to [", $my_ptr->{fullname}, "].<br>\n";
	}
    
    elsif( $clause_type eq "subchapter" )
	{
	#print "CMC subchapter logic.<br>\n";
	if( $my_ptr->{time} )
	    {
	    &parse_time_string($my_ptr->{time});
	    $my_ptr->{timestring} = &show_timeline( $STORY_TIME_FMT, $current_timeline );
	    }
	$my_ptr->{subchapter_id} = ++($parent_ptr->{subchapter_ind});

	if( ! $colp->{color_array} )
	    {
	    @{$colp->{color_array}} = split(/,/,$colp->{colors});
	    $colp->{color_ind} = 0;
	    }

	$my_ptr->{color} =
	    ${$colp->{color_array}}[
		$colp->{color_ind}++
		% scalar(@{$colp->{color_array}})
		];

	$my_ptr->{block_id} =
	    join(".",
		( $SHOW{storyid}
		? ($my_ptr->{story_id},$my_ptr->{chapter_id})
		: $my_ptr->{chapter_id}
		), $my_ptr->{subchapter_id});
	$my_ptr->{fullname} =
	    ( $SHOW{subchapter_names} && defined($my_ptr->{name})
	    ? $my_ptr->{block_id} . ":  " . $my_ptr->{name}
	    : $my_ptr->{block_id}
	    );
	#print "CMC setting subchapter fullname to [", $my_ptr->{fullname}, "].<br>\n";
	}

    elsif( $clause_type eq "camera" )
	{
	#print "CMC camera logic.<br>\n";
	$my_ptr->{camera_id} = ++$cameraid;
	}

    elsif( &in_list( $clause_type, @TEXT_PRIMITIVES ) )
	{
	if( &in_list( $clause_type, "footnote", "comment", "reference" ) )
	    {
	    $my_ptr->{$clause_type."_id"} = join(".",
		$parent_ptr->{block_id},
		++($parent_ptr->{$clause_type."_ind"}));
	    }
	}

    else
        {
	#print "CMC Ignoring $clause_type logic.<br>\n";
	}
    }

#########################################################################
#	Add useful fields to the tree from the XML file.		#
#########################################################################
sub fix_tree
    {
    my( $top_ptr, @args ) = @_;
    #&status("Beginning fix_tree");
    #&traverse_tree( 0, \&fix_tree_entry, undef, $top_ptr, @args );
    &work_tree( \&fix_tree_entry, $top_ptr, @args );
    #&status("End fix_tree");
    }

#########################################################################
#	Return a link or just the text in the link depending on		#
#	$SHOW{links}							#
#########################################################################
sub alink
    {
    my( $name, $href, $text ) = @_;
    my @parts;
#    print "alink(",
#        &orundef($name), ",",
#	&orundef($href), ",",
#	&orundef($text), ")<br>\n";
    if( $SHOW{links} )
        {
	push( @parts, "<a" );
	push( @parts, " name='", $name, "'" ) if( defined($name) );
	push( @parts, " href='", $href, "'" ) if( defined($href) );
	push( @parts, ">" );
	}
    push( @parts, &orundef($text) );
    push( @parts, "</a>" ) if( $SHOW{links} );
    return join("",@parts);
    }

#########################################################################
#########################################################################
sub link_to_body  { return &alink("T".$_[0]->{id}, "#B".$_[0]->{id}, $_[1]); }
sub link_to_table { return &alink("B".$_[0]->{id}, "#T".$_[0]->{id}, $_[1]); }

#########################################################################
#	Creates a list of story/chapters to form a book.		#
#########################################################################
sub generate_work_list
    {
    my( $top ) = @_;
    my @ret_todo;
    foreach my $bookp ( @{$top->{books}} )
        {
	foreach my $fromp ( @{$bookp->{froms}} )
	    {
	    my $found_story = 0;
	    foreach my $sp ( @{$top->{storys}} )
	        {
		if( $sp->{name} eq $fromp->{story} )
		    {
		    my %topush = ( "story"=>$sp );

		    if( $fromp->{title} && $fromp->{title} ne "1" )
		        { $topush{title} = $fromp->{title}; }
		    elsif( defined( $fromp->{title} ) )
		        { $topush{title} = $sp->{name}; }

		    my $offon = ( $fromp->{first} ? 0 : 1 );
		    foreach my $cp ( @{$sp->{chapters}} )
		        {
			$offon = 1
			    if( $fromp->{first} &&
				$cp->{name} eq $fromp->{first} );
			push( @{$topush{chapters}}, $cp ) if( $offon );
			$offon = 0
			    if( $fromp->{last} &&
				$cp->{name} eq $fromp->{last} );
			}
		    push( @ret_todo, \%topush );
		    $found_story = 1;
		    last;
		    }
		}
	    &COMMON::fatal( "Story '". $fromp->{story}. "' not available." )
	        if( ! $found_story );
	    }
	}
    if( ! @ret_todo )
        {
	foreach my $sp ( @{$top->{storys}} )
	    {
#	    my %topush = ( "story"=>sp );
#	    @{$topush{chapters}} = @{$sp->{chapters}};
#	    push( @ret_todo, \%topush );
	    push( @ret_todo, {"story"=>$sp,"chapters"=>\@{$sp->{chapters}}} );
	    #print "CMC backstopping in story: ", $sp->{name}, "\n";
	    }
	}
    if( 0 )
        {
	print "CMC Work list:<br>\n";
	foreach my $p ( @ret_todo )
	    {
	    print "CMC story=", $p->{story}->{name}, ".<br>\n";
	    foreach my $c ( @{$p->{chapters}} )
	        {
		print "CMC chapter=", $c->{fullname}, ".<br>\n";
		}
	    }
	}
    return @ret_todo;
    }

#########################################################################
#	Queue up stuff to be printed.  Done so we can do some last	#
#	minute substitutions.						#
#########################################################################
my @pre_sub_buffer;
sub sub_buf
    {
    #print "CMC sub_buf[", @_, "]<br>\n";
    push( @pre_sub_buffer, @_ );
    }

#########################################################################
#########################################################################
sub status
    {
    push( @pre_sub_buffer, "\n<br><b>", @_, "</b><br>\n" );
    }

#########################################################################
#	Print whatever has been buffered up after doing substitutions	#
#	relative to the story they were generated in.			#
#########################################################################
my $last_story;
sub print_buf
    {
    my( $current_story ) = @_;
#    print "print_buf called with last_story=",
#        ( $last_story ? $last_story->{name} : "undef" ),
#	" and current_story=",
#	( $current_story ? $current_story->{name} : "undef" ),
#	" and ", scalar(@pre_sub_buffer), " records.\n";
    if( @pre_sub_buffer )
        {
#	print "CMC print_buf last_story=",
#	    ( defined($last_story) ? $last_story->{name} : "UNDEF" ),
#	    " current_story=",
#	    ( defined($current_story) ? $current_story->{name} : "UNDEF" ),
#	    ".<br>\n";
	if( ! $last_story )
	    {
	    print @pre_sub_buffer;
	    @pre_sub_buffer = ();
	    }
	elsif( $last_story ne ($current_story||0) )
	    {
	    print &do_subs( $last_story,
		join(
		    "",
		    map { defined($_) ? $_ : "[UNDEF]" } @pre_sub_buffer
		    ) );
	    @pre_sub_buffer = ();
	    }
	}
    $last_story = $current_story;
    }

#########################################################################
#	Prints a simple TOC entry (for pages not in story).		#
#########################################################################
sub simple_toc_line
    {
    my( $fld, $txt ) = @_;
    my $flds = $fld."s";
    my $flag = ( $SHOW{$fld}?$fld : $SHOW{$flds}?$flds : 0 );
    &sub_buf(
        "<tr><td>",
	&alink("T".$fld,"#B".$fld,$txt||ucfirst($flag)),
	"</td></tr>\n") if( $has_clause_type{$fld} && $flag );
    }

#########################################################################
#	Print toc from array of parts.					#
#########################################################################
sub print_toc
    {
    my( $top ) = @_;

    &sub_buf( &new_page("Table of Contents"),
	"<center><table width=85% frame=border border=0 cellspacing=0>",
	"<tbody>\n" );
    grep( &simple_toc_line($_),
	("title","copyright","promotion","overview","dedication") );
    foreach my $workp ( &generate_work_list($top) )
	{
	&print_buf( $workp->{story} );
	&sub_buf( "<tr><th>", $workp->{title}, "</th></tr>" )
	    if( $workp->{title} );
	foreach my $storyp ( @{$workp->{chapters}} )
	    {
	    &sub_buf( "<tr><td>", &link_to_body( $storyp, $storyp->{fullname} ) );
	    &sub_buf( "</td><td width=50%>", $storyp->{timestring} ) if( $storyp->{timestring} );
	    &sub_buf( "</td></tr>\n" );

	    if( $SHOW{subchapters} )
		{
		foreach my $chapterp ( @{$storyp->{subchapters}} )
		    {
		    &sub_buf( "<tr $COLFLAG='",
			$chapterp->{color},
			"'><td>", &link_to_body($chapterp,$chapterp->{fullname}) );
		    &sub_buf( "</td><td width=50%>", $chapterp->{timestring} )
			if( $chapterp->{timestring} );
		    &sub_buf( "</td></tr>\n" );
		    }
		}
	    }
	}
    grep( &simple_toc_line($_), @TEXT_PRIMITIVES, "camera" );
    &simple_toc_line("creator_info","Created by");
    &sub_buf( "</tbody></table></center>\n" );
    }

#########################################################################
#	Create a name usable by the Graphviz system.			#
#########################################################################
sub name_to_id
    {
    my( $id ) = @_;
    return '"' . $id . '"';
    $id =~ s/'s/s/g;
    $id =~ s/[^a-zA-Z0-9]/_/g;
    $id =~ s/__*/_/g;
    $id = $1 if( /^_*\(.*?\)_*$/ );
    $id = "_".$id if( $id =~ /^\d/ );
    return $id;
    }

#########################################################################
#########################################################################
my @flow_nodes;
my %current_threads = ( "order"=>1 );
my $last_thread_string = "";
my %thread_color;
sub one_flow
    {
    my( $bookp, $curp ) = @_;
    if( $curp->{name} )
        {
	my $current_name = &do_subs( $bookp, $curp->{name} );
	foreach my $state_changer ( "open", "mention", "resume" )
	    {
#	    grep( $current_threads{$_}=1, split(/,/,$curp->{$state_changer}) )
#		if( $curp->{$state_changer} );
	    if( $curp->{$state_changer} )
	        {
		foreach my $state_changer_val ( split(/,/,$curp->{$state_changer}) )
		    {
		    $current_threads{$state_changer_val} = 1;
		    print STDERR "Add name=$curp->{name} $state_changer $state_changer_val\n";
		    }
		}
	    }
	my $thread_string = join(",",sort keys %current_threads);
	if( $last_thread_string eq $thread_string )
	    { $flow_nodes[$#flow_nodes]{name} .= "\n$current_name"; }
	else
	    {
	    push( @flow_nodes,
	        {
		id		=> &name_to_id( $current_name ),
		name		=> $current_name,
		threads		=> { %current_threads }
		} );
	    $last_thread_string = $thread_string;
	    }
	push( @{$flow_nodes[$#flow_nodes]{nodes}}, $curp );

	foreach my $state_changer ( "close", "mention", "pause" )
	    {
#	    grep( delete $current_threads{$_}, split(/,/,$curp->{$state_changer}) )
#		if( $curp->{$state_changer} );
	    if( $curp->{$state_changer} )
	        {
		foreach my $state_changer_val ( split(/,/,$curp->{$state_changer}) )
		    {
		    delete $current_threads{$state_changer_val};
		    print STDERR "Del name=$curp->{name} $state_changer $state_changer_val\n";
		    }
		}
	    }
	my $last_thread_string = join(",",sort keys %current_threads);
	}
    }

##########################################################################
##	Return N bit color code based on index.  The idea is that	#
##	Colors with low numbers are more different than those with	#
##	high numbers.							#
##	For 24 bit color (nbit=24), width=8.				#
##	Tries to handle nbit%3!=0 reasonably (e.g. 8 bit color)		#
##	but not well tested.						#
##########################################################################
#my $COLOR_CHANNELS = 3;
#my @unique_nbit_shifters;
#my @unique_nbit_index;
#sub unique_nbit_color
#    {
#    my( $val, $nbit ) = @_;
#    $nbit ||= 24;
#    $val = $unique_nbit_index[$nbit]++ if( ! defined($val) );
#    if( ! $unique_nbit_shifters[$nbit] )
#        {
#	my $minwidth = int( $nbit / $COLOR_CHANNELS );
#	my $extra_bits = $nbit % $COLOR_CHANNELS;
#	my $chan;
#	my @width;
#	for( $chan=0; $chan<$COLOR_CHANNELS; $chan++ )
#	    {
#	    $width[$chan] = $minwidth + ($chan<$extra_bits?1:0);
#	    }
#	my $base = 0;
#	my @bitnum;
#	while( --$chan >= 0 )
#	    {
#	    $base += $width[$chan];
#	    $bitnum[$chan] = $base;
#	    }
#	my @offsets;
#	for( my $i=0; $i<$nbit; $i++ )
#	    {
#	    push( @offsets, 1<<--$bitnum[ ++$chan%$COLOR_CHANNELS ] );
#	    }
#	$unique_nbit_shifters[$nbit] = \@offsets;
#	}
#
#    my $res = 0;
#    for( my $ind=0; $val; $ind++ )
#        {
#	$res |= $unique_nbit_shifters[$nbit][$ind] if( $val & 1 );
#	$val >>= 1;
#	}
#    return $res;
#    }

#########################################################################
#	Print flow file from array of parts.				#
#########################################################################
sub print_flow
    {
    my( $top ) = @_;

    # Go through all the relevent nodes in the tree assigning convenient names.
    my @work_list = &generate_work_list($top);
    my $bookp = $work_list[0]->{story};
    foreach my $workp ( @work_list )
	{
	&one_flow( $bookp, $workp );
	foreach my $storyp ( @{$workp->{chapters}} )
	    {
	    &one_flow( $bookp, $storyp );
	    foreach my $chapterp ( @{$storyp->{subchapters}} )
	        { &one_flow( $bookp, $chapterp ); }
	    }
	}

    # This forces the "order" thread to be black
    $thread_color{"order"} = sprintf("#%06x",&unique_nbit_color());

    &sub_buf( "<pre>\ndigraph \"",
	    &follow_chain("Untitled","name"),
	    "\" {\n" );
    # Go through all the relevent flow_nodes and connect the ones in threads
    for( my $node_ind_0=0; $node_ind_0<scalar(@flow_nodes); $node_ind_0++ )
        {
	my $node0p = $flow_nodes[$node_ind_0];
	my $fixedname = $node0p->{name};	# Should be able to do a labeljust=l
	#$fixedname =~ s/\n/\\l\n/gms;
	$fixedname =~ s/\n/\\l/gms;
	&sub_buf( $node0p->{id},
	    " [ shape=\"box\" label=\"$fixedname\\l\" ];\n" );
	foreach my $thread ( sort keys %{ $node0p->{threads} } )
	    {
	    for( my $node_ind_1=$node_ind_0+1; $node_ind_1<scalar(@flow_nodes); $node_ind_1++ )
	        {
		my $node1p = $flow_nodes[$node_ind_1];
		if( $node1p->{threads}{$thread} )
		    {
		    $thread_color{$thread} = sprintf("#%06x",&unique_nbit_color())
			if( ! defined($thread_color{$thread}) );
		    &sub_buf( $node0p->{id}, " -> ", $node1p->{id},
			" [ color=\"$thread_color{$thread}\" ",
			( $thread eq "order"
			    ? "penwidth=3"
			    : "label=\"$thread\""
			),
			" ];\n" );
		    last;
		    }
		}
	    }
        }
    &sub_buf( "}\n</pre>\n" );
    &print_buf();
    }

#########################################################################
#	Print headings for a table, keep track of columns.		#
#########################################################################
sub print_headings
    {
    &sub_buf( "<tr><th>", join("</th><th>",@_), "</th></tr>" );
    return scalar(@_);
    }

#########################################################################
#########################################################################
sub body_of
    {
    my( $ptr ) = @_;
    return $ptr->{text} || $ptr->{body};
    }

#########################################################################
#	Dump stated fields of a hash table but handle undefs better.	#
#########################################################################
sub outhash
    {
    my( $ptrname, $p, @fields ) = @_;
    return "{$ptrname undefined}" if( ! defined( $p ) );
    my @ret;
    grep( push( @ret, ":$_=", $p->{$_} ? $p->{$_} : "UNDEF" ), @fields );
    return join("","{$ptrname",@ret,"}");
    }

my $num_headings;
my $need_chapter_header;
my $need_tbl_header;
my $last_title;
my %seen_mark;
my %seen_ref;
#########################################################################
#	Print an item from an an end-of-chapter table.			#
#########################################################################
sub print_eos_thing
    {
    my( $lvl, $parent_ptr, $my_ptr, $done_flag, $clause_type, $l4clause_type ) = @_;
    my $text_flag = 1;

    #my( $workp, $storyp, $chapterp, $thingp, $clause_type ) = @_;

    #print "lvl=$lvl done_flag=$done_flag clause_type=$clause_type l4=$l4clause_type.<br>\n";

    return if( $done_flag || $clause_type ne $l4clause_type );
    return if( $my_ptr && $my_ptr->{who} && $my_ptr->{who} eq "FAKE" );
    return if( &in_list($clause_type,@TEXT_HELPERS) );
    if( &in_list($clause_type,"trademark","glossary") )
        { return if( $seen_ref{ $my_ptr->{base} || &body_of($my_ptr) }++ ); }

    #print "CMC pet args $parent_ptr, $my_ptr, $clause_type.<br>\n";
    #print "CMC start pet p=", ($parent_ptr?$parent_ptr->{id}:"NULL"), " m=", $my_ptr->{id}, " t=", $clause_type, ".<br>\n";

    my $chapter_ptr = &find_ancestor_that_is( $my_ptr, "chapter" );

    my $cur_title = find_ancestor_attribute( $my_ptr, "title" );
    if( $cur_title && $last_title ne $cur_title )
	{
	$need_chapter_header = $need_tbl_header = 1;
	}
    if( $need_chapter_header )
	{
	if( $need_tbl_header )
	    {
	    my $plural = ucfirst( $clause_type ) . "s";
	    my $printable = ucfirst($clause_type);
	    $printable .= "s" if( ! &in_list($clause_type,"glossary") );
	    &sub_buf(
		&new_page( &alink("B".$clause_type,"#T".$clause_type,
		    $printable ) ),
		"<center>",
		"<table width=85% frame=border border=0 cellspacing=0>",
		"<tbody>\n" );
	    if( $cur_title && $last_title ne $cur_title )
	        {
		&sub_buf( "<tr><th>$last_title</th></tr>" );
		$last_title = $cur_title;
		}
	    if( $clause_type eq "thank" )
		{ $num_headings=&print_headings("Text","Thanks"); }
	    elsif( $clause_type eq "trademark" )
		{ $num_headings=&print_headings("Product","Company"); }
	    elsif( $clause_type eq "glossary" )
	        { $num_headings=&print_headings("Word","Meaning"); }
#	    elsif( $clause_type eq "comment" )
#		{ $num_headings=&print_headings("Number","Comment"); }
	    elsif( $clause_type eq "reference" )
		{ $num_headings=&print_headings("Number","Description","URL" ); }
	    elsif( &in_list($clause_type,"footnote","comment") )
		{ $num_headings=&print_headings("Number",ucfirst($clause_type)); }
	    elsif( $clause_type eq "illustration" )
		{ $num_headings=&print_headings("Title","Contains"); }
	    elsif( $clause_type eq "camera" )
		{ $num_headings=&print_headings("ID","Action","Where"); }
	    else
	        { print "BOGUS heading entry for [$clause_type].\n"; }
	    $need_tbl_header = 0;
	    }

	&sub_buf( "<tr bgcolor=gray><th colspan=$num_headings>",
	    $chapter_ptr->{fullname}, "</th></tr>\n" )
	    if( $chapter_ptr && $chapter_ptr->{fullname} );
	$need_chapter_header = 0;
	}

    $_= &in_list( $clause_type, "footnote", "comment", "reference", "camera" )
	    ? $my_ptr->{$clause_type."_id"}
	: &in_list( $clause_type, "illustration" ) && $my_ptr->{alt}
	    ? $my_ptr->{alt}
	: $my_ptr->{base}
	    ? $my_ptr->{base}
	: &body_of($my_ptr);

    &sub_buf( "<tr $COLFLAG='", ($chapter_ptr->{color}||"pink"), "'>",
	"<td valign=top>", &link_to_body( $my_ptr, $_ ), "</td>" );

    if( &in_list( $clause_type, "thank", "trademark" ) )
	{ &sub_buf( "<td>", $my_ptr->{who}, "</td>" ); }
    elsif( $clause_type eq "glossary" )
        { &sub_buf( "<td>", $my_ptr->{meaning}, "</td>" ); }
    elsif( &in_list( $clause_type, "footnote", "comment" ) )
	{ &sub_buf( "<td>", &fix_html( &body_of($my_ptr), 1 ), "</td>" ); }
    elsif( $clause_type eq "reference" )
	{
	&sub_buf("<td>");
	if( $my_ptr->{alt} )
	    { &sub_buf( $my_ptr->{alt} ); }
	else
	    { &print_all_obj( $text_flag, $my_ptr, $lvl ); }
	sub_buf("</td><td>",&alink("",$my_ptr->{href},$my_ptr->{href}),"</td>");
	}
    elsif( $clause_type eq "illustration" )
	{
	&sub_buf("<td>",&alink("",$my_ptr->{src},$my_ptr->{contains}), "<br>");
	&print_all_obj( $text_flag, $my_ptr, $lvl );
	&sub_buf("</td>");
	}
    elsif( $clause_type eq "camera" )
        {
        &sub_buf( "<td>", $my_ptr->{action}, "</td>",
	    "<td>", $my_ptr->{where}, "</td>" );
	}
    &sub_buf( "</tr>\n" );
    #print "CMC end pet p=", ($parent_ptr?$parent_ptr->{id}:"NULL"), " m=", $my_ptr->{id}, " t=", $clause_type, ".<br>\n";
    }

#########################################################################
#	Print an end-of-chapter table.					#
#########################################################################
sub print_eos
    {
    my( $top, $clause_type, @args ) = @_;
    %seen_ref = ();
    $last_title = "";
    $need_chapter_header = $need_tbl_header = 1;
    #print "CMC Calling work_tree...<br>\n";
    &work_tree( \&print_eos_thing, $top, $clause_type, @args );
    #print "CMC End work_tree...<br>\n";
    &sub_buf( "</tbody></table></center>\n" ) if( ! $need_tbl_header );
    }

#########################################################################
#	Return a string with a full dump of the variable table.		#
#########################################################################
sub var_dump
    {
    my( $top ) = @_;

    my %seen_name;
    my %seen_val;
    my @res;

    foreach my $bookp ( @{$top->{storys}} )
        {
	foreach my $varname ( keys %{$bookp->{vars}} )
	    {
	    $seen_name{$varname} = 1;
	    foreach my $varval ( keys %{$bookp->{vars}{$varname}} )
	        { $seen_val{$varval} = 1; }
	    }
	}

    my %seen = ();
    my @VAR_ORDER =
	grep( ! $seen{$_}++, @PREFERED_VAR_ORDER, sort keys %seen_name );
    %seen = ();
    my @FIELD_ORDER =
	grep( ! $seen{$_}++, @PREFERED_FIELD_ORDER, sort keys %seen_val );

    my $printed_table_header = 0;
    push(@res,"<h1>Variables</h1>");
    foreach my $bookp ( @{$top->{storys}} )
	{
	my $printed_story_header = 0;
	foreach my $varname ( @VAR_ORDER )
	    {
	    my $num_in_var = 0;
	    my @defined_fields = ();
	    foreach my $valname ( @FIELD_ORDER )
	        {
		push( @defined_fields, $valname )
		    if( $valname ne "NICKFULL"
		      && defined( $bookp->{vars}{$varname}{$valname} ) );
		}
	    foreach my $valname ( @defined_fields )
		{
		push(@res, &new_page( "Vars" ),
		    "<center><table class=newpage border=1><tbody>" )
			if( ! $printed_table_header++ );
		push(@res, "<tr><th colspan=3 align=left>",
		    $bookp->{name},
		    "</th></tr>\n",
		    "<tr><th>Variable</th><th>Field</th><th>Value</th></tr>" )
		    if( ! $printed_story_header++ );
		push(@res, "<tr>" );
		push(@res, "<th rowspan=",scalar(@defined_fields),">",
		    $varname, "</th>" )
		    if( $valname eq $defined_fields[0] );
		push(@res, "<th align=left>",$valname,"</th><td>",
		    $bookp->{vars}{$varname}{$valname},
		    "</td></tr>\n" );
		}
	    }
	}
    push(@res, "</tbody></table></center>\n" ) if( $printed_table_header );
    return join("",@res);
    }

#########################################################################
#	Print information about variables.				#
#########################################################################
sub print_vars
    {
    my( $top ) = @_;
    &status( "Beginning print_vars" );
    &sub_buf( &var_dump( $top ) );
    &status( "End print_vars" );
    }

#########################################################################
#	Return a string useful to search for objects (debugging)	#
#########################################################################
sub node_info
    {
    my( $p ) = @_;
    return "UNDEF" if( ! $p );
    return join("",
        "id=", ($p->{id}?$p->{id}:"UNDEF"),
	" type=", ($p->{clause_type}?$p->{clause_type}:"UNDEF") );
    }

#########################################################################
#	Print out non-structural objects (footnotes, etc) or recurse	#
#########################################################################
my $by_next;
my $by_last;
my $type_next;
my $type_last;
my %colors;
my $color_bar;
sub print_obj
    {
    my( $text_flag, $ptr, $lvl ) = @_;
    my $clause_type = $ptr->{clause_type};
    #&sub_buf("<br>Call PO($lvl,",&node_info($ptr),")<br>\n");
    if( $clause_type eq "subchapter" )
	{
	$by_next = $by_last = $type_last = "";
	if( $SHOW{subchapters} )
	    {
	    &sub_buf( ( $SHOW{text} ? "<h2 align=center>" : "" ),
			&link_to_table( $ptr, $ptr->{fullname} ),
		      ( $SHOW{text} ? "</h2>" : "" ) );
	    }
	elsif( $need_spacer )
	    { &sub_buf( "<center>* * * * *</center>" ); }
	else
	    { $need_spacer=1; }
	&print_all_obj( $text_flag, $ptr, $lvl );
	}
    elsif( $clause_type eq "camera" )
	{
	if( $text_flag )
	    {
	    my $changenumtext =
		&link_to_table(
		    $ptr, $ptr->{$clause_type."_id"} );
	    &sub_buf(
		"<table cellspacing=0 width=100%><tr>",
		"<td width=5%>&nbsp;</td>",
		"<td align=right bgcolor=LightGray>",
		$ptr->{action}, "</td>",
		"<td></td>",
		"</tr><tr>",
		"<th align=left>", $changenumtext, "</th>",
		"<td align=left bgcolor=LightGray>",
		$ptr->{where}, "</td>",
		"<th align=right width=5%>", $changenumtext, "</th>",
		"</tr><tr>",
		"<td></td><td bgcolor=LightGray>");
	    #&fix_html( &body_of($ptr) || "", 1 )
	    &print_all_obj( $text_flag, $ptr, $lvl );
	    &sub_buf("</td><td></td></tr></table>" );
	    }
	$by_last = "";
	$type_last = "";
	}
    elsif( $clause_type eq "by" )
	{
	$by_next = $ptr->{name};
	$colors{$by_next} = sprintf("#%06x",int( rand() * 0xffffff ) )
	    if( !defined( $colors{$by_next} )
	     && !defined($colors{$by_next} = shift(@COLOR_LIST)) );
	&print_all_obj( $text_flag, $ptr, $lvl );
	$by_next = "";
	}
    elsif( &in_list( $clause_type, "line", "action" ) )
	{
	if( $by_next ne $by_last )
	    {
	    $color_bar = "<th width=1% bgcolor='$colors{$by_next}'>&nbsp;</th>";
	    $type_last = $clause_type;
	    if( $text_flag )
		{
		&sub_buf( "<br>" );
		&sub_buf("<table cellspacing=0 width=100%><tr>",
		    $color_bar,
		    "<td width=98%>$by_next</td>",
		    $color_bar,
		    "</tr></table>" );
		}
	    }
	elsif( $clause_type ne $type_last )
	    {
	    &sub_buf("<table cellspacing=0 width=100%><tr>",$color_bar,
		"<td width=98%>&nbsp;</td>",$color_bar,"</tr></table>")
		if( $text_flag );
	    $type_last = $clause_type;
	    }
	if( $text_flag )
	    {
	    &sub_buf( "<table cellspacing=0 width=100%><tr>",
		$color_bar,
		"<th width=10% valign=top align=left>",
		#($by_last eq $by_next ? "" : $by_next),
		"",
		"</th><td width=88%>" );
	    &sub_buf( "<i>(", &fix_html($ptr->{how},1), ")</i><br>" )
		if( $ptr->{how} );
	    &sub_buf("<i>") if( $clause_type eq "action" );
	    }
	&print_all_obj($text_flag,$ptr,$lvl);
	if( $text_flag )
	    {
	    &sub_buf("</i>") if( $clause_type eq "action" );
	    &sub_buf( "</td>",$color_bar,"</tr></table>" );
	    }
	$by_last = $by_next;
	$type_last = $clause_type;
	}
    elsif( $clause_type eq "description" )
	{
	$by_last = "";
	$type_last = "";
	#&sub_buf( &fix_html( &body_of($ptr) || "", 1 ) );
	&print_all_obj( $text_flag, $ptr, $lvl )
	    if( $text_flag );
	}
    elsif( &in_list( $clause_type, "footnote", "comment", "reference" ) )
	{
	if( $text_flag && $SHOW{"${clause_type}s"} )
	    {
	    &print_all_obj( $text_flag, $ptr, $lvl ) if( $clause_type eq "reference" );
	    #&sub_buf( &body_of($ptr) ) if( $clause_type eq "reference" );
	        
	    &sub_buf( "<sup>",
		&link_to_table( $ptr, $ptr->{$clause_type."_id"} ),
		"</sup>" );
	    }
	}
    elsif( &in_list($clause_type,"offset") )
        {
	if( $text_flag )
	    {
	    my %tblargs;
	    if( $ptr->{descriptor_string} )
	        {
		foreach my $pc ( grep( $_, split(/\s+/,$ptr->{descriptor_string}) ) )
		    {
		    my $tbla = 1;
		    my $tblk = $pc;
		    if( $pc =~ /(.*)=(.*)/ )
		        { $tblk=$1; $tbla=$2; }
		    $tblk = lc($tblk);
		    $tbla =~ s/['"]//g;
		    if( $tblk eq "frame" )
			{
			push( @{$tblargs{style}}, 'border:1','border-collapse:collapse' )
			    if( $tbla );
			push( @{$tblargs{frame}}, "border" );
			}
		    else
			{ push( @{$tblargs{$tblk}}, split(/;/,$tbla) ); }
		    }
		}
	    push( @{$tblargs{width}}, "90%" ) if( ! $tblargs{width} );
	    my $tblarg =
	        ( %tblargs
		? join('',map {" $_='".join(";",@{$tblargs{$_}})."'"} sort keys %tblargs )
		: "" );
	    &sub_buf("<center><table$tblarg><tr><td>");
	    &print_all_obj( $text_flag, $ptr, $lvl );
	    &sub_buf("</td></tr></table></center>");
	    }
	}
    elsif( $clause_type eq "letter" )
        {
	if( $text_flag )
	    {
	    &sub_buf("<center><table width=90% frame='border'>\n");
	    &print_all_obj( $text_flag, $ptr, $lvl );
	    &sub_buf("</table></center>\n");
	    }
	}
    elsif( &in_list($clause_type,"sender","date","signature") )
        {
	if( $text_flag )
	    {
	    &sub_buf("<tr><td width=50%></td><td width=50%>\n");
	    &print_all_obj( $text_flag, $ptr, $lvl );
	    &sub_buf("<br>&nbsp</td></tr>\n");
	    }
	}
    elsif( &in_list($clause_type,"receiver","salutation","contents","cc") )
        {
	if( $text_flag )
	    {
	    &sub_buf("<tr><td colspan=2>\n");
	    &print_all_obj( $text_flag, $ptr, $lvl );
	    &sub_buf("<br>&nbsp;</td></tr>\n");
	    }
	}
    elsif( &in_list($clause_type,"trademark","glossary") )
        {
	if( $text_flag )
	    {
	    &sub_buf( &body_of($ptr) );
	    &sub_buf( &link_to_table( $ptr, $MARK_TO_HTML{$clause_type} ) )
		if( $SHOW{$clause_type."s"} &&
		    ! $seen_mark{
			$clause_type }{ $ptr->{base} || &body_of($ptr) }++ );
	    }
	}
    elsif( $clause_type eq "illustration" )
	{
	&sub_buf( "<center><table class=newpage><tbody><tr><td>",
	    &link_to_table( $ptr,
		"<img style='border:1px solid black'" .
		    " src='". $ptr->{src}. "'".
		    ( $ptr->{alt}
			? ' alt="[Picture:  '. $ptr->{alt}. ']"'
			: '' ) .
		    ( $ptr->{contains}
			? ' contains="'.$ptr->{alt}.'"'
			: '' ) .
		    "/>"
		), "</td></tr></tbody></table></center>" )
	    if( $text_flag && $SHOW{illustrations} );
	&print_all_obj( $text_flag, $ptr, $lvl );
	#&sub_buf( &fix_html(&body_of($ptr),1) );
	}
    elsif( $clause_type eq "summary" )
        {
	my( $sz, $col, $flg ) =
	    ( &find_ancestor_that_is( $ptr, "subchapter" )
	    ? ( 80, "brown", "subchapter_summaries" )
	    : ( 90, "red",  "chapter_summaries" )
	    );
	if( $SHOW{$flg} )
	    {
	    &centered_table_begin( $sz );
	    &sub_buf("<i style='color:$col;background-color:white'>");
	    &print_all_obj(1,$ptr,$lvl);
	    &sub_buf("</i>");
	    &centered_table_end();
	    }
	}
    elsif( $clause_type eq "text" )
	{
	&print_all_obj( $text_flag, $ptr, $lvl );
	}
    else
	{
	#&sub_buf( "CMC Hacking [$clause_type]<br>" );
	&sub_buf( &fix_html( &body_of($ptr) ) )
	    if( $text_flag );
	#&sub_buf( "CMC End Hacking [$clause_type]<br>" );
	}
    #&sub_buf("Return PO($lvl,",&node_info($ptr),")\n");
    }

#########################################################################
#	Print all objects within an object.				#
#########################################################################
sub print_all_obj
    {
    my( $text_flag, $ptr, $lvl ) = @_;
    $lvl++;
    &check_ref( $ptr, "HASH" );
    foreach my $kid_ptr ( @{$ptr->{all}} )
	{ &print_obj( $text_flag, $kid_ptr, $lvl ); }
    }

#########################################################################
#	Print text from array of parts.					#
#########################################################################
sub print_text
    {
    my( $text_flag, $top ) = @_;

    my $last_title = "";

    my %colors;
    my %seen_story;
    my $abort_flag = 0;

    foreach my $workp ( &generate_work_list($top) )
	{
	&print_buf( $workp->{story} );
	&sub_buf( &new_page( $last_title = $workp->{title} ) )
	    if( $workp->{title} && $workp->{title} ne $last_title );

	if( ! $seen_story{$workp->{story}} )
	    {
	    if( $SHOW{story_summaries}
	     && $workp->{story}
	     && ! $seen_story{$workp->{story}}
	     && $workp->{story}->{summary}
	     && $workp->{story}->{summary}->{body} =~ /\w/ )
		{
		&centered_table_begin( 95 );
		&sub_buf("<center>Summary</center>");
		&print_all_obj( 1, $workp->{story}->{summary} );
	        &centered_table_end();
		}
	    &print_obj( $text_flag, $workp->{story}->{comment}, 0 )
	        if( $workp->{story}->{comment} );
	    }

	foreach my $chapter_ptr ( @{$workp->{chapters}} )
	    {
	    if( $chapter_ptr->{agent_abort} && $SHOW{short_text} )
	        {
		$abort_flag = 1;
		last;
		}
	    &sub_buf( &new_page(
		&link_to_table($chapter_ptr,$chapter_ptr->{fullname}) ) );
	    &sub_buf( "<h3 align=center>".$chapter_ptr->{timestring}."</h3>" )
	        if( $chapter_ptr->{timestring} );

	    $need_spacer = 0;

	    $by_next	= $by_last	= "";
	    $type_last	= "";
	    $color_bar	= "";

	    foreach my $ptr ( @{$chapter_ptr->{all}} )
		{ &print_obj( $text_flag, $ptr, 0 ); }
	    }
	$seen_story{ $workp->{story} } = 1;
	last if( $abort_flag );
	}
    }

#########################################################################
#	Print a copyright page						#
#########################################################################
sub print_copyright
    {
    &sub_buf( &new_page( join("",
	    #&alink("Bcopyright","#Tcopyright","©"),
	    #&alink("Bcopyright","#Tcopyright","(C)"),
	    &alink("Bcopyright","#Tcopyright","&copy;"),
	    &follow_chain( "Anonymous", "copyright" ) ) ),
	"<br><br><br><br>\n",
	"<center>All rights reserved.</center>",
	"<br><br><br><br>\n",
	"<center>ISBN: ",
	&follow_chain("Unknown","ISBN"),
	"<br><br><br><br>\n",
	"<font size=-2>Generated ",
	    ( $COMMON::FORM{GENERATED} || `date +'%m/%d/%Y %H:%M'`),"</font>",
	"</center>\n" );
    }

#########################################################################
#	Print a simple single page item					##
#########################################################################
sub print_simple_page
    {
    my( $fld, $txt ) = @_;
    my $text_flag = 1;
    &sub_buf( &alink("B".$fld,"#T".$fld,&new_page($txt)),
	"<br><br><br><br>\n");
    &centered_table_begin( 70 );

    my $arrptr = &follow_chain( "None", $fld."s" );
    if( $arrptr eq "None" )
        { &sub_buf( $arrptr ); }
    else
	{
	my $seen_line = 0;
	foreach my $ptr ( @{$arrptr} )
	    {
	    sub_buf( "<hr>" ) if( $seen_line++ );
	    if( ref($ptr) ne "HASH" )
		{ &sub_buf($ptr); }
	    else
		{ &print_all_obj( $text_flag, $ptr ); }
	    }
	}
    &centered_table_end();
    }

#########################################################################
#	Just print out css header with file contents.			#
#########################################################################
sub print_css
    {
    print &COMMON::embed_css( @_ );
    }

#########################################################################
#	Figure out what headers to print on the basis of filename.	#
#########################################################################
sub do_a_header
    {
    #print "CMC do_a_header() called.\n";
    my( $fname ) = @_;

    if( $IS_CGI )
	{
	my $basename;
	my $story_fname;
	my $parent_dir;

	if( ! $ENV{PWD} )
	    {
	    $ENV{PWD} = $ENV{SCRIPT_FILENAME};
	    $ENV{PWD} =~ s:/[^/]*$::;
	    }

	$fname = "$ENV{PWD}/$fname" if( $fname !~ m:^/: );
	&COMMON::fatal("do_a_header($fname) failed as file name is in wrong format.")
	    if( $fname !~ m:^(.*)/([^/]*)/([^/]*)\.(cgi|pl)$: );
	$parent_dir = $1;
	$story_fname = $2;
	$basename = $3;

	print "<head>";
	&print_css($_) if(-f ($_="$parent_dir/common/writing/css") );
	&print_css($_) if(-f ($_="$parent_dir/$story_fname/css") );
	&print_css($_) if(-f ($_="$parent_dir/$story_fname/$basename.css") );
	print "</head><body>\n";
	}
    }

#########################################################################
#	Follows a chain of hash indices or returns default value if	#
#	chain broken.							#
#########################################################################
sub follow_chain
    {
    my( $default_val, @indices ) = @_;
    
    foreach my $start ( "book", "story" )
        {
	#print "CMC start=$start\n";
	my $thing = $top_ptr->{$start};

	foreach my $ind ( @indices )
	    {
	    #print "ind=$ind thing=".(defined($thing)?$thing:"UNDEFINED")."\n";
	    last if( !defined($thing) );
	    my $thing_type = ref $thing;
	    #print "Thing type=$thing_type.\n";
	    if( $thing_type eq "HASH" )
		{ $thing = $thing->{ $ind }; }
	    elsif( $thing_type eq "ARRAY" )
		{ $thing = $thing->[ $ind ]; }
	    else
	        { &COMMON::fatal( "Indexed to non-reference." ); };
	    }
	#print "Returning $thing.\n" if( defined($thing) );
	return $thing if( defined($thing) );
	}
    #print "CMC returning default value:  $default_val\n";
    return $default_val;
    }

#########################################################################
#	We inherit some properties from our parents.  Rather than just	#
#	cloning the parents, we create a ptr back to them and search	#
#	the up tree.							#
#########################################################################
sub find_ancestor_attribute
    {
    my( $ptr, $attr, $defval ) = @_;

    while( defined($ptr) )
        {
	return $ptr->{$attr} if( defined($ptr->{$attr}) );
	$ptr = $ptr->{parent};
	}
    return $defval;
    }

#########################################################################
#	Return ptr to node that is of specified type.			#
#########################################################################
sub find_ancestor_that_is
    {
    my( $ptr, $clause_type, $defval ) = @_;

    while( defined($ptr) )
        {
	return $ptr if( $ptr->{clause_type} eq $clause_type );
	$ptr = $ptr->{parent};
	}
    return $defval;
    }

#########################################################################
#	Read a file and return it as pieces for include mechanism.	#
#########################################################################
sub include_files
    {
    my( $fname ) = @_;
    return split(/(<include\s+file\s*=\s*\".*?\"\s*\/>)/s, &COMMON::read_file($fname));
    }


#########################################################################
#	Debug timeline							#
#########################################################################
sub debug_timeline
    {
    return;

    my( $ln, $msg ) = @_;
    my $t = $current_timeline;


    print "CMC timeline at ${ln}: ";

    if( ! $t )
        { print "timeline not defined"; }
    elsif( ! $timelines{$t} )
        { print "timelines{$t} not defined"; }
    else
	{
	print
	    "timeline=", ($t||"UNDEF"),
	    "  basedon=", ( $timelines{$t}{basedon} || "UNDEF" ),
	    "  attime=",
		    ( ! defined( $timelines{$t}{attime} ) ? "UNDEF"
		    :   &COMMON::at_string( $COMMON::ANYTIME_FMT, $timelines{$t}{attime}) ),
	    "  offset=",
		    ( ! defined( $timelines{$t}{offset} ) ? "UNDEF"
		    :   &COMMON::at_dur_string($timelines{$t}{offset}) );
	}
    print ": ", ($msg||("Bad message at $ln")), ".\n";
    }

#########################################################################
#	Update a particular timeline.					#
#########################################################################
sub parse_time_string
    {
    my( $time_strings ) = @_;
    #print "CMC parse_time_strings($time_strings)\n";
    &debug_timeline(__LINE__,"parse_timestring($time_strings)");

    $time_strings =~ s/(\d)\s+(\d)/$1-QQQ-$2/g;
    $time_strings =~ s/\s+//g;
    $time_strings =~ s/-QQQ-/ /g;
    foreach my $time_string ( split(/,/,$time_strings) )
	{
	my $old_timeline = $current_timeline;
	#print "CMC part [$time_string]\n";
	if( $time_string =~ /(.*)=(.*)/ )
	    {
	    $current_timeline = $1;
	    $time_string = $2;
	    }

	#print "CMC current timeline = [$current_timeline], time_string=[$time_string]\n";
	if( $time_string =~ /^[\-\d :]*$/ )
	    {
	    %{$timelines{$current_timeline}} =
	        ( basedon=>undef, offset=>undef, attime=>&COMMON::at($time_string) );
	    #&debug_timeline(__LINE__,"DIRECT");
	    }
	else
	    {
	    #&debug_timeline(__LINE__,"Parsing [$time_string]");
	    my @toks = grep( defined($_)&&($_ ne ""), split(/(\+|-)/,$time_string) );

	    my $tok = shift(@toks);
#	    print "CMC looking at [$tok], before: ",
#		"$current_timeline basedon=",
#		$timelines{$current_timeline}{basedon}, " offset=",
#		$timelines{$current_timeline}{offset}, ".\n";
	    if( $tok eq "." )
		{
		#&debug_timeline(__LINE__,"Ignoring dot.");
		}
	    elsif( $tok eq "now" )
		{
		%{$timelines{$current_timeline}}
		    = (basedon=>undef,offset=>undef,attime=>&COMMON::at());
		#&debug_timeline(__LINE__,"Settimg to now.");
		}
	    elsif($timelines{$tok})
		{
		#&debug_timeline(__LINE__,"Copying from $tok.");
		%{$timelines{$current_timeline}} = %{$timelines{$tok}};
		#&debug_timeline(__LINE__,"Copied from $tok.");
		}
	    elsif( $tok =~ /^[A-Z_a-z]*$/ )
		{
		%{$timelines{$current_timeline}}
		    = (basedon=>$tok,attime=>undef,offset=>&COMMON::at_dur());
		#&debug_timeline(__LINE__,"Based on unknown timeline.");
		}
	    else
		{
		#print __LINE__,":  CMC didn't know what to do with $tok, put it back on todo list.\n";
		unshift(@toks,$tok);
		}

	    %{$timelines{$current_timeline}} = %{$timelines{$old_timeline}}
	        if( ! $timelines{$current_timeline} );

	    if( ! @toks )
	        {
		#&debug_timeline(__LINE__,"No toks to parse.");
		}
	    else
	        {
		my $ooffset = $timelines{$current_timeline}{offset};
		&debug_timeline(__LINE__,"Pre summing offsets.");
		$timelines{$current_timeline}{offset} =
		    ( $ooffset
		    ? &COMMON::at_dur( $ooffset, join("",@toks) )
		    : &COMMON::at_dur( join("",@toks) ) );
		&debug_timeline(__LINE__,"Post summing offsets.");
		}
	    if( $timelines{$current_timeline}{attime}
	        && $timelines{$current_timeline}{offset} )
	        {
		$timelines{$current_timeline}{attime} =
		    &COMMON::at_dur_add( 
			$timelines{$current_timeline}{attime},
			$timelines{$current_timeline}{offset} );
		$timelines{$current_timeline}{offset} = undef;
		&debug_timeline(__LINE__,"Sum of time and offset.");
		}

	    #&debug_timeline(__LINE__,"Post parsing magic.");
	    }
	}
    &debug_timeline(__LINE__,"Returning");
    }

#########################################################################
#	Prints a timeline which might include relative information.	#
#########################################################################
sub show_timeline
    {
    my( $fmt, $timeline ) = @_;
    #print __LINE__, ", CMC show_timeline($timeline).\n";

    my @ret;
    push( @ret,
	&COMMON::at_string( $fmt, $timelines{$timeline}{attime}) )
	if( $timelines{$timeline}{attime} );
    if( my $basedon = $timelines{$timeline}{basedon} )
	{
        $basedon =~ s/_/ /g;
	push( @ret, $basedon );
	}
    push( @ret, &COMMON::at_dur_string($timelines{$timeline}{offset}) )
        if( $timelines{$timeline}{offset} );
    return join("+",@ret);
    }

#########################################################################
#	User has referred to the timeline in the body of the story.	#
#########################################################################
sub timeline_ref
    {
    my( $arg, $fmt ) = @_;
    $fmt ||= $STORY_TIME_FMT;
    my %bup_timelines = %{$timelines{$current_timeline}};
    &parse_time_string( $arg );
    my $ret = &show_timeline( $fmt, $current_timeline );
    %{$timelines{$current_timeline}} = %bup_timelines;
    return $ret;
    }

#########################################################################
#	Read a file in, doing any inclusions and substitutions.		#
#########################################################################
sub do_one_file
    {
    my( $filename ) = @_;
    my %top;
    my @parsed_pieces = ();

    my $current_dir = ".";

    &do_a_header( $filename );

    if( $filename =~ m+^(/.*)/[^/]*$+ )
        { $current_dir = $1; }
    elsif( $filename =~ m+^(.*)/([^/]*)$+ )
        {
	$current_dir = "$current_dir/$1";
	$filename = "$current_dir/$2";
	}

    my @pieces = &include_files( $filename );
    while( my $pc = shift @pieces )
        {
	if( $pc =~ /<include\s+file\s*=\s*"(.*)"\s*\/>/ )
	    {
	    #print "CMC pc=[$pc]\n";
	    unshift( @pieces, "<context dir=\"$current_dir\"/>" );
	    $filename = $1;
	    if( $filename =~ m+^(/.*)/[^/]*$+ )
	        { $current_dir = $1; }
	    elsif( $filename =~ m+^(.*)/([^/]*)$+ )
	        {
		$current_dir = "$current_dir/$1";
		$filename = "$current_dir/$2";
		}
	    else
	        {
		$filename = "$current_dir/$filename";
		}
	    unshift( @pieces, &include_files( $filename ) );
	    }
	elsif( $pc =~ /<context dir="(.*)"\/>/ )
	    { $current_dir = $1; }
	else
	    { push( @parsed_pieces, $pc ); }
	}

    my $xmltext = join("",@parsed_pieces);

    $top_ptr = &parse_file( $xmltext );
    &fix_tree( $top_ptr );
    &print_tree( $top_ptr, "TOP", 0 ) if( $SHOW{objects} );
    &print_tree( $top_ptr, "TOP", 0 );

    if( $SHOW{title} )
	{
	&sub_buf( "<h1 class=chapter align=center>",
	    &alink("Btitle","#Ttitle",&follow_chain("Untitled","name") ),
	    "</h1>\n",
	    "<br><br><br><br><br><br><br>\n",
	    "<center>By ",
	    &follow_chain( "Anonymous", "author" ),
	    "</center>\n" );
	my $illustrations = &follow_chain( "", "illustrations" );
	&sub_buf( "<center>Illustrations by $illustrations</center>" )
	    if( $illustrations );
	}

    &print_copyright()				if( $SHOW{copyright} );

    foreach my $fld ( "promotion", "overview", "dedication" )
        {
	&print_simple_page($fld,ucfirst($fld))	if( $SHOW{$fld} );
	}

    &print_buf();

    &print_toc( $top_ptr )			if( $SHOW{toc} );
    &print_flow( $top_ptr )			if( $SHOW{flow} );

    if( $SHOW{text} )
        { print_text( 1, $top_ptr ); }
    elsif( $SHOW{chapter_summaries} || $SHOW{subchapter_summaries} )
        { print_text( 0, $top_ptr ); }

    if( $SHOW{short_text} )
        {
	&print_simple_page("creator_info","Created by")
    						if( $SHOW{creator_info} );
	&print_text( 1, $top_ptr );
	}
    else
	{
	foreach my $tbl ( @TEXT_PRIMITIVES, "camera" )
	    {
	    print_eos( $top_ptr, $tbl )		if( $SHOW{$tbl} || $SHOW{$tbl."s"} );
	    }
	&print_vars( $top_ptr )			if( $SHOW{vars} );
	&print_simple_page("creator_info","Created by")
						    if( $SHOW{creator_info} );
	}
    &print_buf();
    print "</body></html>\n";
    }

#########################################################################
#	Print a usage message and exit.					#
#########################################################################
sub usage
    {
    &COMMON::fatal( "Usage:  $COMMON::PROG something" );
    }

#########################################################################
#	Main								#
#########################################################################

if( $IS_CGI )
    {
    &COMMON::CGIheader();
    &COMMON::CGIreceive();

    #grep( $SHOW{$_}=0, @SHOWS ) if( $COMMON::FORM{"shownone"} );
    #grep( $SHOW{$_}=1, @SHOWS ) if( $COMMON::FORM{"showall"} );

    if( $COMMON::FORM{show} )
        {
	foreach my $show ( split( /,/, $COMMON::FORM{show} ) )
	    {
	    if( $SHOW_LISTS{$show} )
	        {
		%SHOW=();
		grep( $SHOW{$_}=1, @{$SHOW_LISTS{$show}} );
		}
	    elsif( grep( $_ eq $show, @SHOWS ) )
	        { $SHOW{$show}=1; }
	    elsif( $show =~ /^no(.*)/ && grep( $_ eq $1, @SHOWS ) )
	        {
		$SHOW{$1}=0;
		}
	    }
	}

    foreach my $svar ( @SHOWS )
        {
	if( defined( $COMMON::FORM{"show$svar"} ) )
	    {
	    if( $SHOW_LISTS{$svar} )
	        { grep( $SHOW{$_}=$COMMON::FORM{"show$svar"}, @{$SHOW_LISTS{$svar}} ); }
	    else
		{ $SHOW{$svar} = $COMMON::FORM{"show$svar"}; }
	    }
	elsif( defined( $COMMON::FORM{"noshow$svar"} ) )
	    {
	    if( $SHOW_LISTS{$svar} )
	        { grep( $SHOW{$_}=0, @{$SHOW_LISTS{$svar}} ); }
	    else
		{ $SHOW{$svar} = 0; }
	    }
	}

    grep( $SHOW{$_}=1, @{$SHOW_LISTS{browser}} ) if( scalar(keys %SHOW) == 0 );
    }

#foreach $_ ( @SHOWS )
#    {
#    print "SHOW{$_}=", ( $SHOW{$_} ? $SHOW{$_} : "undefined" ), ".<br>\n";
#    }

my $filename;
my @problems;
while( scalar(@ARGV) )
    {
    my $arg = shift(@ARGV);
    if( $arg eq "-v" )
        { $verbose = 1; }
    elsif( $arg eq "-shownone" )
        { grep( $SHOW{$_} = 0, @SHOWS ); }
    elsif( $arg =~ /^-(noshow|show)(.*)/ )
        {
	my $fnc = $1;
	my @lst;
	if( $2 eq "all" )
	    { @lst = @SHOWS; }
	elsif( $SHOW_LISTS{$2} )
	    { @lst = @{$SHOW_LISTS{$2}}; }
	elsif( grep( $_ eq $2, @SHOWS ) )
	    { @lst = ( $1 ); }
	if( $fnc eq "show" )
	    { grep( $SHOW{$_}=1, @lst ); }
	else	# fnc eq "noshow"
	    { grep( $SHOW{$_}=0, @lst ); }
	}
    else
	{
	if( ! defined( $filename ) )
	    { $filename = $arg; }
	else
	    { push(@problems,"File name multiply defined."); }
	}
    }
push(@problems,"No filename specified.") if( !defined($filename) );

&usage( @problems ) if( @problems );

$COLFLAG = ( $SHOW{color} ? "bgcolor" : "other" );

&do_one_file( $filename );
