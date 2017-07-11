# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasters < ActiveRecord::Migration

  def change
    
    unless table_exist? :rasters
      
      create_table :rasters do |t|
        t.column      :name,                :string
        t.column      :raster_variable_id,  :bigint
        t.column      :rid,                 :int
        t.column      :rast,                :raster
        t.column      :filename,            :string
        t.timestamps
      end
      
    end
    
    #foreign_key(:rasters, :raster_variable_id)
    
    foreign_key_if_not_exists(:rasters, :raster_variable_id)
    
  end
end
