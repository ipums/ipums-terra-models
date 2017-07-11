# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateTerrapopSamplesTags < ActiveRecord::Migration

  def change
    create_table :terrapop_samples_tags, :id => false do |t|
      t.column      :terrapop_sample_id,    :bigint
      t.column      :tag_id,                :bigint
      t.column      :user_id,               :bigint
      t.column      :visible,               :boolean, :default => true, :null => false      
    end
    
    foreign_key(:terrapop_samples_tags, :terrapop_sample_id)
    foreign_key(:terrapop_samples_tags, :tag_id)
    foreign_key(:terrapop_samples_tags, :user_id)

  end
end
