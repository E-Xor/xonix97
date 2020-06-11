#!/usr/bin/env ruby

# Xonix game based on Xonix32 introduced in 1997 for Windows 95.
# The main difference to the DOS Xonix is orange line that paints back the field.
# This also allows red line to selve-intersect. I think it was not allowed originally
# to keep Flood Fill faster.

# brew install sdl2
# gem install gosu

require "gosu"

# WIDTH, HEIGHT = 520, 390
WIDTH, HEIGHT = 520, 340

module GameDefs
  Blue  = 0
  Black = 1
  Red   = 2
  Border = 18
#define OBJ_OFFSET 3
#define OBJ_SIZE ((2*OBJ_OFFSET)+1)
#define OBJ_MOVE 4
#define BORDER_THICKNESS (OBJ_OFFSET+4*OBJ_MOVE-1)
end

def bresenham_line
end

def scanline_flood_fill
end

class Dot
  attr_reader :x, :y
  OFFSET = 2
  Z_ORDER = 3

  def initialize(x: nil, y: nil)

    Random.new_seed

    if x
      @x = x
    else
      @x = GameDefs::Border + rand(WIDTH - 2 * GameDefs::Border)
    end

    if y
      @y = y
    else
      @y = GameDefs::Border + rand(HEIGHT - 2 * GameDefs::Border)
    end

    @x_speed = rand(2) + 1
    @y_speed = rand(2) + 1
    @x_speed = -@x_speed if rand(2) == 1
    @y_speed = -@y_speed if rand(2) == 1

    # puts "x: #{@x}"
    # puts "y: #{@y}"
    # puts "x_speed: #{@x_speed}"
    # puts "y_speed: #{@y_speed}"
  end

  def bounce(field_bmp)

    if y_border || next_pix_y(field_bmp) == @bounce_pix 
      @y_speed = -@y_speed
      # puts "bounce y, speed: #{@y_speed}"
    end

    if x_border || next_pix_x(field_bmp) == @bounce_pix
      @x_speed = -@x_speed
      # puts "bounce x, speed: #{@x_speed}"
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
    # puts "next_pix_y #{@x}"
    # puts "next_pix_y #{@y + @y_speed}"
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
    # puts "next_pix_y pix: #{pix}"
    pix
  end

  def next_pix_x(field_bmp)
    # puts "next_pix_x #{@x + @x_speed}"
    # puts "next_pix_x #{@y}"
    if @x_speed > 0
      pix = field_bmp[@y][@x + @x_speed + OFFSET]
    else
      pix = field_bmp[@y][@x + @x_speed - OFFSET]
    end

    pix = @bounce_pix unless pix

    # puts "next_pix_x pix: #{pix}"
    pix
  end

  def x_border
    if @x_speed > 0
      @x + @x_speed + OFFSET > WIDTH
    else
      @x + @x_speed - OFFSET < 0
    end
  end

  def y_border
    if @y_speed > 0
      @y + @y_speed + OFFSET > HEIGHT
    else
      @y + @y_speed - OFFSET < 0
    end
  end
end

class WhiteDot < Dot
  def initialize
    @bounce_pix = GameDefs::Blue
    @image = Gosu::Image.new("media/wdot.bmp")

    super
  end
end

class BlackDot < Dot
  def initialize
    @bounce_pix = GameDefs::Black
    @image = Gosu::Image.new("media/bdot.bmp")
    # @x = GameDefs::Border + rand(WIDTH - 2 * GameDefs::Border)
    y = rand(GameDefs::Border) + (HEIGHT - GameDefs::Border)
    super(y: y)
  end
end

class LineDot < Dot
  def initialize
    @bounce_pix = GameDefs::Blue
    @image = Gosu::Image.new("media/bdot.bmp")
    
    super

  end
end

class OrangeLine
  ORANGE = Gosu::Color.rgba(132, 132, 0, 255)
  Z_ORDER = 3

  def initialize
    @end_one = LineDot.new
    @end_two = LineDot.new
  end

  def update(field_bmp)
    @end_one.update(field_bmp)
    @end_two.update(field_bmp)
  end

  def draw
    Gosu.draw_quad(
      @end_one.x, @end_one.y, ORANGE,
      @end_one.x, @end_one.y+4, ORANGE,
      @end_two.x, @end_two.y, ORANGE,
      @end_two.x, @end_two.y+4, ORANGE,
      Z_ORDER
    )
  end
end

class Field
  attr_reader :field_bmp
  Z_ORDER = 2
  # AQUA = Gosu::Color.rgba(17, 128, 127, 255)
  AQUA = Gosu::Color.rgba(0, 132, 132, 255)

  def initialize
    @field_bmp = Array.new(HEIGHT) { Array.new(WIDTH) }
    HEIGHT.times do |i|
      WIDTH.times do |j|
        if i < GameDefs::Border || j < GameDefs::Border || i > HEIGHT - GameDefs::Border || j > WIDTH - GameDefs::Border
          @field_bmp[i][j] = GameDefs::Blue
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
    Gosu.draw_rect(0, 0, WIDTH, HEIGHT, AQUA)

    # 7 FPS
    # @field_bmp.each_with_index do |l, i|
    #   l.each_with_index do |p, j|
    #     if p == GameDefs::Black
    #       Gosu.draw_rect(j, i, 1, 1, Gosu::Color::BLACK)
    #     elsif p == GameDefs::Red
    #       Gosu.draw_rect(j, i, 1, 1, Gosu::Color::RED)
    #     end
    #   end
    # end

    # Max FPS
    @field_bmp.each_with_index do |l, i|
      j = 0
      while j < WIDTH
        if l[j] == GameDefs::Black
          len = 1 
          start = j
          j += 1
          while l[j]  == GameDefs::Black
            len += 1
            j += 1
          end
          Gosu.draw_rect(start, i, len, 1, Gosu::Color::BLACK, Z_ORDER)
        else
          j += 1
        end
      end
    end

    # Can be even faster better
    # rmagic_image = Magick::Image.constitute(width_arg, height_arg, map_arg, pixels_arg)
    # Gosu::Image.new(rmagic_image)
  end

end

class Player
  SIZE = 5
  OFFSET = 2
  SPEED = 2
  Z_ORDER = 10

  def initialize
    @x_speed = 0
    @y_speed = 0
    @x = WIDTH / 2
    @y = 0
    @image = Gosu::Image.new("media/player.bmp")
  end

  def draw
    @image.draw(@x - OFFSET, @y, Z_ORDER)
  end

  def update
    move
    direction
  end

  def move
    @x += @x_speed
    @y += @y_speed
  end

  def direction
    case Gosu.button_down?
    when Gosu::KB_LEFT
      @x_speed = -SPEED
      @y_speed = 0
    when Gosu::KB_RIGHT
      @x_speed = SPEED
      @y_speed = 0
    when Gosu::KB_UP
      @x_speed = 0
      @y_speed = -SPEED
    when Gosu::KB_DOWN
      @x_speed = 0
      @y_speed = SPEED
    end
  end

end

class Xonix97 < Gosu::Window
  def initialize
    super WIDTH, HEIGHT
    
    self.caption = "Xonix97"

    @field = Field.new
    puts @field.field_bmp.count
    puts @field.field_bmp.first.count

    @player = Player.new
    @white_dots = 6.times.map{ WhiteDot.new }
    @black_dots = 3.times.map{ BlackDot.new }
    @font = Gosu::Font.new(20)
    @orange_lines = 3.times.map{ OrangeLine.new }
  end
  
  def update
    @white_dots.each do |w|
      w.update(@field.field_bmp)
    end

    @black_dots.each do |w|
      w.update(@field.field_bmp)
    end

    @orange_lines.each do |l|
      l.update(@field.field_bmp)
    end
  end
  
  def draw
    @field.draw
    @player.draw

    @white_dots.each do |w|
      w.draw
    end

    @black_dots.each do |w|
      w.draw
    end

    @orange_lines.each do |l|
      l.draw
    end

    @font.draw_text("#{Gosu.fps} FPS", 5, 5, 11)
  end
end

Xonix97.new.show
