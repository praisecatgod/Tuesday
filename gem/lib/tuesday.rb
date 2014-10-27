#!/usr/bin/env ruby

class Tuesday
  #kitchen
  #domain
  #app_type
  #path
  #databases
  @@kitchen_path = "/usr/local/bin/kitchen"
  def self.kitchen_path
    @@kitchen_path
  end
  def self.installs
    if `which nginx` == ""
      puts "You appear to be missing nginx"
      puts "Don't worry I'll install it now"
      `sudo apt-get install nginx`
    end
    #Now get rid of the bad nginx
    puts "Killing the bad nginx"
    puts `rm /etc/nginx/conf.d/defaults`
    puts `rm /etc/nginx/sites-available/*`
    puts `rm /etc/nginx/sites-enabled/*`
    puts `rm /etc/nginx/conf.d/default.conf`

    puts "#{@@menu[:app_type]}"
    #now to do databases
    puts "Time to build up the databases"
    if @@menu[:databases].include? "mongodb"
      if `which mongod` != ""
        puts "You have MongoDB already installed"
      end
    end
    if @@menu[:databases].include? "postgressql"
      if `which psql` != ""
       puts "You have Postgressql already installed"
      end
    end
  end
  def self.readMenu
    begin
      # Exceptions raised by this code will
      # be caught by the following rescue clause
      @@menu = eval("{#{IO.readlines("Menufile").join.strip}}")
    rescue
      puts "It appears you are missing or how corrupt Menufile. Please consult tuesdayrb.me for support"
      abort
    end
    @@menu[:path] = `pwd`
  end
  def self.run
	 puts "Welcome to Ruby-Tuesdays	"
   readMenu
   installs
  end
end

$PROGRAM_NAME = 'Tuesday'
puts $0 # This is an alias for the same thing.

#Setting up the kitchen in localbin
puts `touch  "#{Tuesday.kitchen_path}"`
puts `chmod a+x "#{Tuesday.kitchen_path}"`
