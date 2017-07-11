# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddYearToTerrapopSample < ActiveRecord::Migration

  def change
    
    add_column  :terrapop_samples, :year, :bigint
    add_index :terrapop_samples, :year
    
  end
end
