#!/usr/bin/perl
# $File: //member/autrijus/Template-Generate/t/1-basic.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 7841 $ $DateTime: 2003/09/02 16:54:33 $ vim: expandtab shiftwidth=4

use strict;
use Test;

BEGIN { plan tests => 4 }

require Template::Generate;
ok(Template::Generate->VERSION);

my $obj = Template::Generate->new;
ok(ref($obj), 'Template::Generate');

my @input = (
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

my @template = $obj->generate(@input);
ok("@template",  "(Simon's Blog) Score: [% score %], Name: [% first %] [% last %]");

my $template = $obj->generate(@input);
ok($template,  "(Simon's Blog) Score: [% score %], Name: [% first %] [% last %]");
