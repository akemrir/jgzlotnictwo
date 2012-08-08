require 'rubygems'
require 'sinatra'
# require 'pry'

# Sinatra defines #set at the top level as a way to set application configuration
set :env, (ENV['RACK_ENV'] ? ENV['RACK_ENV'].to_sym : :development)
set :server, 'thin'
set :views, File.join(File.dirname(__FILE__), 'app','views')
set :root, File.dirname(__FILE__)
set :run, false
set :public_folder, File.dirname(__FILE__) + "/public"
set :statyczne, File.dirname(__FILE__) + "/public/statyczne"
set :sass, :style => :compact

enable :sessions

# binding.pry

require './app.rb'
run Sinatra::Application
