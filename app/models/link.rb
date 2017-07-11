# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class Link < ActiveRecord::Base


  def self.hash
    @@memo ||= make_hash
  end


  def self.make_hash
    hash = {}
    self.all.each do |link|
      hash[link.name] = link.location
    end
    hash
  end


  def self.clear_cached
    @@memo = nil
  end

end