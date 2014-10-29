#!/usr/bin/env ruby
#use system "ls" to give the unix messages for the user
#use `ls` for quick unix messages or want to save it as a string
#don't use exec "ls" as it switches the shell to that new unix process from our ruby one.
#require 'colorize' #This could add some color to the std outputs

#Kitchen is the stashed file in /usr/local/bin that stores all the basic settings like what is the pid and the path
#Menu is the set of settings for an application. The kitchen is composed of menus

class Tuesday
  #Menu hash
    #domain
    #app_type
    #path
    #database
    #webserver
    #num_workers
    #worker_timeout
    #nginx_timeout
    #pid
  @@kitchen_path = "/usr/local/bin/kitchen"
  def self.kitchen_path
    @@kitchen_path
  end
  def self.installs
    puts "#{"#"*5}Installation#{"#"*5}"

    #If already installed than bundle/rvm should be working
    #maybe check for a Gemfile
    system "bundle install"

    #check if nginx is installed
    if `which nginx` == ""
      puts "You appear to be missing nginx"
      puts "Don't worry I'll install it now"
      system "sudo apt-get install nginx"
    end
    #Now get rid of the bad nginx
    puts "Killing the bad nginx"
    system "rm /etc/nginx/conf.d/defaults"
    system "rm /etc/nginx/sites-available/*"
    system "rm /etc/nginx/sites-enabled/*"
    system "rm /etc/nginx/conf.d/default.conf"

    #Time for Databases
    puts "Time to build up the databases"
    case @@menu[:database]
    when "mongodb"
      puts "You appear to not have Mongodb installed"
      system "apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10"
      system 'echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" | tee -a /etc/apt/sources.list.d/10gen.list'
      system 'apt-get -y update'
      system 'apt-get -y install mongodb-10gen'
      system 'sudo bash ./mongo_install.bash'
      system 'ps aux | grep mongo'
    when "postgressql", "pg", "psql"
      if `which psql` != ""
       puts "You have Postgressql already installed"
     else
       puts "You appear to not have Postgressql installed"
       system "sudo apt-get update"
       system "sudo apt-get install postgresql postgresql-contrib"
     end
    else
      puts "I don't recognize that database. You will have to install it yourself and make sure your pathing is correct"
    end

    #Time for web servers
    puts "Now to do Web Servers"
    @@menu[:webserver].downcase! unless @@menu[:webserver].nil? #make sure its not nil first
    if @@menu[:webserver] == "puma" || @@menu[:webserver] == "unicorn" || @@menu[:webserver] == "thin" || @@menu[:webserver] == "passanger"
      if `gem list "#{@@menu[:webserver]}"`.include? "("
        puts "#{@@menu[:webserver]} is already installed"
      else
        puts "You don't have #{@@menu[:webserver]}  installed don't worry I got you"
        system "gem install #{@@menu[:webserver]}"
      end
    else
      puts "I'm sorry I don't recognize that web server.....you will have to manually set it up :/ sorry"
    end
  end

  def self.readMenu
    begin
      # Exceptions raised by this code will
      # be caught by the following rescue clause

      @@menu = eval("{#{IO.readlines("Menufile").join.strip}}")
    rescue
      puts "It appears you are missing or have a corrupt Menufile. Please consult http://tuesdayrb.me for support"
      abort
    end
    @@menu[:path] = `pwd`.strip
    @@menu[:domain].downcase!
    @@menu[:webserver].downcase!
    @@menu[:database].downcase!
  end

  def self.make_unicorn(app_name,path)
"working_directory '#{path}'

pid '#{path}/pids/unicorn.pid'

stderr_path '#{path}/logs/unicorn.log'
stdout_path '#{path}/logs/unicorn.log'

listen '/tmp/unicorn.#{app_name}.sock'

# Number of processes
# worker_processes 4
worker_processes 1

# Time-out
timeout 30"
  end

  def self.make_unicorn_for_nginx(app_name,path,domain_name)
"upstream #{app_name} {
  # Path to Unicorn SOCK file, as defined previously
  server unix:/tmp/unicorn.#{app_name}.sock fail_timeout=0;
}
server {
  listen 80;
  # Set the server name, similar to Apache's settings
  server_name localhost #{app_name}.#{domain_name};
  # Application root, as defined previously
  root #{path}/public;
  try_files $uri/index.html $uri @#{app_name};
  location @#{app_name} {
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_redirect off;
      proxy_pass http://#{app_name};
  }
  error_page 500 502 503 504 /500.html;
  client_max_body_size 4G;
  keepalive_timeout 10;
}"
  end

  def self.configure
    #kill the old version of this server
    if @@menu[:webserver] == "puma" || @@menu[:webserver] == "unicorn"
      #kill the old process
      if @@kitchen[@@menu[:path]]
        system "kill #{@@kitchen[@@menu[:path]][:pid]}"
        @@kitchen.delete(@@menu[:path])
      end
    end
    #create the new server
    output = `pwd`
    app_name = output.split("/").last
    app_name.strip!
    puts app_name
    @@menu[:app_name] = app_name
    case @@menu[:webserver]
    when "unicorn"
      File.open("#{@@menu[:path]}/unicorn.rb", 'w') { |file| file.write("#{make_unicorn app_name, @@menu[:path]}") }
      system "mkdir #{@@menu[:path]}/pids"
      system "chown nobody:nogroup -R #{@@menu[:path]}/pids"
      system "mkdir #{@@menu[:path]}/logs"
      system "chown nobody:nogroup -R #{@@menu[:path]}/logs"
      system "unicorn -c #{@@menu[:path]}/unicorn.rb -D"
      #now store the newly created pid
      str = ""
      File.open("#{@@menu[:path]}/pids/unicorn.pid", "r").each_line do |line|
        str += line
      end
      @@menu[:pid] = str.strip
    else
      puts "Something went wrong in the new server creation...."
      abort
    end
    #store it in kitchen
    @@kitchen[@@menu[:path]] = @@menu
    File.open(@@kitchen_path, 'w') { |file| file.write("#{@@kitchen}") }
  end
  def self.restart_servers
    #system "service nginx restart"
    #Readd all the servers to nginx
    str = ""
    @@kitchen.each do |key,value|
      str += make_unicorn_for_nginx(value[:app_name],value[:path],value[:domain])
      str += "\n"
    end
    #str = make_unicorn_for_nginx(@@menu[:app_name],@@menu[:path],@@menu[:domain])
    File.open("/etc/nginx/conf.d/default.conf", 'w') { |file| file.write("#{str}") }
    system "service nginx restart"
  end

  def self.stockKitchen
    puts "Stocking the kitchen"
    str = ""
    File.open(@@kitchen_path).each do |f|
      str += f
    end
    #puts str
    @@kitchen = eval str
    @@kitchen ||= {}
    #puts @@kitchen
  end

  def self.reset
    #load kitchen
    stockKitchen
    #kill all processes
    #and delete the leftover files
    @@kitchen.each do |key,value|
      system "kill #{value[:pid]}"
      system "rm -rf #{value[:path]}/pids"
      system "rm -rf #{value[:path]}/logs"
    end
    #delete the nginx configuration files
    File.open("/etc/nginx/conf.d/default.conf", 'w') { |file| file.write("") }
    #kill nginx
    system "service nginx restart"
    #clean the kitchen
    File.open(@@kitchen_path, 'w') { |file| file.write("") }
  end

  def self.run
	 puts "Welcome to Ruby-Tuesdays.rb"
   puts "Please note, currently Tuesday kills all free roaming daemons before releasing the new ones."
   #Check if it needs to restart
  if ARGV[0] == "reset"
    reset
  else
    #otherwise
    readMenu
    stockKitchen
    installs
    configure
    restart_servers
  end

  end
end

#$PROGRAM_NAME = 'Tuesday'
#puts $0 # This is an alias for the same thing.

#Setting up the kitchen in localbin
`touch  "#{Tuesday.kitchen_path}"`
`chmod a+x "#{Tuesday.kitchen_path}"`

#Tuesday.run
