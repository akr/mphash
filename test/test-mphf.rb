require 'test/unit'
require 'mphash'

class TestMPHF < Test::Unit::TestCase
  def check_mphf(keys)
    mphf = MPHash::MPHF.new(keys)
    check = {}
    keys.each {|key|
      hash = mphf.hashcode(key)
      assert_operator(0, :<=, hash)
      assert_operator(hash, :<, keys.length)
      assert_nil(check[hash], "collision: #{hash} : #{check[hash].inspect} #{key.inspect}")
      check[hash] = key
    }
    10.times {
      key = rand.to_s
      hash = mphf.hashcode(key)
      if hash != -1
        assert_operator(0, :<=, hash)
        assert_operator(hash, :<, keys.length)
      end
    }
  end

  def test_smallset
    keys = %w[foo bar baz]
    check_mphf(keys)
  end

  def test_largeset
    keys = ["a"]
    1000.times { keys << keys.last.succ }
    check_mphf(keys)
  end

  def test_emptyset
    keys = []
    check_mphf(keys)
  end

  def test_singleton
    keys = ["a"]
    check_mphf(keys)
  end

end
