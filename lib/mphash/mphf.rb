# mphash/mphf.rb - minimal perfect hash generator
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

class MPHash
  NON_KEY = -1

  # :stopdoc:
  class HashTuple
    @saltcounter = 0

    def self.gensalt
      ret = @saltcounter
      @saltcounter += 1
      ret
    end

    def initialize(r, range)
      @r = r
      @range = range
      @m = @r * range
      @min = (0...@r).map {|i| i * range }
      @salt = (0...@r).map { HashTuple.gensalt }
    end

    def makehash_with_hashes(str)
      hs = MPHash.jenkins_lookup3_2(str, @salt[0], @salt[1]) << MPHash.jenkins_lookup3(str, @salt[2])
      result = []
      result << hs[0] % @range
      result << (hs[1] % @range) + @min[1]
      result << (hs[2] % @range) + @min[2]
      return result, hs
    end

    def makehash(str)
      makehash_with_hashes(str).first
    end
  end
  # :startdoc:

  # MPHF is a generator for minimal perfect hash function.
  class MPHF
    # generate a minimal perfect hash function from an array of strings.
    def initialize(keys)
      keys = keys.dup
      check_keys keys
      @r = 3
      @n = keys.length
      @range = ((@n * 1.23).ceil + @r - 1) / @r
      @range = 2 if @range <= 1
      @m = @range * @r
      ordered_edges = mapping(keys)
      assigning ordered_edges
      ranking
    end

    # returns number of keys.
    def size
      @n
    end

    # :stopdoc:
    def check_keys(keys)
      h = {}
      keys.each {|k|
        if h[k]
          raise ArgumentError, "duplicate key: #{k.inspect}"
        end
        h[k] = true
      }
    end

    def mapping(keys)
      begin
        hashtuple = HashTuple.new(@r, @range)
        hs = keys.map {|key| hashtuple.makehash(key) }
        ordered_edges = check_ascyclic(hs)
        #raise "cycle found" if !ordered_edges
      end until ordered_edges
      @hashtuple = hashtuple
      ordered_edges
    end

    def check_ascyclic(edges)
      v2es = Array.new(@m) { [] }
      edges.each_with_index {|e, i|
        e.each {|n|
          v2es[n] << e
        }
      }
      ordered_edges = []
      v2es.each_index {|node|
        next if v2es[node].length != 1
        stack = [node]
        until stack.empty?
          node = stack.pop
          next if v2es[node].length == 0
          if v2es[node].length != 1
            raise "unexpected degree"
          end
          e = v2es[node].first
          ordered_edges << e
          e.each {|n|
            v2es[n].delete e
          }
          e.each {|n|
            stack << n if v2es[n].length == 1
          }
        end
      }
      if v2es.any? {|es| !es.empty? }
        return nil # cycle found
      end
      ordered_edges
    end

    def assigning(ordered_edges)
      @g = Array.new(@m, @r)
      visited = Array.new(@m, false)
      ordered_edges.reverse_each {|e|
        u = e.find {|n| !visited[n] }
        j = e.index(u)
        e.each {|v|
          next if !visited[v]
          j -= @g[v]
        }
        @g[u] = j % @r
        e.each {|v|
          visited[v] = true
        }
      }
    end

    RANK_SUPERBLOCKSIZE = 256
    RANK_SMALLBLOCKSIZE = 32
    def ranking
      @rs = []
      @rb = []
      k = 0
      @g.each_with_index {|j, i|
        if i != 0
          if i % RANK_SUPERBLOCKSIZE == 0
            @rs << k
          elsif i % RANK_SMALLBLOCKSIZE == 0
            @rb << (k - @rs.fetch(-1, 0))
          end
        end
        next if j == @r
        k += 1
      }
    end

    def phf(key)
      phf_with_hashes(key).first
    end

    def phf_with_hashes(key)
      hs, full_hs = @hashtuple.makehash_with_hashes(key)
      i = hs.inject(0) {|sum, h| sum + @g[h] }
      return hs[i % @r], full_hs
    end
    # :startdoc:

    # returns a pair of a hash code and an array of integers.
    #
    # The hash code is identical to one returned by hashcode method.
    #
    # The array contains three internal 32bit hash code for <i>key</i>.
    def hashcode_with_internal_hashes(key)
      h, full_hs = phf_with_hashes(key)
      if @g[h] == @r
        return NON_KEY, full_hs # no key
      end
      a, b = h.divmod(RANK_SUPERBLOCKSIZE)
      if a == 0
        result = 0
      else
        result = @rs[a-1]
      end
      b, c = b.divmod(RANK_SMALLBLOCKSIZE)
      if b != 0
        result += @rb[a*(RANK_SUPERBLOCKSIZE/RANK_SMALLBLOCKSIZE-1)+b-1]
      end
      (h-c).upto(h-1) {|i|
        result += 1 if @g[i] != @r
      }
      return result, full_hs
    end

    # returns a hash code of <i>key</i>.
    #
    # The return value is 0 to number of keys minus one, or
    # MPHash::NON_KEY.
    #
    # MPHash::NON_KEY means the given <i>key</i> is not a key.
    # However <i>key</i> may not be a key even if the return value
    # is not MPHash::NON_KEY.
    def hashcode(key)
      hashcode_with_internal_hashes(key).first
    end
  end
end
