#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'gosu'

# 1 frame = 17ms @60 FPS

# puts "__dir__ :#{__dir__}"
# puts

# files = Dir["#{__dir__}/*"]
# puts "files in __dir__: #{files.join(',')}"
# puts

# files = Dir["./Resources/*"]
# puts "files in ./Resources/*: #{files.join(',')}"
# puts

# files = Dir["../Resources/*"]
# puts "files in ../Resources/*: #{files.join(',')}"
# puts

# files = Dir["#{__dir__}/../Resources/*"]
# puts "files in __dir__/../Resources/*: #{files.join(',')}"
# puts

# files = Dir["/*"]
# puts "files in /*: #{files.join(',')}"
# puts

# files = Dir["~/*"]
# puts "files in ~/*: #{files.join(',')}"
# puts

# puts 'ls -al'
# puts `ls -al`
# puts

# puts 'ls -al ~/'
# puts `ls -al ~/`
# puts

# puts 'ls -al /'
# puts `ls -al /`
# puts

# puts 'pwd'
# puts `pwd`
# puts

# print "Press ENTER to continue"
# gets

MEDIA_DIR = `pwd`.chomp + '/../Resources' # not __dir__, when compiled into binary code it has differenent return compared to pwd

FIELD_WIDTH, FIELD_HEIGHT = 510, 322
TOTAL_SQUARES = FIELD_WIDTH * FIELD_HEIGHT
WIDTH, HEIGHT = FIELD_WIDTH, FIELD_HEIGHT + 25 # 25 is for status bar

FPS_DEBUG = true

module GameDefs
  Blue    = 0
  Black   = 1
  Red     = 2
  Checked = 10
  Border  = 20

  def self.object_counts(level)
    {
      white_dots:   [8, 3 + level / 3].min,
      black_dots:   [4, (1 + (level - 1) / 3)].min,
      orange_lines: [4, (level + 1) / 3].min
    }
  end

  def self.time_limit(level, died_on_this_level)
    limit = 60 * [5, level].min
    limit /= 2 if died_on_this_level

    limit
  end

  def self.bonus(time_remaining, time_limit, died_on_this_level)
    half_time_limit = time_limit/2

    if !died_on_this_level && time_remaining > half_time_limit
      return 10 * (time_remaining - half_time_limit)
    end

    return 0
  end

end

class Dot
  attr_reader :x, :y, :x_speed, :y_speed
  OFFSET = 3
  Z_ORDER = 4
  GAP = 50

  def initialize(x: nil, y: nil)

    Random.new_seed

    if x
      @x = x
    else
      @x = GAP + rand(FIELD_WIDTH - 2 * GAP)
    end

    if y
      @y = y
    else
      @y = GAP + rand(FIELD_HEIGHT - 2 * GAP)
    end

    @x_speed = -@x_speed if rand(2) == 1
    @y_speed = -@y_speed if rand(2) == 1
  end

  def bounce(field_bmp)

    if y_border || next_pix_y(field_bmp) == @bounce_pix 
      @y_speed = -@y_speed
    end

    if x_border || next_pix_x(field_bmp) == @bounce_pix
      @x_speed = -@x_speed
    end

  end

  def update(field_bmp)
    bounce(field_bmp)
    @x += @x_speed
    @y += @y_speed
  end

  def draw
    @image.draw(@x - OFFSET, @y - OFFSET, Z_ORDER)
  end

  private

  def next_pix_y(field_bmp)
    if @y_speed > 0
      next_y = field_bmp[@y + @y_speed + OFFSET]
    else
      next_y = field_bmp[@y + @y_speed - OFFSET]
    end

    if next_y
      pix = next_y[@x]
    else 
      pix = @bounce_pix
    end
    pix
  end

  def next_pix_x(field_bmp)
    if @x_speed > 0
      pix = field_bmp[@y][@x + @x_speed + OFFSET]
    else
      pix = field_bmp[@y][@x + @x_speed - OFFSET]
    end

    pix = @bounce_pix unless pix

    pix
  end

  def x_border
    if @x_speed > 0
      @x + @x_speed + OFFSET > FIELD_WIDTH
    else
      @x + @x_speed - OFFSET < 0
    end
  end

  def y_border
    if @y_speed > 0
      @y + @y_speed + OFFSET > FIELD_HEIGHT
    else
      @y + @y_speed - OFFSET < 0
    end
  end
end

class WhiteDot < Dot
  def initialize
    @bounce_pix = GameDefs::Blue
    @image = Gosu::Image.new("#{MEDIA_DIR}/wdot.png")
    @x_speed = rand(2) + 1
    @y_speed = rand(2) + 1

    super
  end
end

class BlackDot < Dot
  def initialize
    @bounce_pix = GameDefs::Black # and Red
    @image = Gosu::Image.new("#{MEDIA_DIR}/bdot.png")

    @x_speed = 2
    @y_speed = 2

    y = rand(4) + (FIELD_HEIGHT - GameDefs::Border + 10)
    x = GameDefs::Border + rand(FIELD_WIDTH - GameDefs::Border)
    super(x: x, y: y)
  end
end

class LineDot < Dot
  def initialize
    @bounce_pix = GameDefs::Blue

    @x_speed = 1
    @y_speed = 1

    super
  end
end

class OrangeLine
  attr_reader :end_one, :end_two
  ORANGE = Gosu::Color.rgba(132, 132, 0, 255)
  Z_ORDER = 3

  def initialize
    @end_one = LineDot.new
    @end_two = LineDot.new
  end

  def update(field_bmp)
    @end_one.update(field_bmp)
    @end_two.update(field_bmp)

    cover_field(field_bmp)
  end

  def draw
    # Draws fat line taking rectangular and rotating it

    angle = Gosu.angle(@end_one.x, @end_one.y, @end_two.x, @end_two.y)
    length = Gosu.distance(@end_one.x, @end_one.y, @end_two.x, @end_two.y)
    width = 3
    Gosu.rotate(angle - 90, @end_one.x, @end_one.y) do
      Gosu.draw_rect(@end_one.x, @end_one.y, length, width, ORANGE, Z_ORDER)
    end
  end

  private

  def cover_field(field_bmp)
    # Based on Bresenham's line
    # Line plus south, north, east, west pixels for fatness

    # The line is always drawn from left to right at the closer to horisontal angle.
    # So two flips might be needed
    # 1. y diff bigger than x diff, meaning line is closer to vertical
    #    swap x and y coordinates in this case
    # 2. top is on right, bottom is on left 
    #    swap top and bottom
    #    line can be built upwards or downwards, but always left to right
    # Main Loop
    #   Increase x and draw a pixel
    #   If error < 0 increase y in the drawing direction
    #   If error < 0 add x diff to it
    #   Every step decrease error by y diff, which is by definition smaller than x diff

    # < 1ms

    x1, y1 = @end_one.x, @end_one.y
    x2, y2 = @end_two.x, @end_two.y
 
    steep = (y2 - y1).abs > (x2 - x1).abs
 
    if steep
      x1, y1 = y1, x1
      x2, y2 = y2, x2
    end
 
    if x1 > x2
      x1, x2 = x2, x1
      y1, y2 = y2, y1
    end
 
    delta_x = x2 - x1
    delta_y = (y2 - y1).abs
    error = delta_x / 2
    up_or_down = y1 < y2 ? 1 : -1

    y = y1
    x1.upto(x2) do |x|
      pixel = steep ? [y,x] : [x,y]
      field_bmp[pixel[1]][pixel[0]] = GameDefs::Black
      field_bmp[pixel[1]+1][pixel[0]] = GameDefs::Black
      field_bmp[pixel[1]][pixel[0]+1] = GameDefs::Black
      field_bmp[pixel[1]-1][pixel[0]] = GameDefs::Black
      field_bmp[pixel[1]][pixel[0]-1] = GameDefs::Black
      error -= delta_y
      if error < 0
        y += up_or_down
        error += delta_x
      end
    end

  end

end

class Field
  attr_reader :field_bmp, :blue_count
  Z_ORDER = 2
  AQUA = Gosu::Color.rgba(0, 132, 132, 255)

  def initialize
    @field_bmp = Array.new(FIELD_HEIGHT) { Array.new(FIELD_WIDTH) }
    @blue_count = 0
    FIELD_HEIGHT.times do |i|
      FIELD_WIDTH.times do |j|
        if i < GameDefs::Border - 1 || j < GameDefs::Border - 1 || i >= FIELD_HEIGHT - GameDefs::Border || j >= FIELD_WIDTH - GameDefs::Border
          @field_bmp[i][j] = GameDefs::Blue
          @blue_count += 1
        else
          @field_bmp[i][j] = GameDefs::Black
        end
      end
    end

    @modified = true
  end

  def update
    if @modified
      modified = false
      # @field_bmp to ImageMagic array
    end
  end

  def draw
    Gosu.draw_rect(0, 0, FIELD_WIDTH, FIELD_HEIGHT, AQUA)

    draw_pieces(GameDefs::Black, Gosu::Color::BLACK)
    draw_pieces(GameDefs::Red, Gosu::Color::RED)
  end

  def flood_fill(white_dots, orange_lines)

    # Replace red with blue
    FIELD_HEIGHT.times do |i|
      FIELD_WIDTH.times do |j|
        
        if @field_bmp[i][j] == GameDefs::Red
          @field_bmp[i][j] = GameDefs::Blue 
          @blue_count += 1
        end

      end
    end

    # Each white dot and yellow line are starting points for the flood fill
    if orange_lines
      start_points = white_dots + orange_lines.map(&:end_one) + orange_lines.map(&:end_two)
    else
      start_points = white_dots
    end

    start_points.each do |d|
      next if @field_bmp[d.y][d.x] == GameDefs::Checked

      queue = [[d.x, d.y]]

      # Basic flood fill, 121ms worst, 14ms best
      # while queue.size > 0
      #   x, y = queue.pop
      #   if @field_bmp[y][x] == GameDefs::Black
      #     @field_bmp[y][x] = GameDefs::Checked
      #     queue << [x + 1, y]
      #     queue << [x, y + 1]
      #     queue << [x - 1, y]
      #     queue << [x, y - 1]
      #   end
      # end

      # Scanline variation, 75ms worst, 12ms best
      # while queue.size > 0
      #   x_start, y = queue.pop
      #   x = x_start
      #   while @field_bmp[y][x] == GameDefs::Black
      #     @field_bmp[y][x] = GameDefs::Checked
      #     queue << [x, y + 1]
      #     queue << [x, y - 1]
      #     x = x + 1
      #   end
      #   x = x_start - 1
      #   while @field_bmp[y][x] == GameDefs::Black
      #     @field_bmp[y][x] = GameDefs::Checked
      #     queue << [x, y + 1]
      #     queue << [x, y - 1]
      #     x = x - 1
      #   end
      # end

      # Scanline with direction check, 51ms worst, 12ms best
      while queue.size > 0
        x_start, y, from_south, from_north = queue.pop
        x = x_start
        while @field_bmp[y][x] == GameDefs::Black
          @field_bmp[y][x] = GameDefs::Checked
          queue << [x, y + 1] unless @field_bmp[y + 1][x] == GameDefs::Checked
          queue << [x, y - 1] unless @field_bmp[y - 1][x] == GameDefs::Checked
          x = x + 1
        end

        x = x_start - 1
        while @field_bmp[y][x] == GameDefs::Black
          @field_bmp[y][x] = GameDefs::Checked
          queue << [x, y + 1] unless @field_bmp[y + 1][x] == GameDefs::Checked
          queue << [x, y - 1] unless @field_bmp[y - 1][x] == GameDefs::Checked
          x = x - 1
        end
      end
    end

    # Replace Black with Blue and Checked with Black
    # Count fill % here

    FIELD_HEIGHT.times do |i|
      FIELD_WIDTH.times do |j|
         
        if @field_bmp[i][j] == GameDefs::Black
          @field_bmp[i][j] = GameDefs::Blue
          @blue_count += 1
        end

        @field_bmp[i][j] = GameDefs::Black if @field_bmp[i][j] == GameDefs::Checked
      end
    end

  end

  def interference?(white_dots)
    white_dots.each do |w|
      return true if @field_bmp[w.y][w.x] == GameDefs::Red
    end

    return false
  end

  def clean_red
    FIELD_HEIGHT.times do |i|
      FIELD_WIDTH.times do |j|
        if @field_bmp[i][j] == GameDefs::Red
          @field_bmp[i][j] = GameDefs::Black
        end
      end
    end
  end

  private

  def draw_pieces(field_bit, filed_color)
    # Draws horizontal lines of the field instead of single pixels
    # 4-8 ms

    @field_bmp.each_with_index do |l, i|
      j = 0
      # Add red
      while j < FIELD_WIDTH
        if l[j] == field_bit
          len = 1 
          start = j
          j += 1
          while l[j]  == field_bit
            len += 1
            j += 1
          end
          Gosu.draw_rect(start, i, len, 1, filed_color, Z_ORDER)
        else
          j += 1
        end
      end
    end
  end

end

class Player
  attr_reader   :score
  attr_accessor :xonii, :died_on_this_level

  COLLISION = 5
  OFFSET = 3
  SPEED = 4
  Z_ORDER = 10

  def initialize
    @image = Gosu::Image.new("#{MEDIA_DIR}/player.bmp")

    @score = 0
    @xonii = 2
    @died_on_this_level = false
  end

  def reset_position
    @x_speed = 0
    @y_speed = 0

    @x = 251 # FIELD_WIDTH / 2
    @y = 3
  end

  def draw
    @image.draw(@x - OFFSET, @y - OFFSET, Z_ORDER)
  end

  def update(field_bmp)
    direction
    move(field_bmp)
  end

  def move(field_bmp)
    # check edges before move
    if (@x_speed < 0 && @x - OFFSET <= 1) || (@x_speed > 0 && @x + OFFSET >= FIELD_WIDTH - 3)
      @x_speed = 0
    end

    if (@y_speed < 0 && @y - OFFSET <= 1) || (@y_speed > 0 && @y + OFFSET >= FIELD_HEIGHT - 3)
      @y_speed = 0
    end

    @x += @x_speed
    @y += @y_speed

    (@x - OFFSET .. @x + OFFSET).each do |j|
      (@y - OFFSET .. @y + OFFSET).each do |i|
        begin
          if field_bmp[i] && field_bmp[i][j] == GameDefs::Black
            field_bmp[i][j] = GameDefs::Red
          end
        rescue => e
          puts i
          puts j
          raise e
        end
      end
    end

    # End of red path
    if field_bmp[@y][@x] == GameDefs::Blue && (field_bmp[@y - @y_speed][@x - @x_speed] == GameDefs::Red)
      @x_speed = 0
      @y_speed = 0
      return true
    end

    return nil
  end

  def direction
    if Gosu.button_down? Gosu::KB_LEFT
      @x_speed = -SPEED
      @y_speed = 0
    elsif Gosu.button_down? Gosu::KB_RIGHT
      @x_speed = SPEED
      @y_speed = 0
    elsif Gosu.button_down? Gosu::KB_UP
      @x_speed = 0
      @y_speed = -SPEED
    elsif Gosu.button_down? Gosu::KB_DOWN
      @x_speed = 0
      @y_speed = SPEED
    end
  end

  def update_score(time_remaining, time_limit)
    @score += 500
    @score += GameDefs.bonus(time_remaining, time_limit, @died_on_this_level)
  end

  def interference?(white_dots, black_dots)
    white_dots.each do |w|
      return true if (w.x - @x).abs + (w.y - @y).abs <= COLLISION
    end

    black_dots.each do |b|
      return true if (b.x - @x).abs + (b.y - @y).abs <= COLLISION
    end

    return false
  end

end

class StatusBar
  Z_ORDER = 20
  STRETCH = 0.8

  def initialize
    @font = Gosu::Font.new(15) # font size
    @status_bar_messages = 'Level: %d   Xonii: %d   Filled: %4.1f%%   Score: %d   Time: %1d:%02d'
    @sbm_time_warn       = 'Level: %d   Xonii: %d   Filled: %4.1f%%   Score: %d   <b>Time:%1d:%02d</b>'
  end

  def draw(level, xonii, score, filled, time)
    mins = time/60
    secs = time - mins*60
    if mins == 0 && secs <= 30 && secs.even?
      @font.draw_markup(@sbm_time_warn % [level, xonii, filled, score, mins, secs], 10, FIELD_HEIGHT + 5, Z_ORDER)
    else
      @font.draw_text(@status_bar_messages % [level, xonii, filled, score, mins, secs], 10, FIELD_HEIGHT + 5, Z_ORDER) 
    end
    if Gosu.fps < 59 && FPS_DEBUG
      @font.draw_text("#{Gosu.fps} FPS", 5, 5, 11)
    end
  end

end

class Xonix97 < Gosu::Window
  def initialize
    super WIDTH, HEIGHT
    
    self.caption = "Xonix97"

    @player = Player.new
    @status_bar = StatusBar.new

    @level = 0

    next_level

    @center_message_font = Gosu::Font.new(20)

    @show_score = false
    @skip_update = false
  end
  
  def update
    @skip_update = !@skip_update # 30 FPS emulation

    if !@skip_update && !@show_score
      @skip_update = false

      if @show_ready
        @show_ready = false
        sleep 2
        @level_start_time = Gosu::milliseconds
      end

      if @player.update(@field.field_bmp) # true if done cutting
        @field.flood_fill(@white_dots, @orange_lines)
        @percentage_complete = 100 * @field.blue_count.to_f / TOTAL_SQUARES

        if @percentage_complete > 75.0
          next_level
        end
      end

      @white_dots.each do |w|
        w.update(@field.field_bmp)
      end

      @black_dots.each do |w|
        w.update(@field.field_bmp)
      end

      if @orange_lines
        @orange_lines.each do |l|
          l.update(@field.field_bmp)
        end
      end

      @time_remaining = @time_limit - (Gosu::milliseconds - @level_start_time)/1000

      # Death
      if @player.interference?(@white_dots, @black_dots) || @field.interference?(@white_dots) || @time_remaining <= 0
        sleep 2

        @player.xonii -= 1

        if @player.xonii == 0
          @show_score = true
        else
          @player.died_on_this_level = true
          @player.reset_position
          @field.clean_red

          @time_limit = GameDefs.time_limit(@level, @player.died_on_this_level)

          @show_ready = true
        end
      end

    end

    if @show_score && (Gosu.button_down?(Gosu::KB_ESCAPE) || Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::MS_LEFT))
      exit
    end
  end
  
  def draw
    if @show_score
      @center_message_font.draw_text("Your score is #{@player.score}",
        FIELD_WIDTH/3, FIELD_HEIGHT/2 - 10, 11, 1, 1, Gosu::Color::YELLOW)
    end

    @field.draw
    @player.draw

    @white_dots.each do |w|
      w.draw
    end

    @black_dots.each do |w|
      w.draw
    end

    if @orange_lines
      @orange_lines.each do |l|
        l.draw
      end
    end

    @status_bar.draw(@level, @player.xonii, @player.score, @percentage_complete, @time_remaining)

    if @show_ready
      @center_message_font.draw_text('Ready...', FIELD_WIDTH/3 + 50, FIELD_HEIGHT/2 - 10, 11, 1, 1, Gosu::Color::YELLOW)
    end
  end

  def next_level
    @player.update_score(@time_remaining, @time_limit) if @level > 0
    @player.reset_position

    if @level == 15
      @show_score = true
    end

    @level += 1
    @player.xonii += 1
    @time_limit = GameDefs.time_limit(@level, @player.died_on_this_level)

    @field = Field.new
    counts = GameDefs.object_counts(@level)
    @white_dots   = counts[:white_dots].times.map{ WhiteDot.new }
    @black_dots   = counts[:black_dots].times.map{ BlackDot.new }
    @orange_lines = counts[:orange_lines].times.map{ OrangeLine.new }

    @time_remaining = @time_limit
    @percentage_complete = 18

    @show_ready = true
  end

end

if __FILE__ == $0
  Xonix97.new.show
end

# time_remaining = time_limit # at the beginning of the level
# # if death due to timeout, halve the time limit!
# time_remaining = time_limit /= 2;
# make a test

# Black dot should bounce of red field

# I think time per level is off

# Time blinkis odd

# Colons in status bar are weird

# Time is old during Ready ...


