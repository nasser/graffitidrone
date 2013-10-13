require 'nokogiri'
require 'artoo'

connection :ardrone, :adaptor => :ardrone
device :drone, :driver => :ardrone

Point = Struct.new(:x, :y)

filename = ARGV.first || "test.xml"

gml = Nokogiri::XML(File.open('test.xml'))

width = gml.xpath("//screenBounds/x").first.content.to_f
height = gml.xpath("//screenBounds/y").first.content.to_f

last_point = Point.new 0, 0

deltas = gml.xpath("//stroke").map do |stroke|
  stroke.xpath("pt").map do |pt|
    new_point = Point.new pt.xpath("x").first.content.strip.to_f, y:pt.xpath("y").first.content.strip.to_f
    delta = Point.new new_point.x - last_point.x, new_point.y - last_point.y
    last_point = new_point

    delta
  end
end

DRONE_SPEED = 0.2

def fly delta
  puts "fly to #{delta}"
  # trig math to determine constant horizontal and vertical movement
end

def pen_down
  puts "pen down"
  after(0.1.seconds) { drone.forward(DRONE_SPEED) }
  after(0.1.seconds) { drone.hover }
end

def pen_up
  puts "pen up"
  after(0.1.seconds) { drone.backward(DRONE_SPEED) }
  after(0.1.seconds) { drone.hover }
end

work do
  drone.start
  drone.take_off

  deltas.each do |stroke|
    fly stroke.shift
    pen_down
    stroke.each do |point|
      fly point
    end
    pen_up
  end

  after(1.seconds) { drone.stop }
end