# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "terrapop_models/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "terrapop_models"
  s.version     = TerrapopModels::VERSION
  s.authors     = ["Ankit Soni", 'Alex Jokela']
  s.email       = ["asoni@umn.edu", 'ajokela@umn.edu']
  s.homepage    = ""
  s.summary     = "All models of Terrapop go here"
  s.description = "Description of TerrapopModels."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE.md", "NOTICE.txt", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

end
