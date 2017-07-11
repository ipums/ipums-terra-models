# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AreaDataVariableTopics < ActiveRecord::Migration

  def up
    
    create_table :area_data_variables_topics, :id => false do |t|
      t.column  :area_data_variable_id, :bigint, :null => false
      t.column  :topic_id, :bigint, :null => false
    end
    
    add_index :area_data_variables_topics, :area_data_variable_id
    add_index :area_data_variables_topics, :topic_id
    
    foreign_key :area_data_variables_topics, :area_data_variable_id
    foreign_key :area_data_variables_topics, :topic_id
    
  end

  def down
    
    drop_table :area_data_variables_topics, :id => false
    
  end
end
