#!/bin/bash
#
# Copyright (c) 2007-2008 Brian Koropoff
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the Moonunit project nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY BRIAN KOROPOFF ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL BRIAN KOROPOFF BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

function die()
{
    echo "$@" >&2
    exit 1
}

function tokenize()
{
    sed 's/[^a-zA-Z0-9_][^a-zA-Z0-9_]*/ /g' | xargs | awk 'BEGIN { RS=" "; } { print $1; }'
}

function filter_prefix()
{
    grep "${1}[a-zA-Z0-9_]*"
}

function extract_symbols()
{
    tokenize | filter_prefix "$1" | sort | uniq
}

function extract_tests()
{
    extract_symbols "__mu_t_"
}

function extract_library_setup()
{
    extract_symbols "__mu_ls"
}

function extract_library_teardown()
{
    extract_symbols "__mu_lt"
}

function extract_fixture_setup()
{
    extract_symbols "__mu_fs_"
}

function extract_fixture_teardown()
{
    extract_symbols "__mu_ft_"
}

function preprocess()
{
    ${CPP:-cpp} $CPPFLAGS "$1"
}

function emit_test_prototypes()
{
    local symbol;
    for symbol in "$@"
    do
        echo "extern MuTest ${symbol};"
    done
}

function emit_library_setup_prototypes()
{
    local symbol;
    for symbol in "$@"
    do
        echo "extern MuLibrarySetup ${symbol};"
    done
}

function emit_library_teardown_prototypes()
{
    local symbol;
    for symbol in "$@"
    do
        echo "extern MuLibraryTeardown ${symbol};"
    done
}

function emit_fixture_setup_prototypes()
{
    local symbol;
    for symbol in "$@"
    do
        echo "extern MuFixtureSetup ${symbol};"
    done
}

function emit_fixture_teardown_prototypes()
{
    local symbol;
    for symbol in "$@"
    do
        echo "extern MuFixtureTeardown ${symbol};"
    done
}

function emit_stub_hook()
{
    local library_setup="$1"
    local library_teardown="$2"
    local fixture_setup="$3"
    local fixture_teardown="$4"
    local tests="$5"

    cat << __PRE__
void __mu_stub_hook(MuLibrarySetup** ls, MuLibraryTeardown** lt,
                    MuFixtureSetup*** fss, MuFixtureTeardown*** fts,
                    MuTest*** ts)
{
__PRE__

    echo "    static MuFixtureSetup* fixture_setups[] ="
    echo "    {"
    
    for symbol in $fixture_setup
    do
        echo "        &$symbol,"
    done
    
    echo "        NULL"
    echo "    };"

    echo 

    echo "    static MuFixtureTeardown* fixture_teardowns[] ="
    echo "    {"
    
    for symbol in $fixture_teardown
    do
        echo "        &$symbol,"
    done
    
    echo "        NULL"
    echo "    };"

    echo

    echo "    static MuTest* tests[] ="
    echo "    {"
    
    for symbol in $tests
    do
        echo "        &$symbol,"
    done
    
    echo "        NULL"
    echo "    };"

    echo

    if [ -n "$library_setup" ]
    then
        echo "    *ls = &$library_setup";
    fi
    if [ -n "$library_teardown" ]
    then
        echo "    *ls = &$library_teardown";
    fi

    echo "    *fss = fixture_setups;"
    echo "    *fts = fixture_teardowns;"
    echo "    *ts = tests;"

    echo "}"
}

function emit-stub()
{
    local TMPFILE

    if type mktemp >/dev/null 2>&1
    then
        TMPFILE=`mktemp /tmp/moonunit-stub.XXXXXXXXXX` || exit 1
    else
        TMPFILE="/tmp/moonunit-stub.${PPID}"
    fi

    touch $TMPFILE

    for input in "$@"
    do
        preprocess "$input" >> $TMPFILE || die Error preprocessing $input
        echo >> $TMPFILE
    done

    local LIBRARY_SETUP=`extract_library_setup < $TMPFILE`
    local LIBRARY_TEARDOWN=`extract_library_teardown < $TMPFILE`
    local FIXTURE_SETUP=`extract_fixture_setup < $TMPFILE`
    local FIXTURE_TEARDOWN=`extract_fixture_teardown < $TMPFILE`
    local TESTS=`extract_tests < $TMPFILE`

    rm -f $TMPFILE

    cat << __HEADER__
/* Automatically generated by moonunit-stub */

#include <moonunit/test.h>
#include <stdlib.h>

__HEADER__
    emit_library_setup_prototypes $LIBRARY_SETUP
    emit_library_teardown_prototypes $LIBRARY_TEARDOWN
    emit_fixture_setup_prototypes $FIXTURE_SETUP
    emit_fixture_teardown_prototypes $FIXTURE_TEARDOWN
    emit_test_prototypes $TESTS
    
    echo

    emit_stub_hook "$LIBRARY_SETUP" "$LIBRARY_TEARDOWN" "$FIXTURE_SETUP" "$FIXTURE_TEARDOWN" "$TESTS"
}

function usage()
{
    name=`basename $1`
    cat << __EOF__
$name -- Mu test loading stub generator

  This script scans C source code files for Mu unit tests
  and generates a test loading stub.  This stub allows MoonUnit
  to load unit tests without scanning symbols in your library
  at runtime (an operation which is highly platform-dependent
  and less portable).

Usage: $name [-o <outfile>] [<name>=<value> ...] source1.c source2.c ...
  -o <file>           Write output to <file> (defaults to stdout)
  -?,-h,--help        Display this usage information
  <name>=<value>      Set an environment variable for the duration of
                      this script (e.g. CPPFLAGS)

Environment variables:
  CPP                 The C preprocessor program to invoke (default: cpp)
  CPPFLAGS            Additional flags to pass to the C preprocessor
__EOF__
}

arg=$1

outfile="/dev/stdout"

while [ -n "$arg" ]
do
    shift
    case "$arg" in
        --help|-h|'-?')
            usage $0
            exit 0
            ;;
        -o)
            outfile="$1"
            shift
            ;;
        *=*)
            export "$arg"
            ;;
        *)
            sources=("${sources[@]}" "$arg")
            ;;
    esac
    arg="$1"
done

if [ -n "${sources[*]}" ]
then
    emit-stub "${sources[@]}" > $outfile
else
    usage $0
    exit 1
fi
