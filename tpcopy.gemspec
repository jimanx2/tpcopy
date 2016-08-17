$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "tpcopy/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "tpcopy"
  s.version     = Tpcopy::VERSION
  s.authors     = ["Haziman Hashim"]
  s.email       = ["haziman@abh.my"]
  s.homepage    = "http://www.abh.my/gems/tpcopy"
  s.summary     = "Import HTML templates into your Rails Applications"
  s.description = "This gem let you import your HTML template into layout for your Rails Application. "+
    "Forget about all those hassles of placing the required assets manually";
  s.license     = "MIT"

  s.files = Dir["{app,bin,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.executables << 'tpcopy'
  s.test_files = Dir["test/**/*"]

  s.add_runtime_dependency 'thor', '~> 0.16', '>= 0.1.0'
  s.add_runtime_dependency 'nokogiri', '~> 1.6', '>= 1.6.5'
  s.add_runtime_dependency 'css_parser', '~> 1.3', '>= 1.3.0'
  s.add_runtime_dependency 'rails', '>= 4.2.3'
  s.add_development_dependency 'sqlite3', '~> 1.3', '>= 1.3.10'
end
