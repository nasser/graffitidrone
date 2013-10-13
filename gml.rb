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
    new_point = Point.new(pt.xpath("x").first.content.strip.to_f, pt.xpath("y").first.content.strip.to_f)
    delta = Point.new(new_point.x - last_point.x, new_point.y - last_point.y)
    last_point = new_point

    delta
  end
end

TAG_SCALE = 2
DRONE_SPEED = 0.5

$timeline = 0
def push_event t, &evt
  $timeline += t
  after($timeline, &evt)
end

def fly delta
  puts "fly #{delta}"

  magnitude = Math.sqrt(delta.x**2 + delta.y**2)

  puts "-- magnitude = #{magnitude}"

  push_event(0.1) do
    if delta.x >= 0
      drone.right (delta.x * DRONE_SPEED)
      puts "-- drone.right (#{delta.x * DRONE_SPEED})"
    else
      drone.left (delta.x.abs * DRONE_SPEED)
      puts "-- drone.left (#{delta.x.abs * DRONE_SPEED})"
    end

    if delta.y >= 0
      drone.up (delta.y * DRONE_SPEED)
      puts "-- drone.up (#{delta.y * DRONE_SPEED})"
    else
      drone.down (delta.y.abs * DRONE_SPEED)
      puts "-- drone.down (#{delta.y.abs * DRONE_SPEED})"
    end
  end

  push_event(magnitude * TAG_SCALE) { drone.hover }
end

def pen_down
  puts "pen down"
  push_event(0.1) { drone.forward(DRONE_SPEED) }
  push_event(0.1) { drone.hover }
end

def pen_up
  puts "pen up"
  push_event(0.1) { drone.backward(DRONE_SPEED) }
  push_event(0.1) { drone.hover }
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

  push_event(1) { drone.stop }
end