require 'rubygems'
require 'bundler'
Bundler.require(:default)

get '/' do
  haml :home
end


get '/docs' do
  haml :tutorial
end

get '/about' do
  haml :about
end
