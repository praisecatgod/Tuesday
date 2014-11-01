#!/usr/bin/env ruby
#use system "ls" to give the unix messages for the user
#use `ls` for quick unix messages or want to save it as a string
#don't use exec "ls" as it switches the shell to that new unix process from our ruby one.
#require 'colorize' #This could add some color to the std outputs

#Kitchen is the stashed file in /usr/local/bin that stores all the basic settings like what is the pid and the path
#Menu is the set of settings for an application. The kitchen is composed of menus
#system "yaml"
#system "pg"
#system "mongo"

#To read YAML (.yml) file use the following
require 'yaml'

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
      if `which mongod` != ""
        puts "You have MongoDB already installed"
      else
        puts "You appear to not have Mongodb installed"
      	system "apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10"
      	system 'echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" | tee -a /etc/apt/sources.list.d/10gen.list'
      	system 'apt-get -y update'
      	system 'apt-get -y install mongodb-10gen'
      	puts "Finished installing Mongodb"
      end
      require 'mongo'
      include Mongo
    when "postgressql", "pg", "psql"
      if `which psql` != ""
       puts "You have Postgressql already installed"
     else
       puts "You appear to not have Postgressql installed"
       system "sudo apt-get update"
       system "sudo apt-get install postgresql postgresql-contrib"
       system "sudo apt-get install postgresql-client libpq5 libpq-dev"
       system "sudo -u postgres createuser root -d -s -w"
       system "psql -c \"ALTER USER root WITH PASSWORD 'root'\" -d template1"
       #sudo -u postgres createuser root -d -s -w
       #template1 | postgres
       #PG::Connection.new(nil, 5432, nil, nil, 'template1', nil, nil)
       #Modify nano pg_hba.conf
       # IPv4 local connections:
       # TYPE  DATABASE    USER        CIDR-ADDRESS          METHOD
       #host    all         all         127.0.0.1/5432         trust
       #psql -c "ALTER USER root WITH PASSWORD 'root'" -d template1
       #pg = PG::Connection.new('localhost', 5432, nil, nil, 'template1', 'root', 'root')
       #Maybe we can use this to create the users database and their new role/user
       #sudo -u postgres createdb -O user_name database_name
     end
     require 'pg'
    else
      puts "I don't recognize that database. You will have to install it yourself and make sure your pathing is correct"
    end

    if @@menu[:database]
      if File.directory?("config")
        if File.file?("config/mongo.yml")
          yaml = YAML.load_file("config/mongo.yml")
          #figure out what development wants
          #make sure the database is seen and accessible
          mongo_server = yaml["development"]["sessions"]["default"]["hosts"].first.split(":")
          db = MongoClient.new(mongo_server[0],mongo_server[1]).db(yaml["development"]["sessions"]["default"]["database"])
          #by default use development but if menufile says to use production
        else
          puts "You don't appear to be using config/mong.yml to set up your database"
        end

        if File.file?("config/database.yml")
          yaml = YAML.load_file("config/database.yml")
          puts yaml
          #puts yaml["development"]["sessions"]["default"]["hosts"].first.split(":")
          pg_server = yaml["development"]
          #pg = PG::Connection.new(pg_server["host"], 5432, nil, nil, pg_server["database"], pg_server["username"], pg_server["password"])
          #puts ""
          #PG::Connection.new
          system "sudo -u postgres createuser #{ pg_server["username"]}"
          system "sudo -u postgres createdb -O #{ pg_server["username"]} #{pg_server["database"]}"
          system "sudo -u postgres psql -c \"ALTER USER #{ pg_server["username"]} WITH PASSWORD '#{ pg_server["password"]}'\" -d template1"
          #sudo -u postgres psql -c "ALTER USER user_name WITH PASSWORD 'pass_word'" -d template1
          pg = PG::Connection.new(pg_server["host"], 5432, nil, nil, pg_server["database"], pg_server["username"], pg_server["password"])
          #figure out what development wants
          #make sure the database is seen and accessible
          #by default use development but if menufile says to use production
          #For ActiveRecord
          #system 'rake db:migrate'
          #system 'rake db:seed'
        else
          puts "You don't appear to be using config/database.yml to set up your database"
        end
      else
        puts "You don't appear to be using config folder to set up your databases"
      end
    end

    #Time for web servers
    puts "Now to do Web Servers"
    @@menu[:webserver].downcase! unless @@menu[:webserver].nil? #make sure its not nil first
    @@menu[:webserver] ||= "unicorn"
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
      @@menu = eval("#{IO.readlines("Menufile").join.strip}")
    rescue
      puts "It appears you are missing or have a corrupt Menufile. Please consult http://tuesdayrb.me for support"
    end
    str = `ls`
    @@menu ||= {}
    if str.include? "Gemfile"
      File.open("Gemfile").each_line do |line|
        if line.include? "sinatra"
          @@menu[:app_type] ||= "sinatra"
        elsif line.include? "rails"
          @@menu[:app_type] ||= "rails"
        elsif line.include? "unicorn"
          @@menu[:webserver] ||= "unicorn"
        elsif line.include? "puma"
          @@menu[:webserver] ||= "puma"
        elsif line.include? "pg"
          @@menu[:database] ||= "pg"
        elsif line.include? "mongoid"
          @@menu[:database] ||= "mongodb"
          @@menu[:orm] ||= "mongoid"
        elsif line.include? "mongo-mapper"
          @@menu[:database] ||= "mongodb"
          @@menu[:orm] ||= "mongo-mapper"
        elsif line.include? "activerecord"
          @@menu[:orm] ||= "activerecord"
        elsif line.include? "sinatra-activerecord"
          @@menu[:orm] ||= "activerecord"
        elsif line.include? "data-mapper"
          @@menu[:orm] ||= "data-mapper"
        else
          #nothing
        end
      end
    else
      puts "You don't have a Gemfile installed"
      abort
    end
    @@menu[:domain] ||= "localhost"
    @@menu[:webserver] ||= "unicorn"
    @@menu[:path] = `pwd`.strip
    @@menu[:domain].downcase! if @@menu[:domain]
    @@menu[:webserver].downcase! if @@menu[:webserver]
    @@menu[:database].downcase! if @@menu[:database]
    #updating it for future reference
    File.open("Menufile","w"){|f| f.write("#{@@menu}")}
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
      if @@menu[:app_type] == "rails"
        File.open("#{@@menu[:path]}/config/unicorn.rb", 'w') { |file| file.write("#{make_unicorn app_name, @@menu[:path]}") }
      else
        File.open("#{@@menu[:path]}/unicorn.rb", 'w') { |file| file.write("#{make_unicorn app_name, @@menu[:path]}") }
      end
      system "mkdir #{@@menu[:path]}/pids"
      system "chown nobody:nogroup -R #{@@menu[:path]}/pids"
      system "mkdir #{@@menu[:path]}/logs"
      system "chown nobody:nogroup -R #{@@menu[:path]}/logs"
      if @@menu[:app_type] == "rails"
        system "unicorn_rails -c #{@@menu[:path]}/config/unicorn.rb -D"
      else
        system "unicorn -c #{@@menu[:path]}/unicorn.rb -D"
      end
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


#If the user doesn't supply a Menufile. Assume this is a single application and don't need subdomain support.
#Also, add smart Menufile build. If Menufile doesn't have X it should look for it in the Gem/database.yml file.
#At the end of a nginx/kitchen setup a new Menufile should be pasted into the file
