# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class ChangeTypeOfColumnDataFromExtractDataArtifacts < ActiveRecord::Migration

  def change
    execute "drop index if exists extract_data_artifacts_variables_description"
    change_column :extract_data_artifacts, :variables_description, 'json USING CAST(variables_description as json)', null: false, default: '{}'
  end
end
