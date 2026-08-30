#!/usr/bin/perl -w

use strict;

my $PROG = $0;
$PROG =~ s+.*/++;
my $TMP = "/tmp/$PROG";

my $DEBUG = 0;

my $MOD_STR = "MOD:";
$MOD_STR = "";

my $STRIKE_OPEN="<strike style='text-decoration:line-through;color:red;background-color:LightGray'><font style='color:DarkGray'>$MOD_STR";
my $STRIKE_CLOSE="</font></strike>";

my $ADDED_OPEN="<font style='font-weight:bold;background-color:LightGreen;color=DarkGreen'>$MOD_STR";
my $ADDED_CLOSE="</font>";

#########################################################################
#	Print an error, a usage message, and die.			#
#########################################################################
sub usage
    {
    print join("\n",@_), "\nUsage:  $PROG old new diff\n";
    exit(1);
    }

#########################################################################
#	Print lines to named file					#
#########################################################################
sub dump
    {
    my( $fname, @lines ) = @_;
    open( OUT, "> $fname" ) || &usage("Cannot write ${fname}:  $!");
    print OUT join("\n",@lines), "\n";
    close( OUT );
    }

#########################################################################
#	Convert file to have different words on each file ignoring	#
#	xmlisms.							#
#########################################################################
sub convert
    {
    my( $old_file_name, $new_file_name ) = @_;
    open( INF, $old_file_name )
	|| &usage("Cannot open ${old_file_name}:  $!");
    open( OUT, ">$new_file_name" )
	|| &usage("Cannot write ${new_file_name}:  $!");

    my $hdr = <INF>;		# This gets the #!/ line
    print OUT $hdr;

    foreach my $txt ( split(/(<.*?>)/s,join("",<INF>)) )
        {
	if( $txt =~ /<.*/ )
	    {
	    print OUT $txt if( $txt !~ /<trademark/ && $txt !~ /<\/trademark/ );
	    }
	else
	    {
	    my @pieces = split(/(\s+)/,$txt);
	    while( defined($_ = shift(@pieces)) )
		{
		if( $_ =~ /\n\s*\n/ )
		    { print OUT "\n\n"; }
		elsif( $_ =~ /\s*\n\s*/ )
		    { print OUT "\n"; }
		else
		    {
		    print OUT $_;
		    if( $_ !~ /\s/ )
			{
			if( @pieces && $pieces[0] =~ /^[ 	]+$/ )
			    {
			    shift( @pieces );
			    print OUT "\n";
			    }
			}
		    }
		}
	    }
	}
    close( OUT );
    close( INF );
    }

#########################################################################
#	Glue the tags to the first and last lines.			#
#########################################################################
sub fix_newlines
    {
    my( $start_tag, @lines ) = @_;
    my $end_tag = pop @lines;
    $lines[0] = $start_tag . $lines[0];
    $lines[$#lines] .= $end_tag;
    return @lines;
    }

#########################################################################
#	Main								#
#########################################################################

my @problems;

&usage("Incorrect number of arguments.") if( scalar(@ARGV) != 3 );

my $OLD_FILE = $ARGV[0];
my $NEW_FILE = $ARGV[1];
my $RESULT = $ARGV[2];

push( @problems, "$OLD_FILE not readable file." )
    if( ! -f $OLD_FILE || ! -r $OLD_FILE );
push( @problems, "$NEW_FILE not readable file." )
    if( ! -f $NEW_FILE || ! -r $NEW_FILE );
push( @problems, "$RESULT already exists." )
    if( -e $RESULT );

&usage( @problems ) if( @problems );

&convert( $OLD_FILE, "$TMP.old" );
&convert( $NEW_FILE, "$TMP.new" );
open( INF, "$TMP.old" ) || &usage("$TMP.old not readable:  $!");
my @lines = <INF>;
chomp( @lines );
close( INF );

my $passnum = 0;
&dump( "/tmp/".$passnum++, @lines ) if( $DEBUG );
my $cmd = "diff -e '$TMP.old' '$TMP.new'";
open( INF, "$cmd |" ) || &usage("$cmd failed:  $!");
while( $_ = <INF> )
    {
    chomp( $_ );
    $_ = "$1,${1}$2" if( /^(\d+)([acd])/ );
    if( ! /^(\d+),(\d+)([acd])/ )
        {
	print STDERR "Unknown ed commands [$_]\n";
	}
    else
        {
	my( $from_line ) = $1 - 1;
	my( $to_line ) = $2 - 1;
	my( $op ) = $3;
	my @new_lines;
	if( $op eq "d" )
	    {
	    push( @new_lines, @lines[0..$from_line-1] )
		if( $from_line > 0 );
	    push( @new_lines,
	        &fix_newlines(
		    $STRIKE_OPEN, @lines[$from_line..$to_line], $STRIKE_CLOSE ) );
	    push( @new_lines, @lines[$to_line+1..$#lines] )
	        if( $to_line+1 <= $#lines );
	    }
	else		# if( $op eq "a" || $op eq "c" )
	    {
	    my @text;
	    while( $_ = <INF> )
	        {
		chomp( $_ );
		last if( $_ eq "." );
		push( @text, $_ );
		}
	    if( $op eq "a" )
	        {
		push( @new_lines, @lines[0..$from_line] )
		    if( $from_line >= 0 );
		push( @new_lines,
		    &fix_newlines( $ADDED_OPEN, @text, $ADDED_CLOSE ) );
		push( @new_lines, @lines[$from_line+1..$#lines] )
		    if( $from_line+1 <= $#lines );
		}
	    else	# if( $op eq "c" )
	        {
		push( @new_lines, @lines[0..$from_line-1] )
		    if( $from_line-1 >= 0 );
		push( @new_lines,
		    &fix_newlines( $ADDED_OPEN, @text, $ADDED_CLOSE ) );
		push( @new_lines,
		    &fix_newlines(
			$STRIKE_OPEN, @lines[$from_line..$to_line], $STRIKE_CLOSE
			) );
		push( @new_lines, @lines[$to_line+1..$#lines] )
		    if( $to_line+1 <= $#lines );
		}
	    }
	@lines = @new_lines;
	&dump( "/tmp/".$passnum++, @lines ) if( $DEBUG );
	}
    }
close( INF );

&dump( $RESULT, @lines );

exit(0);
