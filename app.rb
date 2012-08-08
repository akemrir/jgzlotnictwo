# encoding: utf-8
# requirement gems# {{{
require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require "sinatra/reloader" if development?
require 'haml'
require 'sass'
require 'json'
require 'pry'
require 'RMagick'
include Magick
# require 'mongoid'
# require 'sinatra/mongoid'
# }}}
module Sinatra# {{{
  module Linkers# {{{
    def menu_pos(url, name = url)
      if request.path_info.include? url
        haml_tag :strong do
          haml_tag :a, "#{name}", :href => "/#{url}"
        end
      else
        haml_tag :a, "#{name}", :href => "/#{url}"
      end
    end
  end# }}}
  module Partials# {{{
    def partial(template, *args)
      template_array = template.to_s.split('/')
      template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
      options = args.last.is_a?(Hash) ? args.pop : {}
      options.merge!(:layout => false)
      locals = options[:locals].nil? ? {} : options[:locals] # SAVE LOCALS
      if collection = options.delete(:collection) then
        collection.inject([]) do |buffer, member|
          buffer << haml(:"#{template}", options.merge(:layout => false, :locals => {template_array[-1].to_sym => member}.merge(locals))) # MERGE THEM BACK TO EACH
        end.join("\n")
      else
        haml(:"#{template}", options)
      end
    end
  end# }}}
  module SessionAuth# {{{

    module Helpers
      def authorized?
        session[:authorized]
      end

      def authorize!
        # redirect '/', unless authorized?
        #app specific
        redirect '/rooms', :error => "Brak prawa do wstępu, WON!" unless authorized?
      end

      def logout!
        session[:authorized] = false
      end
    end

    def self.registered(app)
      app.helpers SessionAuth::Helpers

      app.set :username, 'akemrir'
      app.set :password, 'changeme'

      app.get '/login' do
        "<form method='POST' action='/login'>" +
          "<input type='text' name='user'>" +
          "<input type='password' name='pass'>" +
          "<input name='submit' type='submit' value='wyślij' />" +
          "</form>"
      end

      app.post '/login' do
        if params[:user] == options.username && params[:pass] == options.password
          session[:authorized] = true
          # redirect '/'
          redirect '/', :notice => "Zalogowany" #app specific
        else
          session[:authorized] = false
          # redirect '/login'
          redirect '/login', :error => "Złe dane" #app specific
        end
      end

      #app specific below
      app.get '/logout' do
        logout!
        redirect '/rooms', :notice => "Wylogowany"
      end
    end
  end

  register SessionAuth# }}}

  helpers Linkers
  helpers Partials
end# }}}
class Article# {{{
  def self.all
    file = File.read(File.join("public", "gallery.json"))
    JSON::load(file)
  end


  def self.save_json
    @images = {}
    Dir["public/galeria/*.jpg"].sort.each do |image|
      i = Image.new(image, true)
      @group_name = case i.name[0]
        when "B" then "Bransolety"
        when "I" then "Specjalne"
        when "K" then "Kolczyki"
        when "P" then "Pierścionki"
        when "W" then "Wisiorki"
        end
      @group_name

      @images[@group_name] = { "images" => []
      } unless @images[@group_name]


      @images[@group_name]["images"] << {
        "name" => i.name,
        "mini" => i.minimal_gal,
        "prev" => i.preview_gal
      }
    end
    # binding.pry
    file = File.open(File.join("public", "gallery.json"), "wb")
    file.write(JSON::dump({ :title => "Galeria", :images => @images}))
    file.close
  end

  def self.convert
    @images = []
    Dir["public/galeria/*.jpg"].sort.each do |image|
      i = Image.new(image)
      i.scale_gallery
      @images << i
    end
    @images
  end
end

class Slide
  def self.all
    file = File.read(File.join("public", "slides.json"))
    JSON::load(file)
  end

  def self.save_json
    @images = []
    Dir["public/slajdy/*.jpg"].each do |image|
      i = Image.new(image, true)
      # binding.pry
      @images << { :name => i.name,
                   :mini => i.minimal_slide,
                   :prev => i.preview_slide
      }
    end
    #binding.pry
    file = File.open(File.join("public", "slides.json"), "wb")
    file.write(JSON::dump({ :title => "Slajdy", :images => @images}))
    file.close
  end

  def self.convert
    @images = []
    Dir["public/slajdy/*.jpg"].each do |image|
      i = Image.new(image)
      i.scale
      @images << i
    end
    @images
  end
end

class Image
  include Magick
  attr_reader :name

  def initialize url, json = false
    if json == true
      @url = url.gsub("public", "")
      @name = @url.split("/").last
    else
      @image = Magick::Image.read(url)[0]
      @name = @image.filename.split("/").last
      @url = url.gsub("public", "")
    end
    # binding.pry
  end

  def preview_slide
    File.join("/", "slajdy", "preview", @name).to_s
  end

  def minimal_slide
    File.join("/", "slajdy", "minimal", @name).to_s
  end

  def preview_gal
    File.join("/", "galeria", @name).to_s
  end

  def minimal_gal
    File.join("/", "galeria", "minimal", @name).to_s
  end

  def name
    @name
  end

  def scale
    @name = @image.filename.split("/").last
    @prev = @image.resize_to_fill(960, 370)
    @prev.write(File.join("public", "slajdy", "preview", @name))
    @thumb = @image.resize_to_fill(70, 50)
    @thumb.write(File.join("public", "slajdy", "minimal", @name))
  end

  def scale_gallery
    @name = @image.filename.split("/").last
    @prev = @image.resize_to_fill(130, 130)
    @prev.write(File.join("public", "galeria", "minimal", @name))
  end
end
#}}}

# sinatra app
# home# {{{
get '/' do
  redirect to('/glowna')
end

get '/glowna' do
  # binding.pry
  @slides = Slide.all
  haml :glowna
end

get '/galeria' do
  @gallery = Article.all
  # binding.pry
  haml :galeria
end

get '/dojazd' do
  haml :dojazd
end

get '/prepare_images' do
  Slide.convert
  Slide.save_json
  Article.convert
  Article.save_json
  redirect to('/glowna'), :notice => "Obrazki przekonwertowane"
end
# }}}
# style# {{{
get '/css/style.css' do
  sass :'css/style'#, :style => :expanded
end# }}}
