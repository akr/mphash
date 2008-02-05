require 'test/unit'
require 'mphash'

class TestUndump < Test::Unit::TestCase
  def test_oct
    0x00.upto(0xff) {|c|
      expected = [c].pack("C")
      dumped_list = [
        '"\\%03o"' % c,
        '"\\%02o"' % c,
        '"\\%01o"' % c,
      ]
      dumped_list.each {|dumped|
        result = nil
        assert_nothing_raised("MPHash.str_undump(#{dumped.inspect})") {
          result = MPHash.str_undump(dumped)
        }
        assert_equal(expected, result, "MPHash.str_undump(#{dumped.inspect})")
      }
    }
  end

  def test_hex
    0x00.upto(0xff) {|c|
      expected = [c].pack("C")
      dumped_list = [
        '"\\x%02x"' % c,
        '"\\x%01x"' % c,
      ]
      dumped_list.each {|dumped|
        result = nil
        assert_nothing_raised("MPHash.str_undump(#{dumped.inspect})") {
          result = MPHash.str_undump(dumped)
        }
        assert_equal(expected, result, "MPHash.str_undump(#{dumped.inspect})")
      }
    }
  end

  def test_mnemonic
    assert_equal("\t", MPHash.str_undump('"\t"'))
    assert_equal("\n", MPHash.str_undump('"\n"'))
    assert_equal("\r", MPHash.str_undump('"\r"'))
    assert_equal("\f", MPHash.str_undump('"\f"'))
    assert_equal("\b", MPHash.str_undump('"\b"'))
    assert_equal("\a", MPHash.str_undump('"\a"'))
    assert_equal("\v", MPHash.str_undump('"\v"'))
    assert_equal("\e", MPHash.str_undump('"\e"'))
  end

end
