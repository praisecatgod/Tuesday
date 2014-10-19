#!/usr/bin/env ruby

class Tuesday
  def self.run
    puts "#praisecatgod"
  end
end

kitchen_path = File.join( File.dirname(__FILE__), 'kitchen' )
file = File.open(kitchen_path)

`cp "#{kitchen_path}" /usr/local/bin/kitchen`
`chmod a+x /usr/local/bin/kitchen`
