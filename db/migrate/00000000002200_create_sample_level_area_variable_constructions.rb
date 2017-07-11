# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateSampleLevelAreaVariableConstructions < ActiveRecord::Migration

  def change
    
    create_table :sample_level_area_variable_constructions, :id => false do |t|
      t.column  :sample_level_area_data_variable_id,  :bigint
      t.column  :variable_id,                         :bigint
    end

    foreign_key(:sample_level_area_variable_constructions, :sample_level_area_data_variable_id)
    foreign_key(:sample_level_area_variable_constructions, :variable_id)
  end
end
