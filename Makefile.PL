#!/usr/bin/env perl
# $File: //member/autrijus/Template-Generate/Makefile.PL $ $Author: autrijus $
# $Revision: #1 $ $Change: 7841 $ $DateTime: 2003/09/02 16:54:33 $

use 5.006;
use inc::Module::Install;

WriteMakefile (
    AUTHOR	    => 'Autrijus Tang (autrijus@autrijus.org)',
    NAME	    => 'Template::Generate',
    ABSTRACT	    => 'Generate TT2 templates from data and documents',
    VERSION_FROM    => 'lib/Template/Generate.pm',
);

