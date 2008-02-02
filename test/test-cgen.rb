require 'test/unit'
require 'mphash'
require 'rbconfig'
require 'fileutils'
require 'tmpdir'

unless Dir.respond_to? :mktmpdir
  def Dir.mktmpdir(prefix_suffix=nil, tmpdir=nil)
    case prefix_suffix
    when nil
      prefix = "d"
      suffix = ""
    when String
      prefix = prefix_suffix
      suffix = ""
    when Array
      prefix = prefix_suffix[0]
      suffix = prefix_suffix[1]
    else
      raise ArgumentError, "unexpected prefix_suffix: #{prefix_suffix.inspect}"
    end
    tmpdir ||= Dir.tmpdir
    t = Time.now.strftime("%Y%m%d")
    n = nil
    begin
      path = "#{tmpdir}/#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"
      path << "-#{n}" if n
      path << suffix
      Dir.mkdir(path, 0700)
    rescue Errno::EEXIST
      n ||= 0
      n += 1
      retry
    end

    if block_given?
      begin
        yield path
      ensure
        FileUtils.remove_entry_secure path
      end
    else
      path
    end
  end
end

class TestMPHF_CGen < Test::Unit::TestCase
  RUBY = [RbConfig::CONFIG["bindir"], RbConfig::CONFIG["ruby_install_name"]].join('/')
  MPHASH_SRCDIR = File.dirname(File.dirname(File.expand_path(__FILE__)))
  MPHASH_LIBDIR =  "#{MPHASH_SRCDIR}/lib"
  MPHASH_BIN = "#{MPHASH_SRCDIR}/bin/mphash.in"
  CC = 'gcc'

  def write_file(filename, content)
    File.open(filename, 'w') {|f|
      f << content
    }
  end

  def run_mphash(*args)
    command = [RUBY, "-I#{MPHASH_LIBDIR}", "-I#{MPHASH_SRCDIR}", MPHASH_BIN, *args]
    system(*command)
  end

  def reset_hash_salt
    MPHash::HashTuple.instance_eval { @saltcounter = 0 }
  end

  def make_mhpf(keys)
    reset_hash_salt
    MPHash::MPHF.new(keys)
  end

  SAMPLE_ARRAYS = [
    %w[foo bar baz],
    (0..1000).map { rand.to_s }
  ]
  def test_command
    Dir.mktmpdir {|d|
      Dir.chdir d
      SAMPLE_ARRAYS.each_with_index {|ary, i|
        mphf = make_mhpf(ary)
        write_file "keyfile", ary.join("\n")
        run_mphash 'keyfile', '-o', 'tst.c'
        system(CC, 'tst.c'); assert($?)
        list = `./a.out`
        list.each_line {|line|
          pat = /\A(\d+) "(.*)"\n\z/
          assert_match(pat, line)
          pat =~ line
          h = $1.to_i
          k = $2
          assert(ary.include?(k))
          assert_equal(mphf.mphf(k), h)
        }
      }
    }
  end

  SMALL_ARRAY = %w[foo bar baz]

  def test_func_self_contained
    Dir.mktmpdir {|d|
      Dir.chdir d
      ary = SMALL_ARRAY
      mphf = make_mhpf(ary)
      write_file "keyfile", ary.join("\n")
      run_mphash '-f', 'keyfile', '-o', 'hash.c'
      system(CC, '-c', 'hash.c'); assert($?)
      run_mphash '-fH', '-o', 'hash.h'
      write_file "tst.c", <<'End'
#include "hash.h"
#include <stdio.h>
#include <string.h>
int main(int argc, char **argv)
{
  int i;
  for (i = 1; i < argc; i++) {
    printf("%d\n", mphf(argv[i], strlen(argv[i])));
  }
  return 0;
}
End
      system(CC, '-c', 'tst.c'); assert($?)
      system(CC, 'tst.o', 'hash.o'); assert($?)
      command = "./a.out #{ary.join(" ")}"
      result = `#{command}`
      result = result.split(/\s+/)
      assert_equal(ary.length, result.length)
      ary.each_index {|i|
        assert_equal(mphf.mphf(ary[i]), result[i].to_i)
      }
    }
  end

  def test_func_data_only
    Dir.mktmpdir {|d|
      Dir.chdir d
      ary = SMALL_ARRAY
      mphf = make_mhpf(ary)
      write_file "keyfile", ary.join("\n")
      run_mphash '-cH', '-o', 'mphash.h'
      run_mphash '-c', '-o', 'mphash.c'
      system(CC, '-c', 'mphash.c'); assert($?)
      run_mphash '-fd', 'keyfile', '-o', 'hash.c'
      system(CC, '-c', 'hash.c'); assert($?)
      run_mphash '-fdH', '-o', 'hash.h'
      write_file "tst.c", <<'End'
#include "hash.h"
#include <stdio.h>
#include <string.h>
int main(int argc, char **argv)
{
  int i;
  for (i = 1; i < argc; i++) {
    printf("%d\n", mphash_generic(argv[i], strlen(argv[i]), &mphf_param, NULL, NULL, NULL));
  }
  return 0;
}
End
      system(CC, '-c', 'tst.c')
      assert($?)
      system(CC, 'tst.o', 'hash.o', 'mphash.o')
      assert($?)
      command = "./a.out #{ary.join(" ")}"
      result = `#{command}`
      result = result.split(/\s+/)
      assert_equal(ary.length, result.length)
      ary.each_index {|i|
        assert_equal(mphf.mphf(ary[i]), result[i].to_i)
      }
    }
  end

  SMALL_ASSOC = [%w[foo hoge], %w[bar fuga]]
  def test_table_self_contained
    Dir.mktmpdir {|d|
      Dir.chdir d
      assoc = SMALL_ASSOC
      write_file "dict", assoc.map {|k,v| "#{k} #{v}\n" }.join("")
      run_mphash '-t', 'dict', '-o', 'table.c'
      system(CC, '-c', 'table.c'); assert($?)
      run_mphash '-tH', '-o', 'table.h'
      write_file "tst.c", <<'End'
#include "table.h"
#include <stdio.h>
#include <string.h>
int main(int argc, char **argv)
{
  int i;
  for (i = 1; i < argc; i++) {
    size_t len;
    void *val = mpht(argv[i], strlen(argv[i]), &len);
    if (val)
      printf("%.*s\n", (int)len, (char*)val);
    else
      puts("not-found");
  }
  return 0;
}
End
      system(CC, '-c', 'tst.c'); assert($?)
      system(CC, 'tst.o', 'table.o'); assert($?)
      command = "./a.out #{assoc.map {|k,v| k }.join(" ")}"
      result = `#{command}`
      result = result.split(/\s+/)
      assert_equal(assoc.length, result.length)
      assoc.each_index {|i|
        assert_equal(assoc[i][1], result[i])
      }
    }
  end

  def test_table_data_only
    Dir.mktmpdir {|d|
      Dir.chdir d
      assoc = SMALL_ASSOC
      write_file "dict", assoc.map {|k,v| "#{k} #{v}\n" }.join("")
      run_mphash '-cH', '-o', 'mphash.h'
      run_mphash '-c', '-o', 'mphash.c'
      system(CC, '-c', 'mphash.c'); assert($?)
      run_mphash '-td', 'dict', '-o', 'table.c'
      system(CC, '-c', 'table.c'); assert($?)
      run_mphash '-tdH', '-o', 'table.h'
      write_file "tst.c", <<'End'
#include "table.h"
#include <stdio.h>
#include <string.h>
int main(int argc, char **argv)
{
  int i;
  for (i = 1; i < argc; i++) {
    size_t len;
    const void *val = mphash_table_lookup(argv[i], strlen(argv[i]), &mpht_param, &len);
    if (val)
      printf("%.*s\n", (int)len, (char*)val);
    else
      puts("not-found");
  }
  return 0;
}
End
      system(CC, '-c', 'tst.c')
      assert($?)
      system(CC, 'tst.o', 'table.o', 'mphash.o')
      assert($?)
      command = "./a.out #{assoc.map {|k,v| k }.join(" ")}"
      command = "./a.out #{assoc.map {|k,v| k }.join(" ")}"
      result = `#{command}`
      result = result.split(/\s+/)
      assert_equal(assoc.length, result.length)
      assoc.each_index {|i|
        assert_equal(assoc[i][1], result[i])
      }
    }
  end

end
