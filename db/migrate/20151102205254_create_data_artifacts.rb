# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateDataArtifacts < ActiveRecord::Migration

  def change
    
    create_table :extract_data_artifacts do |t|
      t.column    :extract_request_id, :bigint
      t.text      :data_filename
      t.text      :boundary_filename
      t.text      :data_year
      t.text      :geographic_level
      t.timestamps
    end
    
    add_index :extract_data_artifacts, :extract_request_id
    foreign_key :extract_data_artifacts, :extract_request_id
    
  end
end
