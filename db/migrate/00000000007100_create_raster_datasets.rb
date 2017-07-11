# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasterDatasets < ActiveRecord::Migration

  def change
    create_table :raster_datasets do |t|
      t.column    :mnemonic,      :string, :null => false
      t.column	  :label,         :string

      t.column    :resolution_id, :bigint

      t.column	  :source,		    :string

      t.column    :coord_sys,     :string, :default => "lat/long WGS84"

      t.column    :begin_year,    :int
      t.column    :end_year,      :int

      t.column	  :usage_rights,  :text
      t.column	  :description,	  :text
      t.column    :citation,      :text

      t.timestamps
    end

    foreign_key(:raster_datasets, :resolution_id)

  end
end
