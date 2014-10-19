#!/usr/bin/ruby
# encoding: utf-8

require 'bundler/setup'
require 'eventmachine'

# 0C | RPM                        | 2 | rpm  | ((A*256)+B)/4
# 05 | Engine coolant temperature | 1 |      | A-40
# 0D | Vehicle speed              | 1 | km/h | A
# 0A | Fuel Pressure              | 1 | kPA  | A*3
# 11 | Throttle position          | 1 | %    | A*100/255
# 2F | Fuel Level Input           | 1 | %    | A*100/255

class RandomStrategy
  def get(field)
    rand(field[:min]..field[:max])
  end
end

FIELDS = {
  '0105' => { :name  => 'Engine coolant temperature',
            :min   => -40,
            :max   => 215,
            :bytes => 1,
            :calc  => lambda { |a| a+40 },
            :unit  => '°C',
            :strategy => RandomStrategy.new,
            :prepend => '7E8 04 41 0C'
          },
  '0107' => { :name  => 'Long term fuel % ',
            :min   => -100,
            :max   => 100,
            :bytes => 1,
            :calc  => lambda { |a| (a.to_f/100*128) + 128 },
            :unit  => '%',
            :strategy => RandomStrategy.new,
            :prepend => '7E8 04 41 0C'
          },
  '010A' => { :name  => 'Fuel Pressure',
            :min   => 0,
            :max   => 765,
            :bytes => 1,
            :calc  => lambda { |a| a.to_f/3 },
            :unit  => 'kPa',
            :strategy => RandomStrategy.new,
            :prepend => '7E8 04 41 0C'
          },
  '010C' => { :name  => 'Engine RPM',
            :min   => 0.0,
            :max   => 16383.75,
            :bytes => 2,
            :calc  => lambda { |a| a*4 },
            :unit  => 'rpm',
            :strategy => RandomStrategy.new,
            :prepend => '7E8 04 41 0C'
          },
  '010D' => { :name  => 'Vehicle Speed',
            :min   => 0,
            :max   => 255,
            :bytes => 1,
            :calc  => lambda { |a| a },
            :unit  => 'km/h',
            :strategy => RandomStrategy.new,
            :prepend => '7E8 04 41 0C'
          },
  '0111' => { :name  => 'Throttle position',
            :min   => 0,
            :max   => 100,
            :bytes => 1,
            :calc  => lambda { |a| a.to_f/100*255 },
            :unit  => '%',
            :strategy => RandomStrategy.new,
            :prepend => '7E8 04 41 0C'
          },
  '012F' => { :name => 'Fuel Level Input',
            :min  => 0,
            :max  => 100,
            :bytes => 1,
            :calc => lambda { |a| a.to_f/100*255 },
            :unit  => '%',
            :strategy => RandomStrategy.new,
            :prepend => '7E8 04 41 0C'
          }
}

class OBD < EventMachine::Connection
  def post_init
    puts "< Got connection"
  end

  def unbind
    puts "| Lost connection"
  end

  def receive_data(data)
    key = data.chomp.upcase
    puts "< #{key}"
    if(FIELDS.has_key?(key))
      field = FIELDS[key]
      value = field[:strategy].get(field)
      converted = to_hex(field[:calc].call(value).to_i, field[:bytes])
      puts "Sending #{field[:name]}: #{value} #{field[:unit]} -> #{converted}"
      send_data("#{key}\n")
      send_data("#{field[:prepend]} #{converted}\n")
    end
  end


  def to_hex(value, bytes)
    ("%0#{bytes*2}X" % value).gsub(/^(..)(..)$/, '\1 \2')
  end
end

EventMachine.run {
  EventMachine::start_server '0.0.0.0', 35000, OBD
  puts "Running at localhost"
}
