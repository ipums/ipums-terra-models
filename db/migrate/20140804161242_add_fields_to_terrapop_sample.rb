# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddFieldsToTerrapopSample < ActiveRecord::Migration

  def change
    add_column    :terrapop_samples, :nhgis_dataset_id, :bigint
    add_column    :terrapop_samples, :begin_year, :integer
    add_column    :terrapop_samples, :end_year,   :integer
  end
end
