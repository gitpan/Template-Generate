# $File: //member/autrijus/Template-Generate/lib/Template/Generate.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 7841 $ $DateTime: 2003/09/02 16:54:33 $ vim: expandtab shiftwidth=4

package Template::Generate;
$Template::Generate::VERSION = '0.01';

use 5.006;
use strict;
use warnings;

=head1 NAME

Template::Generate - Generate TT2 templates from data and documents

=head1 VERSION

This document describes version 0.01 of Template::Generate, released
September 3, 2003.

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
sorted list of possible templates that can satisfy all of them.

In scalar context, only the first item is returned.

=head1 CAVEATS

Currently, the C<generate> method only handles C<[% GET %]> directives,
but support for C<[% FOREACH %]> and C<[% ... %]> is planned.

=cut

sub new {
    bless({}, $_[0]);
}

sub generate {
    my $self = shift;

    my %seen;
    while (my $data = shift) {
	my $document = shift;
	my $repeat = keys(%$data);
	my (@each, @this);
	do {
	    @this = _try($data, (ref($document) ? $document : \$document), $repeat++);
	    push @each, @this;
	} while @this;
	%seen = map { $_ => 1 } grep {
	    !%seen or $seen{$_}
	} @each or return;
    }
    return sort keys %seen if wantarray;
    return((sort keys %seen)[0]);
}

sub _try {
    my ($data, $document, $repeat) = @_;
    my $regex = '\A';
    my $count = 0;

    $regex .= _any(\$count);
    for (1 .. $repeat) {
	$regex .= _match($data, \$count);
	$regex .= _any(\$count);
    }

    $regex .= '\Z';
    $regex .= '(??{_validate(\@m, \@rv, $data)})';

    my (@m, @rv);
    {
	use re 'eval';
	($$document . "\0") =~ $regex;
    }
    return @rv;
}

sub _match {
    my ($data, $count) = @_;
    my $rv = '(?:';
    foreach my $key (sort keys %$data) {
	my $value = quotemeta($data->{$key});
	$$count++;
	$rv .= "($value)(?{\$m[\$-[$$count]] = \\'$key'})|";
    }
    substr($rv, -1) = ')';
    return $rv;
}

sub _any {
    my $count = shift;
    $$count++;
    "(.*?)(?{\$m[\$-[$$count]] = \$$$count})";
}

sub _validate {
    my ($in, $out, $data) = @_;
    my $idx = 0;
    my %seen = ();
    my $rv = '';
    while (defined(my $val = $in->[$idx])) {
	if (ref($val)) {
	    $seen{$$val} = 1;
	    $rv .= "[% $$val %]";
	    $idx += length($data->{$$val});
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

L<Template>, L<Template::Generate>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
