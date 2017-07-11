# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class VariableTopics < ActiveRecord::Migration

  def up
    
    create_table :topics_variables, :id => false do |t|
      t.column  :variable_id, :bigint, :null => false
      t.column  :topic_id, :bigint, :null => false
    end
    
    add_index :topics_variables, :variable_id
    add_index :topics_variables, :topic_id
    
    foreign_key :topics_variables, :variable_id
    foreign_key :topics_variables, :topic_id
    
  end

  def down
  end
end
