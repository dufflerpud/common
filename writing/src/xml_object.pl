#!/usr/bin/perl -w

use strict;

my $lookfor = "illustration";
my %restrictions;
my %preclusions;
my @showlist;

#########################################################################
#	Break up a string into tokens.					#
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
#	Main								#
#########################################################################

foreach my $arg ( @ARGV )
    {
    if( $arg =~ /(.*)!=(.*)/ )
        { $preclusions{$1} = $2; }
    elsif( $arg =~ /(.*)=(.*)/ )
        { $restrictions{$1} = $2; }
    elsif( $arg =~ /<(.*)>/ )
        { $lookfor = $1; }
    else
        { push( @showlist, $arg ); }
    }

#print "showlist=",join(",",@showlist),".\n";
#print "lookfor=$lookfor.\n";
#print "preclusions=",join(",",keys %preclusions),"\n";
#print "restrictions=",join(",",keys %restrictions),"\n";

foreach my $piece ( split(/(<$lookfor\b.*?>)/ms,join("",<STDIN>)))
    {
    if( $piece !~ /<$lookfor\b([^>]*)>/ms )
        { next; }
    else
        {
	my $attributes = $1;
	$attributes =~ s+/$++ms;
	#print "attributes=[$attributes]\n";
	my @tokens = &tokenize( $attributes );
	my $attr;
	my %attributes;
	while( defined($attr = shift(@tokens)) )
	    {
	    if( $tokens[0] ne "=" )
	        { $attributes{$attr} = 1; }
	    else
	        {
		shift( @tokens );	# Get rid of the equals
		$attributes{$attr} = shift( @tokens );
		}
	    }
	my $found = 0;
	foreach my $vvar ( keys %restrictions )
	    {
	    if( ($attributes{$vvar}||"") ne ($restrictions{$vvar}||"") )
	        { $found=1; last; }
	    }
	if( ! $found )
	    {
	    foreach my $vvar ( keys %preclusions )
		{
		if( ($attributes{$vvar}||"") eq ($preclusions{$vvar}||"") )
		    { $found=1; last; }
		}
	    print join("\n ",
	        map {"$_=".($attributes{$_}||"")}
		    ( @showlist ? @showlist : sort keys %attributes ) ),
		    "\n"
		if( ! $found );
	    }
	}
    }
