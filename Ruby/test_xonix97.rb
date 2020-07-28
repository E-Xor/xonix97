#!/usr/bin/env ruby

require_relative 'xonix97'
require 'test/unit'

class TestGameDefs < Test::Unit::TestCase
  def test_objects_count
    assert_equal(GameDefs.object_counts(1),  {white_dots: 3, black_dots: 1, orange_lines: 0})
    assert_equal(GameDefs.object_counts(2),  {white_dots: 3, black_dots: 1, orange_lines: 1})
    assert_equal(GameDefs.object_counts(3),  {white_dots: 4, black_dots: 1, orange_lines: 1})
    assert_equal(GameDefs.object_counts(4),  {white_dots: 4, black_dots: 2, orange_lines: 1})
    assert_equal(GameDefs.object_counts(5),  {white_dots: 4, black_dots: 2, orange_lines: 2})
    assert_equal(GameDefs.object_counts(6),  {white_dots: 5, black_dots: 2, orange_lines: 2})
    assert_equal(GameDefs.object_counts(7),  {white_dots: 5, black_dots: 3, orange_lines: 2})
    assert_equal(GameDefs.object_counts(8),  {white_dots: 5, black_dots: 3, orange_lines: 3})
    assert_equal(GameDefs.object_counts(9),  {white_dots: 6, black_dots: 3, orange_lines: 3})
    assert_equal(GameDefs.object_counts(10), {white_dots: 6, black_dots: 4, orange_lines: 3})
    assert_equal(GameDefs.object_counts(11), {white_dots: 6, black_dots: 4, orange_lines: 4})
    assert_equal(GameDefs.object_counts(12), {white_dots: 7, black_dots: 4, orange_lines: 4})
    assert_equal(GameDefs.object_counts(13), {white_dots: 7, black_dots: 4, orange_lines: 4})
    assert_equal(GameDefs.object_counts(14), {white_dots: 7, black_dots: 4, orange_lines: 4})
    assert_equal(GameDefs.object_counts(15), {white_dots: 8, black_dots: 4, orange_lines: 4})
  end

  def test_time_limit
    assert_equal(GameDefs.time_limit(1),  60)
    assert_equal(GameDefs.time_limit(2),  120)
    assert_equal(GameDefs.time_limit(3),  180)
    assert_equal(GameDefs.time_limit(4),  240)
    assert_equal(GameDefs.time_limit(5),  300)
    assert_equal(GameDefs.time_limit(6),  300)
    assert_equal(GameDefs.time_limit(15), 300)
  end

  def test_bonus
    assert_equal(GameDefs.bonus(GameDefs.time_limit(1), GameDefs.time_limit(1), false),  300)
    assert_equal(GameDefs.bonus(GameDefs.time_limit(1), GameDefs.time_limit(1), true),  0)
    assert_equal(GameDefs.bonus(45, GameDefs.time_limit(1), false),  150)
    assert_equal(GameDefs.bonus(31, GameDefs.time_limit(1), false),  10)
    assert_equal(GameDefs.bonus(30, GameDefs.time_limit(1), false),  0)
    assert_equal(GameDefs.bonus(15, GameDefs.time_limit(1), false),  0)

    assert_equal(GameDefs.bonus(GameDefs.time_limit(2), GameDefs.time_limit(2), false),  600)
    assert_equal(GameDefs.bonus(GameDefs.time_limit(3), GameDefs.time_limit(3), false),  900)
    assert_equal(GameDefs.bonus(GameDefs.time_limit(4), GameDefs.time_limit(4), false),  1200)
    assert_equal(GameDefs.bonus(GameDefs.time_limit(5), GameDefs.time_limit(5), false),  1500)
    assert_equal(GameDefs.bonus(GameDefs.time_limit(6), GameDefs.time_limit(6), false),  1500)

    assert_equal(GameDefs.bonus(GameDefs.time_limit(15), GameDefs.time_limit(15), false), 1500)
    assert_equal(GameDefs.bonus(GameDefs.time_limit(15), GameDefs.time_limit(15), true), 0)
    assert_equal(GameDefs.bonus(250, GameDefs.time_limit(15), false), 1000)
    assert_equal(GameDefs.bonus(151, GameDefs.time_limit(15), false), 10)
    assert_equal(GameDefs.bonus(150, GameDefs.time_limit(15), false), 0)
    assert_equal(GameDefs.bonus(100, GameDefs.time_limit(15), false), 0)
  end
end

class TextXonix97 < Test::Unit::TestCase
  def test_next_level
    x = Xonix97.new
    assert_equal(x.instance_variable_get(:@level), 1)
    assert_equal(x.instance_variable_get(:@white_dots).count, 3)
    assert_equal(x.instance_variable_get(:@black_dots).count, 1)
    assert_equal(x.instance_variable_get(:@orange_lines).count, 0)

    x.next_level
    assert_equal(x.instance_variable_get(:@level), 2)
    assert_equal(x.instance_variable_get(:@white_dots).count, 3)
    assert_equal(x.instance_variable_get(:@black_dots).count, 1)
    assert_equal(x.instance_variable_get(:@orange_lines).count, 1)
  end
end

