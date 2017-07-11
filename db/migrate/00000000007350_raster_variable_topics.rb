# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RasterVariableTopics < ActiveRecord::Migration

  
  def up
    
    create_table :raster_variables_topics, :id => false do |t|
      t.column  :raster_variable_id, :bigint, :null => false
      t.column  :topic_id, :bigint, :null => false
    end
    
    add_index :raster_variables_topics, :raster_variable_id
    add_index :raster_variables_topics, :topic_id
    
    foreign_key :raster_variables_topics, :raster_variable_id
    foreign_key :raster_variables_topics, :topic_id
    
  end

  def down
    drop_table :raster_variables_topics
  end
  
end
