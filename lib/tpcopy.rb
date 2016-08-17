require 'thor'
require 'yaml'
require 'tpcopy/railtie' if defined?(Rails)
require 'tpcopy/template_parser'
require 'fileutils'
require 'css_parser'

module Tpcopy
  include CssParser
  class Tpcopy < Thor
    include Thor::Actions

    class_option :railsroot, :default => '.'
    class_option :verbose, :default => false
    class_option :depth, :default => 4
    argument :source_path
    attr_accessor :template, :tpl_folder, :railsroot

    def self.source_root
      File.expand_path('.')
    end

    desc "import", "Import an HTML file into rails .erb"
    def import
      @template = TemplateParser.new(source_path, options[:depth])
      @tpl_folder = source_path.split('/')[0..-2].last
      @railsroot = Pathname.new(File.expand_path(options[:railsroot]))

      # create required directories
      FileUtils::mkdir_p @railsroot.join('app', 'assets', @tpl_folder)
      FileUtils::mkdir_p @railsroot.join('app', 'assets', 'stylesheets', @tpl_folder)
      FileUtils::mkdir_p @railsroot.join('app', 'assets', 'javascripts', @tpl_folder)
      FileUtils::mkdir_p @railsroot.join('app', 'views', 'layouts', @tpl_folder)

      # start to separate specific css/js
      process_js
      process_css
      process_images
      process_containers

      # write to layout file
      namejs = "#{File.basename(source_path).sub!(/\.(html|htm)/,'')}"
      create_file "#{@railsroot.join('app', 'views', 'layouts', @tpl_folder, namejs)}.html.erb" do
        CGI.unescapeHTML(@template.document.to_html)
      end

      # remove asset filtering
      append_to_file @railsroot.join('config', 'initializers', 'assets.rb') do
        "Rails.application.config.assets.precompile += %w( #{@tpl_folder}/index.js )\nRails.application.config.assets.precompile += %w( #{@tpl_folder}/index.css )\n"
      end

    end

    private
    def preprocess_css(css, abs_folder)
      rgx = /url\([\'\"]?([^\'\"\?\)]+)\??[^\'\"\)]*[\'\"]?\)/
      is_sass = false
      stylesheet = File.open("#{abs_folder}/#{css}", 'rb').read
      if stylesheet.include? 'url('
        stylesheet.gsub!(rgx) do |match|
          begin
            unless match.include? 'http'
              subfile = $1
              copy_file File.expand_path(subfile, "#{abs_folder}/#{File.dirname(css)}"),
                "#{@railsroot.join('app', 'assets', @tpl_folder)}/#{File.dirname(css)}/#{subfile}"
              "asset-url('#{File.dirname(css)}/#{subfile}')"
            else
              match
            end
          rescue Exception => ex
            puts "There was an error while processing #{match} in #{css}: #{ex.message}"
            return false
          end
        end
        is_sass = true
      end
      if is_sass
        puts "Creating SASS file #{css}.scss"
        create_file "#{@railsroot.join('app', 'assets', @tpl_folder)}/#{css}.scss" do
          stylesheet
        end
      end
      return is_sass
    end

    private
    def process_js
      namejs = "#{File.basename(source_path).sub!(/\.(html|htm)/,'')}"
      appjs = @railsroot.join('app', 'assets', 'javascripts', @tpl_folder, "#{namejs}.js")
      buff = ""
      @template.javascripts.each_with_index do |script, i|
        abs_folder = File.expand_path(File.dirname(source_path))
        copy_file "#{abs_folder}/#{script['src']}",
          "#{@railsroot.join('app', 'assets', @tpl_folder)}/#{script['src']}"
        buff << "//= require #{script['src']}\n"
        if i == 0
          script.replace(
            @template.document
              .create_cdata("<%= javascript_include_tag '#{@tpl_folder}/#{namejs}' %>")
          )
        else
          script.remove
        end
      end
      create_file appjs do
        buff
      end
    end

    private
    def process_css
      namecss = "#{File.basename(source_path).sub!(/\.(html|htm)/,'')}"
      appcss = @railsroot.join('app', 'assets', 'stylesheets', @tpl_folder, "#{namecss}.css")
      buff = ""
      buff << "/* \n"
      @template.stylesheets.each_with_index do |link, i|
        next if link['href'].include? 'http'
        abs_folder = File.expand_path(File.dirname(source_path))
        is_sass = preprocess_css "#{link['href']}", abs_folder
        unless is_sass
          copy_file "#{abs_folder}/#{link['href']}",
            "#{@railsroot.join('app', 'assets', @tpl_folder)}/#{link['href']}"
        end
        buff << " *= require #{link['href']}\n"
        if i == 0
          link.replace(
            @template.document
              .create_cdata("<%= stylesheet_link_tag '#{@tpl_folder}/#{namecss}' %>")
          )
        else
          link.remove
        end
      end
      buff << " */"
      create_file appcss do
        buff
      end
    end

    private
    def process_images
      @template.images.each do |image|
        next if image['src'].include? 'http:'
        abs_folder = File.expand_path(File.dirname(source_path))
        copy_file "#{abs_folder}/#{image['src']}",
          "#{@railsroot.join('app', 'assets', @tpl_folder)}/#{image['src']}"
        image['src'] = "<%=asset_path('#{image['src']}')%>"
      end
    end

    private
    def process_containers
      @template.containers.each_key do |key|
        next if @template.containers[key].nil?
        if key == :content
          targetfile = @railsroot.join('app', 'views', @tpl_folder, "#{File.basename(source_path)}.erb")
        else
          targetfile = @railsroot.join('app', 'views', @tpl_folder, 'shared', "_#{key}.html.erb")
        end
        puts "#{key} #{targetfile}"
        create_file targetfile do
          CGI.unescapeHTML(@template.containers[key].to_html)
        end
        @template.containers[key].replace(
          @template.document.create_cdata(
            key == :content ?
              "<%=yield%>" :
              "<%=render('#{@tpl_folder}/shared/#{key}')%>"
          )
        )
      end
    end
  end
end
