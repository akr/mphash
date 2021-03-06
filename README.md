# mphash - minimal perfect hash tool

mphash is a tool for minimal perfect hash.

## Author

Tanaka Akira <akr@fsij.org>

## Home Page

http://www.a-k-r.org/mphash/

## Feature

* generate a minimal perfect hash function
* hash table using the minimal perfect hash function
* generate a C source code (generated code is public domain)
  * single source file for self-contained command (testing purpose)
  * hash table or hash function
  * foo.c and foo.h pair for single hash function/table
  * mphash.h, mphash.c, foo.h, foo.c, bar.h, bar.c, ... for multiple
    hash functions/tables

## Usage

### Simple Test Command Generation

You need a file which contains key-value pairs.
(If a value is ommitted, an empty string is assumed.)

    % cat dictfile
    foo hoge
    bar fuga
    baz "C-style quoted string is usable in keys and values"
    qux moge

mphash command generate a self-contained C source code as follows.
It is just compilable.

    % mphash dictfile -o tst.c
    % gcc tst.c

The compiled binary shows a hash code, key and value for each line.
mphash assigned 0 to 3 for the 4 keys.

    % ./a.out
    2 "foo" "hoge"
    1 "bar" "fuga"
    3 "baz" "C-style quoted string is usable in keys and values"
    0 "qux" "moge"

The binary shows hash codes and values for specified arguments.

    % ./a.out baz bar
    3 "C-style quoted string is usable in keys and values"
    1 "fuga"

It is not an error to specify a non-key string.
The hash function returns 4294967295 or some value in the assigned range (0-3).
4294967295 means the given string is not a key.
However a hash code in the range doesn't mean the string is a key.

    ./a.out a aa aaa
    4294967295 not found
    0 not found
    3 not found

### Large Set

mphash can be used for fairly large key sets,
/usr/share/dict/words for example.
The 98568 words in the file are mapped to integers 0 to 98567.

    % wc -w /usr/share/dict/words
    98568 /usr/share/dict/words
    % mphash /usr/share/dict/words -o words.c
    % gcc words.c
    % ./a.out|sort -n|tail
    98558 "licorice's"
    98559 "neodymium's"
    98560 "Nader's"
    98561 "begotten"
    98562 "Tehran"
    98563 "spunks"
    98564 "druids"
    98565 "glowworms"
    98566 "moralizes"
    98567 "verdigris's"

Note that the given file is single-column, table values are not shown.

### Quoted String

The keys and values can be quoted strings.

    % head /usr/share/X11/rgb.txt
    ! $Xorg: rgb.txt,v 1.3 2000/08/17 19:54:00 cpqbld Exp $
    255 250 250             snow
    248 248 255             ghost white
    248 248 255             GhostWhite
    245 245 245             white smoke
    245 245 245             WhiteSmoke
    220 220 220             gainsboro
    255 250 240             floral white
    255 250 240             FloralWhite
    253 245 230             old lace
    % ruby -e '
    ARGF.each_line {|line|
      next if /^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\S.*\S)\s*$/ !~ line
      printf "\"%s\" \"\\%03o\\%03o\\%03o\"\n", $4, $1.to_i, $2.to_i, $3.to_i
    }' /usr/share/X11/rgb.txt > colordict
    % head colordict 
    "snow" "\377\372\372"
    "ghost white" "\370\370\377"
    "GhostWhite" "\370\370\377"
    "white smoke" "\365\365\365"
    "WhiteSmoke" "\365\365\365"
    "gainsboro" "\334\334\334"
    "floral white" "\377\372\360"
    "FloralWhite" "\377\372\360"
    "old lace" "\375\365\346"
    "OldLace" "\375\365\346"
    % mphash colordict > color.c
    % gcc color.c 
    % ./a.out|head
    483 "snow" "\377\372\372"
    287 "ghost white" "\370\370\377"
    430 "GhostWhite" "\370\370\377"
    151 "white smoke" "\365\365\365"
    632 "WhiteSmoke" "\365\365\365"
    661 "gainsboro" "\334\334\334"
    708 "floral white" "\377\372\360"
    145 "FloralWhite" "\377\372\360"
    567 "old lace" "\375\365\346"
    87 "OldLace" "\375\365\346"

### Options for Generating Libraries

    # self-contained test command
    #
    mphash -o command.c dictfile                  # source code including main
    mphash -o command.c keyfile                   # source code including main

    # single hash table
    #
    # table.[ch] provides mpht().
    # The function name is overridden by -n option.
    #
    mphash -tH [-n table_funcname] -o table.h             # declaration
    mphash -t [-n table_funcname] -o table.c dictfile     # definition

    # single hash function
    #
    # hash.[ch] provides mphf().
    # The function name is overridden by -n option.
    #
    mphash -fH [-n hash_funcname] -o hash.h               # declaration
    mphash -f [-n hash_funcname] -o hash.c keyfile        # definition

    # multiple hash tables/functions
    #
    # mphash.[ch] provides mphash_table_lookup() and mphash_generic().
    #
    # tparam.[ch] provides mpht_param.
    # The name is overridden by -n option.
    #
    # hparam.[ch] provides mphf_param.
    # The name is overridden by -n option.
    #
    mphash -cH -o mphash.h                                # common declaration
    mphash -c -o mphash.c                                 # common definition
    mphash -tpH [-n table_paramname] -o tparam.h          # table declaration
    mphash -tp [-n table_paramname] -o tparam.h dictfile  # table definition
    mphash -fpH [-n hash_paramname] -o hparam.h           # hash declaration
    mphash -fp [-n hash_paramname] -o hparam.h keyfile    # hash definition

## Requirements

* Ruby 1.8.6-p111 : http://www.ruby-lang.org/
  (older version may work)

## Download

* latest release: none

* development version: http://github.com/akr/mphash

## Install

    % ruby extconf.rb
    % make
    % make install

optional:

    % make test
    % make rdoc

## Reference Manual

See rdoc/index.html or
http://www.a-k-r.org/mphash/rdoc/

## References

Botelho, F.C., Pagh, R. and Ziviani, N.
"Simple and Space-Efficient Minimal Perfect Hash Functions"
10th International Workshop on Algorithms and Data Structures (WADS07) August 2007, 139-150

Daisuke Okanohara
"Bep: Associative Arrays for Very Large Collections"
http://www-tsujii.is.s.u-tokyo.ac.jp/~hillbig/bep.htm

Bob Jenkins
"LOOKUP3.C, for hash table lookup"
http://burtleburtle.net/bob/c/lookup3.c

## License

### mphash itself

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
        list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright notice,
        this list of conditions and the following disclaimer in the documentation
        and/or other materials provided with the distribution.
    3. The name of the author may not be used to endorse or promote products
        derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
    WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
    MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
    EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
    OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
    IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
    OF SUCH DAMAGE.

(The modified BSD licence)

### code generated by mphash

Public Domain

