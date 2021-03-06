# mphash/escape.rb - escape library for mphash
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

# :stopdoc:
class MPHash
  C_ESCAPE_MNEMONIC = {
    't' => "\t",
    'n' => "\n",
    'r' => "\r",
    'f' => "\f",
    'b' => "\b",
    'a' => "\a",
    'v' => "\v"
  }

  SRC_UNESCAPE = {}
  SRC_UNESCAPE.update C_ESCAPE_MNEMONIC
  SRC_UNESCAPE['e'] = "\e"

  0.upto(0xff) {|c|
    s = [c].pack("C")
    SRC_UNESCAPE["%03o" % c] = s
    SRC_UNESCAPE["%02o" % c] = s
    SRC_UNESCAPE["%01o" % c] = s
    SRC_UNESCAPE["x%02x" % c] = s
    SRC_UNESCAPE["x%01x" % c] = s
    if 0x20 <= c && c <= 0x7e && /[0-9A-Za-z]/ !~ s
      SRC_UNESCAPE[s] = s
    end
  }

  sorted_keys = SRC_UNESCAPE.keys.sort_by {|k| -k.length }
  QUOTED_STRING_PAT = /"((?:[^\\"]|\\(?:[tnrfbave -\/:-@\[-`\{-~]|x[0-9A-Fa-f][0-9A-Fa-f]?|[0-3][0-7][0-7]|[0-7][0-7]?))*)"/o
  QUOTED_STRING_CONTENT_PAT = %r{[^\\"]|\\([tnrfbave -\/:-@\[-`\{-~]|x[0-9A-Fa-f][0-9A-Fa-f]?|[0-3][0-7][0-7]|[0-7][0-7]?)}o
  def MPHash.str_undump(str)
    if /\A#{QUOTED_STRING_PAT}\z/o !~ str
      raise ArgumentError, "invalid quoting: #{str.inspect}"
    end
    content = $1
    key = content.gsub(QUOTED_STRING_CONTENT_PAT) {
      if $1
        SRC_UNESCAPE.fetch($1) { raise ArgumentError, "unexpected escape sequence : #{$1.inspect}" }
      else
        $&
      end
    }
  end

  C_STRING_ESCAPE = {
    "\\" => "\\\\",
    '"' => '\"',
  }
  C_ESCAPE_MNEMONIC.each {|mnemonic, ch|
    C_STRING_ESCAPE[ch] = "\\#{mnemonic}"
  }
  0x00.upto(0x1f) {|ch| C_STRING_ESCAPE[[ch].pack("C")] ||= "\\%03o" % ch }
  0x7f.upto(0xff) {|ch| C_STRING_ESCAPE[[ch].pack("C")] = "\\%03o" % ch }
  C_STRING_ESCAPE_PAT = Regexp.union(*C_STRING_ESCAPE.keys)
  def MPHash.escape_as_c_string(str)
    '"' + str.gsub(C_STRING_ESCAPE_PAT) { C_STRING_ESCAPE[$&] } + '"'
  end

  C_CHARACTER_ESCAPE = {
    "\0".ord => "'\\0'",
    "\\".ord => "'\\\\'",
    '\''.ord => "'\\\''",
  }
  C_ESCAPE_MNEMONIC.each {|mnemonic, ch|
    C_CHARACTER_ESCAPE[ch.ord] = "'\\#{mnemonic}'"
  }
  0x00.upto(0x1f) {|ch| C_CHARACTER_ESCAPE[ch] ||= "'\\%03o'" % ch }
  0x20.upto(0x7f) {|ch| C_CHARACTER_ESCAPE[ch] ||= "'#{[ch].pack("C")}'" }
  0x7f.upto(0xff) {|ch| C_CHARACTER_ESCAPE[ch] = "'\\%03o'" % ch }
  def MPHash.escape_as_c_characters(str)
    str.unpack("C*").map {|c| C_CHARACTER_ESCAPE[c] }
  end

end
# :startdoc:
