require 'nokogiri'

module Tpcopy
  class TemplateParser

    attr_accessor :document, :stylesheets, :javascripts, :images
    def initialize(file)
      @document = Nokogiri::HTML(File.open(file))
      @stylesheets = @document.css('link[rel=stylesheet]')
      @javascripts = @document.css('script[src*=js]')
      @images = @document.css('img[src]')
    end
  end
end
