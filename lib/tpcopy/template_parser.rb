require 'nokogiri'

module Tpcopy
  class TemplateParser

    attr_accessor :document, :stylesheets, :javascripts, :images

    # for template
    attr_accessor :containers, :depth

    def initialize(file, depth)
      @depth = depth
      @document = Nokogiri::HTML(File.open(file))
      @stylesheets = @document.css('link[rel=stylesheet]')
      @javascripts = @document.css('script[src*=js]')
      @images = @document.css('img[src]')
      @containers = {
        header: nil,
        content: nil,
        slider: nil,
        sidebar: nil,
        footer: nil
      }
      define_containers
    end

    private
    def define_containers
      curdepth = 0
      puts <<-SCREEN
+---------------------------------+
|   Template Processing Wizard    |
+---------------------------------+
Traverse depth: #{@depth} level
Elements within traverse depth:
SCREEN
      elements = traverse(@document.css('body').first, curdepth)
      print "[0] <none>\n"
      elements.each_with_index do |elem, i|
        print "[#{i+1}]#{elem[:text]}\n"
      end

      @containers.each_key do |key|
        num = -1
        print "Which is the #{key}? [1-#{elements.length}] "
        loop do
          num = STDIN.gets.chomp
          if num == ''
            puts 'Bailing out!'
            exit
          end
          num = num.to_i
          unless num.is_a?(Integer) && num >= 0
            print "I need an Integer! [1-#{elements.length}] "
          else
            break
          end
        end
        if num > 0
          @containers[key] = elements[num-1][:elem]
        end
      end
    end

    private
    def traverse(element, depth)
      out = []
      if depth < @depth
        return out if element.node_name.nil?
        unless element.node_name.match(/body|text|script|comment/)
          out.push({
            :text =>
            ("\t"*depth) +
            "#{element.node_name}" +
            (element['id'] ? "##{element['id']}" : "") +
            (element['class'] ? ".#{element['class']}" : ""),
            :elem => element
          })
        end
        element.children.each do |child|
          out += traverse(child, depth + 1)
        end
      end
      return out
    end
  end
end
