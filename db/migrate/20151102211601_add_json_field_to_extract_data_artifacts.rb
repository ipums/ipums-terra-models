# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddJsonFieldToExtractDataArtifacts < ActiveRecord::Migration

  def change
    
    add_column :extract_data_artifacts, :variables_description, :hstore
    execute "CREATE INDEX extract_data_artifacts_variables_description ON extract_data_artifacts USING GIN(variables_description)"
    
  end
end
