# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

TEST_HELPER = 'test_helper.rb'

PATHS       = ['test', 'test/unit', '../test', '.', '../../test/unit']

path = PATHS.reject { |path| path unless File.exist? File.expand_path(File.join(path, TEST_HELPER)) }.first

path = File.expand_path(File.join(path, TEST_HELPER))
  
if File.exist? path
  require path
else
  raise "Unable to locate #{TEST_HELPER}"
end
