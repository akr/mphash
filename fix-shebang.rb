#!/usr/bin/ruby

# fix-shebang.rb - fix shebang line
#
# Copyright (C) 2008 Tanaka Akira  <akr@fsij.org>
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#  1. Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#  3. The name of the author may not be used to endorse or promote products
#     derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.

# usage: ruby fix-shebang.rb [-o destination] [source]

require 'optparse'
require 'rbconfig'

$opt_dest = nil
op = OptionParser.new
op.def_option('-h') { puts op; exit 0 }
op.def_option('-o destination') {|destination| $opt_dest = destination }
op.parse!

rubybin = [RbConfig::CONFIG["bindir"], RbConfig::CONFIG["ruby_install_name"]].join('/')
script = ARGF.read
script.sub!(%r{\A\#!/usr/bin/env ruby}) { "\#!#{rubybin}" }

if $opt_dest
  n = 1
  begin
    tmpname = "#{$opt_dest}.tmp#{n}"
    f = File.open(tmpname, File::WRONLY|File::CREAT|File::EXCL)
  rescue Errno::EEXIST
    n += 1
    retry
  end
  begin
    f << script
  ensure
    f.close
  end
  File.rename(tmpname, $opt_dest)
else
  puts script
end
