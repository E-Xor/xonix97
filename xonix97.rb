#!/usr/bin/env ruby

# Xonix game based on Xonix32 introduced in 1997 for Windows 95.
# The main difference to the DOS Xonix is orange line that paints back the field.
# This also allows red line to selve-intersect. I think it was not allowed originally
# to keep Flood Fill faster.

# brew install sdl2
# gem install gosu

require "gosu"

WIDTH, HEIGHT = 510, 322

module GameDefs
  Blue    = 0
  Black   = 1
  Red     = 2
  Checked = 10
  Border  = 20
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
      @x = GAP + rand(WIDTH - 2 * GAP)
    end

    if y
      @y = y
    else
      @y = GAP + rand(HEIGHT - 2 * GAP)
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
    @image = Gosu::Image.new("media/wdot.png")
    @x_speed = rand(2) + 1
    @y_speed = rand(2) + 1

    super
  end
end

class BlackDot < Dot
  def initialize
    @bounce_pix = GameDefs::Black
    @image = Gosu::Image.new("media/bdot.png")

    @x_speed = 2
    @y_speed = 2

    y = rand(4) + (HEIGHT - GameDefs::Border + 10)
    x = GameDefs::Border + rand(WIDTH - GameDefs::Border)
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
    # Gosu.draw_quad(
    #   @end_one.x, @end_one.y, ORANGE,
    #   @end_one.x, @end_one.y+4, ORANGE,
    #   @end_two.x, @end_two.y, ORANGE,
    #   @end_two.x, @end_two.y+4, ORANGE,
    #   Z_ORDER
    # )

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
 
    deltax = x2 - x1
    deltay = (y2 - y1).abs
    error = deltax / 2
    ystep = y1 < y2 ? 1 : -1

    y = y1
    x1.upto(x2) do |x|
      pixel = steep ? [y,x] : [x,y]
      field_bmp[pixel[1]][pixel[0]] = GameDefs::Black
      field_bmp[pixel[1]+1][pixel[0]] = GameDefs::Black
      field_bmp[pixel[1]][pixel[0]+1] = GameDefs::Black
      field_bmp[pixel[1]-1][pixel[0]] = GameDefs::Black
      field_bmp[pixel[1]][pixel[0]-1] = GameDefs::Black
      error -= deltay
      if error < 0
        y += ystep
        error += deltax
      end
    end

  end

end

class Field
  attr_reader :field_bmp
  Z_ORDER = 2
  AQUA = Gosu::Color.rgba(0, 132, 132, 255)

  def initialize
    @field_bmp = Array.new(HEIGHT) { Array.new(WIDTH) }
    HEIGHT.times do |i|
      WIDTH.times do |j|
        if i < GameDefs::Border - 1 || j < GameDefs::Border - 1 || i >= HEIGHT - GameDefs::Border || j >= WIDTH - GameDefs::Border
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

    draw_pieces(GameDefs::Black, Gosu::Color::BLACK)
    draw_pieces(GameDefs::Red, Gosu::Color::RED)
  end

  def flood_fill(white_dots, orange_lines)

    # replace red with blue
    t0 = Gosu::milliseconds

    HEIGHT.times do |i|
      WIDTH.times do |j|
        @field_bmp[i][j] = GameDefs::Blue if @field_bmp[i][j] == GameDefs::Red
      end
    end

    t1 = Gosu::milliseconds
    puts "t1: #{t1-t0}"

    # for each white dot
    #   unless scanned
    start_point = white_dots + orange_lines.map(&:end_one) + orange_lines.map(&:end_two)
    start_point.each do |d|
      next if @field_bmp[d.y][d.x] == GameDefs::Checked

      queue = [[d.x, d.y]]
      # 5.times do
      while queue.size > 0
        x, y = queue.pop
        # puts "x, y: #{x}, #{y}"
        # puts "@field_bmp[y][x]: #{@field_bmp[y][x]}"
        if @field_bmp[y][x] == GameDefs::Black
          # puts 'past if'
          @field_bmp[y][x] = GameDefs::Checked
          # puts "@field_bmp[y][x]: #{@field_bmp[y][x]}"
          queue << [x + 1, y]
          queue << [x, y + 1]
          queue << [x - 1, y]
          queue << [x, y - 1]
          # puts "queue: #{queue.inspect}"
        end
      end
    end

    t2 = Gosu::milliseconds
    puts "t2: #{t2-t1}"

    # Replace Black with Blue and Checked with Black

    HEIGHT.times do |i|
      WIDTH.times do |j|
        @field_bmp[i][j] = GameDefs::Blue if @field_bmp[i][j] == GameDefs::Black
        @field_bmp[i][j] = GameDefs::Black if @field_bmp[i][j] == GameDefs::Checked
      end
    end

    t3 = Gosu::milliseconds
    puts "t3: #{t3-t2}"

# field at the start
# t1: 13
# t2: 121
# t3: 17

# field at the end
# t1: 13
# t2: 14
# t3: 15

    # checking the source might not be cheaper than checking the dot
    # while pop queue
    #   scan right & left until wall
    #   queue north unles from north & south unless from south
    #   set from south & north
    #   delete scanned from quue
    # Alternative to source tracking is to check if a filed is converted

    # while pop queue
    #   scan right & left until wall
    #   delete scanned from queue
    #   queue north & south
  end

  private

  def draw_pieces(field_bit, filed_color)

    # Maybe faster
    # rmagic_image = Magick::Image.constitute(width_arg, height_arg, map_arg, pixels_arg)
    # Gosu::Image.new(rmagic_image)

    # 4-8 ms
    @field_bmp.each_with_index do |l, i|
      j = 0
      # Add red
      while j < WIDTH
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
  SIZE = 7
  OFFSET = 3
  SPEED = 4
  Z_ORDER = 10

  def initialize
    @x_speed = 0
    @y_speed = 0
    @x = 251 # WIDTH / 2
    @y = 3
    @image = Gosu::Image.new("media/player.bmp")
  end

  def draw
    @image.draw(@x - OFFSET, @y - OFFSET, Z_ORDER)
  end

  def update(field_bmp)
    direction
    move(field_bmp)
  end

  def move(field_bmp)
    # check before move
    # check the speed direction too, allow to move away from the edge
    if (@x_speed < 0 && @x - OFFSET <= 1) || (@x_speed > 0 && @x + OFFSET >= WIDTH - 3)
      @x_speed = 0
    end

    if (@y_speed < 0 && @y - OFFSET <= 1) || (@y_speed > 0 && @y + OFFSET >= HEIGHT - 3)
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
    begin
      if field_bmp[@y][@x] == GameDefs::Blue && (field_bmp[@y - @y_speed][@x - @x_speed] == GameDefs::Red)
        @x_speed = 0
        @y_speed = 0
        return true
      else
        return nil
      end
    rescue => e
      puts @x
      puts @y
      puts @x_speed
      puts @y_speed
      puts @x - @x_speed
      puts @y - @y_speed
      raise e
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

end

class Xonix97 < Gosu::Window
  def initialize
    super WIDTH, HEIGHT
    
    self.caption = "Xonix97"

    @field = Field.new

    @player = Player.new
    @white_dots = 6.times.map{ WhiteDot.new }
    @black_dots = 3.times.map{ BlackDot.new }
    @font = Gosu::Font.new(20)
    @orange_lines = 3.times.map{ OrangeLine.new }
    skip_update = false
  end
  
  def update
    # return
    @skip_update = !@skip_update # 30 FPS emulation

    unless @skip_update
      @skip_update = false

      if @player.update(@field.field_bmp)
        @field.flood_fill(@white_dots, @orange_lines)
      end

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

    # 1 frame = 17ms @60 FPS
    if Gosu.fps < 59
      @font.draw_text("#{Gosu.fps} FPS", 5, 5, 11)
      # puts "#{Gosu.fps} FPS"
    end
  end
end

Xonix97.new.show
