# $File: //member/autrijus/Template-Generate/lib/Template/Generate.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 7849 $ $DateTime: 2003/09/03 20:36:51 $ vim: expandtab shiftwidth=4

package Template::Generate;
$Template::Generate::VERSION = '0.02';

use 5.006;
use strict;
use warnings;
our $DEBUG;

=head1 NAME

Template::Generate - Generate TT2 templates from data and documents

=head1 VERSION

This document describes version 0.02 of Template::Generate, released
September 4, 2003.

=head1 SYNOPSIS

    use Template::Generate;

    my $obj = Template::Generate->new;
    my $template = $obj->generate(
        {
            first	=> 'Autrijus',
            last	=> 'Tang',
            score	=> 55,
        } => "(Simon's Blog) Score: 55, Name: Autrijus Tang",
        {
            first	=> 'Simon',
            last	=> 'Cozens',
            score	=> 61,
        } => "(Simon's Blog) Score: 61, Name: Simon Cozens",
    );

    # "(Simon's Blog) Score: [% score %], Name: [% first %] [% last %]"
    print $template;

=head1 DESCRIPTION

This module generates TT2 templates.  It can take data structures and
rendered documents together, and deduce templates that could have
performed the transformation.

It is a companion to B<Template> and B<Template::Extract>; their
relationship is shown below:

    Template:           ($template + $data) ==> $document   # normal
    Template::Extract:  ($document + $template) ==> $data   # tricky
    Template::Generate: ($data + $document) ==> $template   # very tricky

This module is considered experimental.

=head1 METHODS

=head2 generate($data => $document, $data => $document, ...)

This method takes any number of ($data, $document) pairs, and returns a
sorted list of possible templates that can satisfy all of them.  In scalar
context, the template with most variables is returned.

You may set C<$Template::Generate::DEBUG> to a true value to display
generated regular expressions.

=head1 CAVEATS

Currently, the C<generate> method only handles C<[% GET %]> and
single-level C<[% FOREACH %]> directives, but nested C<[% FOREACH %]>
and C<[% ... %]> is planned.

=cut

sub new {
    bless( {}, $_[0] );
}

sub generate {
    my $self = shift;

    my ( %seen, $final );
    while ( my $data = shift ) {
	my $document = shift;
	my $repeat   = keys(%$data);
	my ( @each, @this );
	do {
	    @this =
	      _try( $data, ( ref($document) ? $document : \$document ),
		$repeat++ );
	    push @each, @this;
	} while @this;
	%seen = map { $final = $_; $_ => 1 }
                grep { !%seen or $seen{$_} } @each
                or return;
    }
    return sort keys %seen if wantarray;
    return $final;
}

sub _try {
    my ( $data, $document, $repeat ) = @_;
    my $regex = "\\A\n";
    my $count = 0;

    $regex .= _any( \$count );
    for ( 1 .. $repeat ) {
	$regex .= _match( $data, \$count );
	$regex .= _any( \$count );
    }

    $regex .= "\\z\n";
    $regex .= "(??{_validate(\\\@m, \\\@rv, \$data)})\n";

    my ( @m, @rv );
    {
	use re 'eval';
	$regex                =~ s/\n//g;
	( $$document . "\0" ) =~ m/$regex/s;
    }
    return @rv;
}

sub _match {
    my ( $data, $count, $prefix, $undef ) = @_;
    $prefix ||= '';
    my $rv = "(?:\n";
    foreach my $key ( sort keys %$data ) {
	my $value = $data->{$key};
	if ( !ref($value) ) {
	    $$count++;
	    if ($undef) {
		$rv .= "("
		  . quotemeta($value)
		  . ")(?{\$m[\$-[$$count]] = [ undef, \$$$count ]})\n|\n";
	    }
	    else {
		$rv .= "("
		  . quotemeta($value)
		  . ")(?{\$m[\$-[$$count]] = \\'{$prefix$key}'})\n|\n";
	    }
	}
	elsif ( UNIVERSAL::isa( $value, 'ARRAY' ) ) {
            die "Array $key must have at least one element" unless @$value;

	    my $c1 = ++$$count;
	    $rv .= "(.*?)(?{\$m[\$-[$$count]] = ['[% FOREACH $key %]', \$$$count, '']})\n";

	    $rv .= _match( $value->[0], $count, "$prefix$key}[0]{" );

	    my $c2 = ++$$count;
	    $rv .= "(.*?)(?{\$m[\$-[$$count]] = ['', \$$$count, '[% END %]']})\n";

	    foreach my $idx ( 1 .. $#$value ) {
		++$$count;
		$rv .= "(\\$c1)(?{\$m[\$-[$$count]]  = [undef, \$$c1]})\n";
		$rv .= _match(
                    $value->[$idx],
                    $count,
		    "$prefix$key}[$idx]{",
                    'undef'
		);
		++$$count;
		$rv .= "(\\$c2)(?{\$m[\$-[$$count]]  = [undef, \$$c2]})\n";
	    }
	    $rv .= "|\n";
	}
	else {
	    die "Unsupported data type: " . ref($value);
	}
    }
    substr( $rv, -2 ) = ")\n";
    return $rv;
}

sub _any {
    my $count = shift;
    $$count++;
    "(.*?)(?{\$m[\$-[$$count]] = \$$$count})\n";
}

sub _validate {
    my ( $in, $out, $data ) = @_;
    my $idx  = 0;
    my %seen = ();
    my $rv   = '';
    while ( defined( my $val = $in->[$idx] ) ) {
	if ( ref($val) eq 'SCALAR' ) {
	    $seen{$$val} = 1;
	    $idx += length( eval("\$data->$$val") );
	    $rv .= "[% " . substr( $$val, rindex( $$val, '{' ) + 1, -1 ) . " %]";
	    next;
	}
	elsif ( ref($val) eq 'ARRAY' ) {
	    $rv .= join( '', @$val ) if @$val == 3;
	    $idx += length( $val->[1] );
	    next;
	}
	$rv .= $val;
	$idx += length($val);
    }
    chop $rv;
    push @$out, $rv if keys(%seen) == keys(%$data);
    return '(?!)';
}

1;

=head1 SEE ALSO

L<Template>, L<Template::Extract>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

