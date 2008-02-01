/*
mphash.c - mphash extension for hash function implementation.

Copyright (C) 2008 Tanaka Akira  <akr@fsij.org>

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
*/

#include "ruby.h"
#include <stdint.h>

#define SELF_TEST 0
#include "hash/lookup3.c"
#include "code/code_lookup3.c"

/*
 *  call-seq: 
 *    MPHash.jenkins_lookup3(str, initval=0)  => integer
 *
 *  Returns a hash value using Bob Jenkins' LOOKUP3.
 *  The hash value is 32bit unsigned integer.
 *
 *  <i>initval</i> is the previous hash, or an arbitrary value.
 */

static VALUE
jenkins_lookup3(int argc, VALUE *argv, VALUE klass)
{
  VALUE str, initval;
  uint32_t iv = 0;
  uint32_t hash;

  if (rb_scan_args(argc, argv, "11", &str, &initval) == 2) {
    iv = NUM2UINT(initval);
  }

  StringValue(str);

  hash = hashlittle(RSTRING_PTR(str), RSTRING_LEN(str), iv);

  return UINT2NUM(hash);
}

/*
 *  call-seq: 
 *    MPHash.jenkins_lookup3_2(str, initval1=0, initval2=0)  => [integer, integer]
 *
 *  Returns a hash values using hashlittle2 in Bob Jenkins' LOOKUP3.
 *  It returns two hash values.
 *  The hash values are 32bit unsigned integer.
 *
 *  The first hash value is same as a result of MPHash.jenkins_lookup3.
 *
 *  <i>initval</i> is the previous hash, or an arbitrary value.
 */

static VALUE
jenkins_lookup3_2(int argc, VALUE *argv, VALUE klass)
{
  VALUE str, initval1, initval2;
  int numargs;
  uint32_t hash1 = 0, hash2 = 0;

  numargs = rb_scan_args(argc, argv, "12", &str, &initval1, &initval2);
  if (2 <= numargs) hash1 = NUM2UINT(initval1);
  if (3 <= numargs) hash2 = NUM2UINT(initval2);

  StringValue(str);

  hashlittle2(RSTRING_PTR(str), RSTRING_LEN(str), &hash1, &hash2);

  return rb_assoc_new(UINT2NUM(hash1), UINT2NUM(hash2));
}

void
Init_mphash()
{
  VALUE cMPHash;

  cMPHash = rb_define_class("MPHash", rb_cObject);
  rb_define_singleton_method(cMPHash, "jenkins_lookup3", jenkins_lookup3, -1);
  rb_define_singleton_method(cMPHash, "jenkins_lookup3_2", jenkins_lookup3_2, -1);
  rb_define_const(cMPHash, "JENKINS_LOOKUP3", rb_str_new(hash_lookup3, sizeof(hash_lookup3)-1));
}


