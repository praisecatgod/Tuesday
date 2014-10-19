require 'sinatra'
require 'haml'

get '/' do
  haml :home
end


get '/docs' do
  haml :tutorial
end

get '/about' do
  haml :about
end
