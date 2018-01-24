## Devel::Debug::DBGp
Debug Perl using interactive debuggers from other dynamic languages.

## Description

First a bit of history...

A long time ago (in 2003) ActiveState and the Xdebug author defined a protocol, named
[DBGp](https://xdebug.org/docs-dbgp.php),
that would ideally allow using a common debugger UI to debug any dynamic language.

Unfortunately, the this never picked up traction, and DBGp support is mainstream
only for PHP. ActiveState provides a Perl DBGp implementation (used by the Komodo IDE),
but it is not 100% interoperable
with debuggers targeting PHP (because ActiveState's implementation does not 100% adhere to the
standard, Xdebug implementation does not 100% adhere to the standard either but in different ways,
and debuggers targeting PHP are coded against the Xdebug
implementation
and its quirks).

This repository contains a refactored version of ActiveState code with changes to fix interoperability with
existing PHP debuggers (pretty much: follow the standard, but add
options to mimic Xdebug behaviour where necessary),
performance improvements
and fixes for various corner cases where the original code crashes.

The goal of this project is to be able to debug web applications using
a modern debugger UI. This has been tested using
[Vim vDebug](https://github.com/joonty/vdebug), [pugdebug](http://pugdebug.com/) and
[Sublime Text Xdebug](https://github.com/martomo/SublimeTextXdebug). It is likely to work with other DBGp
implementations, but it has not been explicitly tested.
Support for debugging Plack applications is provided by
[Plack::Middleware::DBGp](https://metacpan.org/pod/Plack::Middleware::DBGp).

See the full documentation on [MetaCPAN](https://metacpan.org/pod/Devel::Debug::DBGp).

## License

See [LICENSE.txt](https://raw.githubusercontent.com/mbarbon/perl-remote-debugging-client/master/LICENSE.txt)
for copyright and licensing information.
