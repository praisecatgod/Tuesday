#To read YAML (.yml) file use the following
require 'yaml'
require 'pg'
require 'mongo'
include Mongo


# connecting to the database
#yaml = YAML.load_file("some_file.yml")
#puts yaml.inspect #should return a hash

#find Gemfile
str = `ls`
menu = {}
#Look for Sinatra or Rails gem
#Look for pg, mongoid/mongo-mapper gems
#look for puma or unicorn gem
if str.include? "Gemfile"
  File.open("Gemfile").each_line do |line|
    if line.include? "sinatra"
      menu[:app_type] = "sinatra"
    elsif line.include? "rails"
      menu[:app_type] = "rails"
    elsif line.include? "unicorn"
      menu[:webserver] = "unicorn"
    elsif line.include? "puma"
      menu[:webserver] = "puma"
    elsif line.include? "pg"
      menu[:database] = "pg"
    elsif line.include? "mongoid"
      menu[:database] = "mongodb"
    elsif line.include? "mongo-mapper"
      menu[:database] = "mongodb"
    else
      #nothing
    end
  end
else
  puts "You don't have a Gemfile installed"
  abort
end
puts menu
File.open("Menufile","w"){|f| f.write("#{menu}")}


#If pg or mongo is found
#next look for a database.yml file.
#save the path to it

if menu[:database]
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
      puts ""
      PG::Connection.new
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

#Use this to make the database
#db = MongoClient.new("localhost", 27017).db("mydb")

#For Mongo Driver

#For PG Driver
#http://deveiate.org/code/pg/


#Bring non-hacker friends to our demodays
#Equalnox gym
#Just come and hangout
#Will feel the vibe of the community
#Someone brought them there (Circular intro)
#Only so far before they come home
