# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateAreaDataRasters < ActiveRecord::Migration

  def change
    
    create_table :area_data_rasters do |t|
      t.column     :sample_geog_level_id,  :bigint,  null: false
      t.column     :raster_variable_id,    :bigint,  null: false
      t.column     :area_data_variable_id, :bigint,  null: false
      t.column     :raster_size,           :bigint,  null: false, default: 1
      t.column     :valid,                 :boolean, null: false, default: true
      t.column     :rast,                  :raster
      t.timestamps
    end
    
    add_index :area_data_rasters, :sample_geog_level_id
    add_index :area_data_rasters, :raster_variable_id
    add_index :area_data_rasters, :area_data_variable_id
    
    add_index :area_data_rasters, [:sample_geog_level_id, :raster_variable_id, :area_data_variable_id, :raster_size], unique: true, name: :area_data_rasters_uniq_index
    
    foreign_key :area_data_rasters, :sample_geog_level_id
    foreign_key :area_data_rasters, :area_data_variable_id
    foreign_key :area_data_rasters, :raster_variable_id
    
    #tiff_o_sql = <<-TIFF_O_MATIC
    #CREATE OR REPLACE Function terrapop_get_area_level_raster_as_tiff(area_data_raster_id bigint)
    #  Returns TABLE (geotiff bytea) as
    #    $BODY$
    #      BEGIN
    #        RETURN
    #          SELECT ST_AsTiff(adr.rast,'LZW',4326) AS rast_bytea FROM area_data_rasters AS adr WHERE id = area_data_raster_id;
    #      END;
    #    $BODY$
    #    LANGUAGE plpgsql;
    #TIFF_O_MATIC
    
    #execute tiff_o_sql
    
  end
end
