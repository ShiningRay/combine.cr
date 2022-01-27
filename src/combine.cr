# TODO: Write documentation for `Combine`
module Combine
  VERSION = "0.1.0"

  # TODO: Put your code here
end

require "pixie"

Layers = {} of Int32 => Array(Int32)

Dir.glob(File.join("layers/*.png")).each do |filename|
  name = File.basename(filename, ".png")
  layer, idx = name.split("_")
  layer = layer.to_i
  idx = idx.to_i
  Layers[layer] ||= [] of Int32
  Layers[layer] << idx
end

Queue = Channel(Array(Int32)).new(200)

def combine_all(queue)
  spawn do
    combine(queue, 0, [] of Int32)
    puts "finished"
    queue.send([] of Int32)
  end
  queue
end

def combine(yielder, layer, combination : Array(Int32))
  if layer < Layers.size
    Layers[layer].sort.each do |i|
      combine(yielder, layer + 1, combination + [i])
    end
  else
    yielder.send combination
  end
end

def draw(i, combination)
  output = "output/#{i}.png"
  return if File.exists?(output)

  bg = combination.pop
  m = Pixie::ImageSet.new "layers/#{combination.size}_#{bg}.png"

  (combination.size - 1).downto(0) do |layer|
    filename = "layers/#{layer}_#{combination[layer]}.png"
    img = Pixie::ImageSet.new filename
    m.composite_image(img, :over, false, 0, 0)
  end

  m.write_image output
end

combine_all(Queue)
end_ch = Channel(Nil).new
spawn do
  i = 0

  loop do
    puts i
    combination = Queue.receive
    if combination.size == 0
      puts "ended"
      end_ch.send nil
      break
    else
      puts combination.join(",")
      draw(i, combination)
      i += 1
    end
  end
end

Fiber.yield
end_ch.receive
