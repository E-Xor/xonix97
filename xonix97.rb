#!/usr/bin/env ruby

# Made based on Xonix32 introduced in 1997 for Windows 95.
# The main difference to the DOS Xonix is orange line that paints back the field.
# This also allows red line to selve-intersect. I think it was not allowed originally
# to keep Flood Fill faster.

# brew install sdl2
# gem install gosu

require "gosu"

# WIDTH, HEIGHT = 640, 480
WIDTH, HEIGHT = 520, 390

module Tiles
  Blue  = 0
  Black = 1
  Red   = 2
end

def bresenham_line
end

def scanline_flood_fill
end

class Dot
end

class WhiteDot < Dot
end

class BlackDot < Dot
end

class Line
end

class Field
  BORDER = 20
  def initialize
    @field_bmp = Array.new(HEIGHT) { Array.new(WIDTH) }
    HEIGHT.times do |i|
      WIDTH.times do |j|
        if i < BORDER || j < BORDER || i > HEIGHT-20 || j > WIDTH-20
          @field_bmp[i][j] = Tile::Blue
        else
          @field_bmp[i][j] = Tile::Black
        end
      end
    end
  end

  def update
  end

  def draw
    @field_bmp.each_with_index do |l, i|
      l.each_with_index do |p, j|
        if p == Tile::Blue
          Gosu.draw_rect(i, j, 1, 1, Gosu::AQUA)
        elsif p = Tile::Black
          Gosu.draw_rect(i, j, 1, 1, Gosu::BLACK)
        elsif p == Tile::Red
          Gosu.draw_rect(i, j, 1, 1, Gosu::RED)
        else
          Gosu.draw_rect(i, j, 1, 1, Gosu::YELLOW) # bug detection
        end
      end
    end
  end
end

class Player
  SIZE = 5
  SPEED = 2

  def initialise
    @x_speed = 0
    @y_speed = 0
    @x = WIDTH / 2
    @y = 0
  end

  def draw
    Gosu.draw_rect(@x, @y, 5, 5, Gosu::WHITE)
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
  end
  
  def update

  end
  
  def draw
    @field.draw
  end
end

Xonix97.new.show
