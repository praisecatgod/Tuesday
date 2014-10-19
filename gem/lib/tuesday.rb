#!/usr/bin/env ruby

class Tuesday
  def self.run
    puts ARGV[0]

    if ARGV[0].downcase == "reset"
      kitchen_path = File.join( File.dirname(__FILE__), 'kitchen' )
      kitchen_str = ""
      File.foreach(kitchen_path){|line| kitchen_str += line}
      kitchen = eval(kitchen_str.strip)
      puts "Preparing the food"
      if kitchen.nil?
        kitchen = {}
      end

      kitchen.each do |key,value|
        if value[:rails_app]
          puts `rm "#{value[:pwd]}"/config/unicorn.rb`
        else
          puts `rm "#{value[:pwd]}"/unicorn.rb`
        end
        str = "#{value[:pwd]}/pids/unicorn.pid"
        puts str
        unicorn_id = IO.readlines(str).join.strip
        puts `kill "#{unicorn_id}"`
      end

      File.write(kitchen_path, "")
      File.write("/etc/nginx/conf.d/default.conf","")
    else
      #puts "#praisecatgod"
      settings = {}

      rails_app = false

      begin
        # Exceptions raised by this code will
        # be caught by the following rescue clause
        settings = eval "{#{IO.readlines('Menufile').join.strip}}"
      rescue
        puts "You don't have a Menufile. Please consult http://tuesdayrb.me for support.
        Thank you please come again."
        abort
      end

      begin
        #check if file is a rails app
        if File.read("config.ru").match("Rails")
          rails_app = true
        end
      rescue
        puts "You don't have a config.ru. Please consult http://tuesdayrb.me for support.
        Thank you please come again."
        abort
      end

      output = `bundle install --without production`
      puts output

      output = `gem list`
      #puts output
      unicorn_output = output.match(/unicorn (.*)\n/)
      if unicorn_output.nil?
        puts "I'm sorry...you appear to be missing Unicorn. Don't worry I got you ;)"
        puts `gem install unicorn`
      else
        puts "reservation made for mr. unicorn"
      end
      output = `pwd`
      app_name = output.split("/").last
      app_name.strip!
      puts "I see you would like the #{app_name}. Very fine choice"

      base_unicorn = "
      working_directory '/var/www/#{app_name}'

      pid '/var/www/#{app_name}/pids/unicorn.pid'

      stderr_path '/var/www/#{app_name}/logs/unicorn.log'
      stdout_path '/var/www/#{app_name}/logs/unicorn.log'

      listen '/tmp/unicorn.#{app_name}.sock'

      # Number of processes
      # worker_processes 4
      worker_processes 1

      # Time-out
      timeout 30

      "
      puts `rm unicorn.rb`
      if rails_app
        puts `echo "#{base_unicorn}" >> config/unicorn.rb`
      else
        puts `echo "#{base_unicorn}" >> unicorn.rb`
      end

      puts `mkdir logs pids`

      nginx = `which nginx`
      if nginx == ""
        #install nginx
        if `uname`.strip == "Darwin"
          puts `brew install nginx`
        else
          puts `apt-get install nginx`
        end
      end

      #kill the bad nginx
      puts "Killing the bad nginx"
      puts `rm /etc/nginx/conf.d/defaults`
      puts `rm /etc/nginx/sites-available/*`
      puts `rm /etc/nginx/sites-enabled/*`
      puts `rm /etc/nginx/conf.d/default.conf`

      #add app to kitchen
      puts "Stocking up the kitchen"

      kitchen_path = File.join( File.dirname(__FILE__), 'kitchen' )
      kitchen_str = ""
      File.foreach(kitchen_path){|line| kitchen_str += line}
      kitchen = eval(kitchen_str.strip)
      puts "#{settings}"
      puts "Preparing the food"
      if kitchen.nil?
        kitchen = {}
      end


      new_nginx = ""

      #kill old unicorns
      puts "Grinding up the unicorns"
      kitchen.each do |key,value|
        str = "#{value[:pwd]}/pids/unicorn.pid"
        puts str
        unicorn_id = IO.readlines(str).join.strip
        puts `kill "#{unicorn_id}"`
      end

      #run new unicorns

      puts "Making your order"

      if kitchen["#{app_name}".to_sym]
        kitchen.delete("#{app_name}".to_sym)
      end

      kitchen["#{app_name}".to_sym] = {pwd: "#{`pwd`}".strip, rails_app: "#{rails_app}"}

      puts "Making the patties"
      kitchen.each do |key,value|
          if value[:rails_app]
            puts `unicorn_rails -c "#{value[:pwd]}"/config/unicorn.rb -D`
          else
            puts `unicorn -c "#{value[:pwd]}"/unicorn.rb -D`
          end
          value[:pid] = IO.readlines("#{value[:pwd]}/pids/unicorn.pid").join.strip
          app_name = key
          domain_name = settings[:domain]
          #new_nginx += gen_nginx(key,settings[:domain])
          new_nginx += "

          upstream #{app_name} {
              # Path to Unicorn SOCK file, as defined previously
              server unix:/tmp/unicorn.#{app_name}.sock fail_timeout=0;
          }

          server {


              listen 80;

              # Set the server name, similar to Apache's settings
              server_name localhost #{app_name}.#{domain_name};

              # Application root, as defined previously
              root /var/www/#{app_name}/public;

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

          }

          "
      end

      File.write(kitchen_path, "#{kitchen}")
      File.write("/etc/nginx/conf.d/default.conf",new_nginx)

      #restart nginx
      puts `service nginx restart`
    end
  end
end

kitchen_path = File.join( File.dirname(__FILE__), 'kitchen' )
file = File.open(kitchen_path)

`cp "#{kitchen_path}" /usr/local/bin/kitchen`
`chmod a+x /usr/local/bin/kitchen`
