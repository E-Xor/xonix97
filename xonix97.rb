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

module GameValues
  Blue  = 0
  Black = 1
  Red   = 2
#define OBJ_OFFSET 3
#define OBJ_SIZE ((2*OBJ_OFFSET)+1)
#define OBJ_MOVE 4
#define BORDER_THICKNESS (OBJ_OFFSET+4*OBJ_MOVE-1)
end

def line
end

def scanline_flood_fill
end

class Dot
  def initialize
    @x = rand
    @y = rand
    @x_speed = rand
    @y_speed = rand
  end

  def bounce(field)
    if next_pix_y(field) == @bounce_pix
      Y_SPEED = -@y_speed
    if next_pix_x(field) == @bounce_pix
      X_SPEED = -@x_speed
    end
  end

  private

  def next_pix_y(field)
    field[@x][@y + @y_speed]
  end

  def next_pix_x(field)
    field[@x + @x_speed][@y]
  end
end

class WhiteDot < Dot
  def initialize
    @bounce_pix = GameValues::Blue

    # super # called automatically?
  end
end

class BlackDot < Dot
end

class Line
end

class Field
  BORDER = 18
  Z_ORDER = 2
  # AQUA = Gosu::Color.rgba(17, 128, 127, 255)
  AQUA = Gosu::Color.rgba(0, 132, 132, 255)

  def initialize
    @field_bmp = Array.new(HEIGHT) { Array.new(WIDTH) }
    HEIGHT.times do |i|
      WIDTH.times do |j|
        if i < BORDER || j < BORDER || i > HEIGHT - BORDER || j > WIDTH - BORDER
          @field_bmp[i][j] = GameValues::Blue
        else
          @field_bmp[i][j] = GameValues::Black
        end
      end
    end
  end

  def update
  end

  def draw
    @field_bmp.each_with_index do |l, i|
      l.each_with_index do |p, j|
        if p == GameValues::Blue
          Gosu.draw_rect(j, i, 1, 1, AQUA) 
        elsif p = GameValues::Black
          Gosu.draw_rect(j, i, 1, 1, Gosu::Color::BLACK)
        elsif p == GameValues::Red
          Gosu.draw_rect(j, i, 1, 1, Gosu::Color::RED)
        else
          Gosu.draw_rect(j, i, 1, 1, Gosu::Color::YELLOW) # bug detection
        end
      end
    end
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
    @player = Player.new
  end
  
  def update

  end
  
  def draw
    @field.draw
    @player.draw
  end
end

Xonix97.new.show
