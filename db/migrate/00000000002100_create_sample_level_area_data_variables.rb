# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateSampleLevelAreaDataVariables < ActiveRecord::Migration

  def change
    
    create_table :sample_level_area_data_variables do |t|
      t.column      :area_data_variable_id, :bigint
      t.column      :terrapop_sample_id,    :bigint
      t.column      :sample_geog_level_id,  :bigint
      t.timestamps
    end
    
    foreign_key(:sample_level_area_data_variables, :area_data_variable_id)
    foreign_key(:sample_level_area_data_variables, :terrapop_sample_id)
    foreign_key(:sample_level_area_data_variables, :sample_geog_level_id)

  end
end
