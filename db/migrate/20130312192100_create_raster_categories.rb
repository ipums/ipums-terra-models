# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasterCategories < ActiveRecord::Migration

  def change
    
    create_table :raster_categories do |t|
      t.column      :raster_variable_id,  :bigint
      t.column      :code,                :bigint,    :null => false
      t.column      :label,               :text
      t.timestamps
    end
    
    foreign_key :raster_categories, :raster_variable_id
    
  end
end
