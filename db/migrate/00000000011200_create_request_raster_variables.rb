# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRequestRasterVariables < ActiveRecord::Migration

  def change
  
    create_table :request_raster_variables do |t|
      t.column  :raster_variable_id,    :bigint, :null=>false
      t.column  :extract_request_id,    :bigint, :null=>false
      t.column  :raster_operation_id,   :bigint, :null=>true     # this can be null for raster extracts, but should be populated for area_level extracts
      t.timestamps  
    end # create table

    foreign_key(:request_raster_variables, :raster_variable_id)
    foreign_key(:request_raster_variables, :extract_request_id)
    
    add_index :request_raster_variables, :raster_variable_id
    add_index :request_raster_variables, :extract_request_id
    add_index :request_raster_variables, :raster_operation_id
  
  end # change
  
end
