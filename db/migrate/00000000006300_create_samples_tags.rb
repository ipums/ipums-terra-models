# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateSamplesTags < ActiveRecord::Migration

  def change
    create_table :samples_tags, :id => false do |t|
      t.column      :sample_id,   :bigint
      t.column      :tag_id,      :bigint
      t.column      :user_id,     :bigint
      t.column      :visible,     :boolean, :default => true, :null => false
    end
    
    foreign_key(:samples_tags, :sample_id)
    foreign_key(:samples_tags, :tag_id)
    foreign_key(:samples_tags, :user_id)
 
  end
end
