#!/bin/bash

echo "=================REMOVE-OLD-BUILD-TREE=================="

if [ -f ct-ng ]; then
	./ct-ng distclean || exit 1
fi

if [ -f Makefile ]; then
	make distclean || exit 1
fi

if [ -d dl ]; then
        rm -rf dl
fi

# remove remaining
rm -rf Makefile.in aclocal.m4 autom4te.cache config.h.in config/gen config/versions configure kconfig/Makefile.in maintainer/package-versions verbatim-data.mk

echo "====================All IS DONE!========================"
