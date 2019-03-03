require 'rubygems'
Gem::Specification.new do |s|
    s.name = "DeepDarkFantasy"
    s.version = "0.0.1"
    s.date = "2019-03-03"
    s.summary = "A simple machine learning library written all in ruby"
    s.description = ""
    s.authors = ["sxysxy"]
    s.email = "sxysxygm@gmail.com"
    s.files = ["lib/DeepDarkFantasy.rb"] + Dir.glob("lib/DDF/*.rb")
    s.require_path = "lib"
    s.homepage = "https://github.com/sxysxy/DeepDarkFantasy"
    s.license = 'MIT'
end