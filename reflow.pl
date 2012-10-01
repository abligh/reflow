#!/usr/bin/perl

use strict;
use warnings;

use constant
{
    wrapped=>1,
    raw=>2,
    quotedraw=>3
};

my $option_width = 76;
my @unquotedlines;
my @rawlines;
my $quotes=0;
my $mode = wrapped;
my $lastblank = 0;

sub empty
{
    @unquotedlines =();
    @rawlines = ();
}

sub msubstr
{
    my $t = shift @_;
    my $s = shift @_;
    my $l = shift @_;
    my $len = length ($t);
    $l = $len unless defined($l);
    return "" if ($s >= $len);
    $l = $len-$s if ($s+$l > $len);
    return substr($t, $s, $l);
}

sub getquoteprefix
{
    my $level = shift @_;
    $level = $quotes unless defined($level);
    my $quoteprefix = "> " x $level;
    $quoteprefix = ("> " x 9)."... > " if ($level > 10);
    return $quoteprefix;
}

sub outputwrapped
{
    my $text = join(' ', @unquotedlines);
    $text =~ s/\s+/ /g;
    my $quoteprefix = getquoteprefix;
    my $width = $option_width - length($quoteprefix);
    $width = 20 if ($width<20);
    while ($text !~ /^\s*$/)
    {
	# remove leading spaces and trailing spaces
	$text =~ s/^\s+//g;
	$text =~ s/\s+$//g;
	my $breakat=$width-1;
	if ($breakat >= length($text))
	{
	    $breakat = length($text); # an index one beyond last
	}
	else
	{
	    for (;
		 ($breakat > 0) && (msubstr($text, $breakat, 1) !~ /\s/);
		 $breakat--) {}
	    # handle words too big to fit. Often URLs so just go over width
	    if (!$breakat)
	    {
		for ($breakat = $width-1;
		     ($breakat<length($text)) && (msubstr($text, $breakat, 1) =~ /\S/);
		     $breakat++) {}
	    }
	}
	my $fragment = msubstr($text, 0, $breakat);
	$fragment =~ s/^\s+//g;
	$fragment =~ s/\s+$//g;
	$text = msubstr($text, $breakat+1);
	print $quoteprefix.$fragment."\n";
    }
}

sub outputraw
{
    print join("\n", @rawlines)."\n";
}

# Called with a parameter of the unquoted text to output with \n's in
sub outputquotedraw
{
    my $quoteprefix = getquoteprefix;
    foreach my $fragment (@unquotedlines)
    {
	$fragment =~ s/\s+$//g;
	print $quoteprefix.$fragment."\n";
    }
}

sub output
{
    if ($#rawlines >= 0)
    {
	if ($mode == wrapped)
	{
	    outputwrapped;
	}
	elsif ($mode == raw)
	{
	    outputraw;
	}
	elsif ($mode == quotedraw)
	{
	    outputquotedraw;
	}
	else
	{
	    die "Bad mode";
	}
	$lastblank = 0 if ($#unquotedlines >= 0) && (join ('',@unquotedlines) ne "");
    }
    empty;
}

while (<>)
{
    chomp;

    # replace tabs with 8 spaces
    s/\t/        /g;

    my $line = $_;
    my $unqline = $line;
    my $quotelevel = 0;
    while ($unqline =~ s/^\s*>( )?//)
    {
	$quotelevel++;
    }

    if ($line =~ /^\s*$/)
    {
	output;
	print "\n";
	$mode = wrapped;
	$quotes = 0;
	$lastblank = 1;
	next; # do not record this line
    }
    elsif ($line =~ /^--( )?$/) # Signature separator
    {
	output;
	$mode = raw;
	$quotes = 0;
    }
    elsif ($unqline =~ /^\s*$/)
    {
	output;
	$mode = wrapped;
	$mode = quotedraw if ($unqline=~/^\s/);
	$quotes = $quotelevel;
	my $quoteprefix = getquoteprefix;
	print "$quoteprefix\n";
	$lastblank = 1;
    }
    elsif ($quotelevel != $quotes)
    {
	my $oldquotelevel = $quotes;
	my $waslastblank = $lastblank;
	# Quote level changed without a blank line - how rude
	output;
	$mode = wrapped;
	$mode = quotedraw if ($unqline=~/^\s/);
	$quotes = $quotelevel;
	if (!$lastblank && ($quotelevel<$oldquotelevel)) # else we add spaces after 'On ... x wrote'
	{
	    my $quoteprefix = getquoteprefix(($oldquotelevel<$quotelevel)?$oldquotelevel:$quotelevel);
	    print "$quoteprefix\n";
	    $lastblank = 1;
	}
    }
    elsif (($mode==wrapped) && ($unqline=~/^\W/))
    {
	# Do not output, we want to reinterpret the buffer as quotedraw
	# this catches ASCII art, patches, and most code
	$mode = quotedraw;
    }

    # Record line
    push @rawlines, $line;
    push @unquotedlines, $unqline;
}

output;
