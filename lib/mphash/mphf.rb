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

    def makehash(str)
      result = MPHash.jenkins_lookup3_2(str, @salt[0], @salt[1]) << MPHash.jenkins_lookup3(str, @salt[2])
      result[0] = result[0] % @range
      result[1] = (result[1] % @range) + @min[1]
      result[2] = (result[2] % @range) + @min[2]
      result
    end
  end

  class MPHF
    def initialize(keys)
      keys = keys.dup
      @r = 3
      @n = keys.length
      @range = ((@n * 1.23).ceil + @r - 1) / @r
      @m = @range * @r
      ordered_edges = mapping(keys)
      assigning ordered_edges
      ranking
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

    RANK_BLOCKSIZE = 256
    def ranking
      @ranking = []
      k = 0
      @g.each_with_index {|j, i|
        @ranking << k if i % RANK_BLOCKSIZE == 0
        next if j == @r
        k += 1
      }
    end

    def phf(key)
      hs = @hashtuple.makehash(key)
      i = hs.inject(0) {|sum, h| sum + @g[h] }
      hs[i % @r]
    end

    def mphf(key)
      h = phf(key)
      a = h / RANK_BLOCKSIZE
      result = @ranking[a]
      (a * RANK_BLOCKSIZE).upto(h-1) {|i|
        result += 1 if @g[i] != @r
      }
      result
    end
  end
end
