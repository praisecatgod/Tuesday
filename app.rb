require 'rubygems'
require 'bundler'
Bundler.require(:default)

get '/' do
  haml :home
end

get '/install' do
  haml :install
end

get '/docs' do
  haml :tutorial
end

get '/about' do
  haml :about
end
