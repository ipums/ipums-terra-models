# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class DropUnusedProcedures < ActiveRecord::Migration

  def change
    sql =<<SQL
    DROP FUNCTION IF EXISTS terrapop_tiff_raster_clip(bigint, bigint, integer);
    DROP FUNCTION IF EXISTS terrapop_reclassify_categorical_raster_to_binary_summarization(bigint, bigint, integer);
    DROP FUNCTION IF EXISTS terrapop_reclassify_categorical_raster_to_binary_summariz_v4(bigint, bigint, integer);
    DROP FUNCTION IF EXISTS terrapop_raster_to_image_v2(bigint, bigint, integer);
    -- Could be kept, this is for multicountry select. Might need additional logic
    DROP FUNCTION IF EXISTS terrapop_raster_to_image(bigint[], bigint, integer);
    DROP FUNCTION IF EXISTS terrapop_raster_summary_v4(bigint, bigint, bigint, bigint, character varying);
    DROP FUNCTION IF EXISTS terrapop_raster_summary_v3(bigint, bigint, bigint, character varying);
    DROP FUNCTION IF EXISTS terrapop_raster_summary_calc_v2(character varying, raster, double precision);
    DROP FUNCTION IF EXISTS terrapop_raster_summary_calc(character varying, raster, double precision);
    -- The O.G. Maybe you should keep it!
    DROP FUNCTION IF EXISTS terrapop_raster_summary(bigint, bigint, character varying);
    DROP FUNCTION IF EXISTS terrapop_raster_clip(bigint, bigint, integer);
    DROP FUNCTION IF EXISTS terrapop_raster_cellcount(bigint, bigint, bigint);
    DROP FUNCTION IF EXISTS terrapop_raster_as_tiff(integer, raster);
    DROP FUNCTION IF EXISTS terrapop_raster_area_v1(bigint, bigint);
    DROP FUNCTION IF EXISTS terrapop_raster_area_v1(bigint, bigint);
    DROP FUNCTION IF EXISTS terrapop_num_classes_v2(raster);
    DROP FUNCTION IF EXISTS terrapop_num_classes_20130821221743(raster);
    DROP FUNCTION IF EXISTS terrapop_num_classes(raster);
    DROP FUNCTION IF EXISTS terrapop_modis_categorical_binary_summarization_v09282016(bigint, bigint, bigint);
    DROP FUNCTION IF EXISTS terrapop_modis_categorical_binary_summarization(bigint, bigint, bigint);
    DROP FUNCTION IF EXISTS terrapop_modal_value_v2(raster);
    DROP FUNCTION IF EXISTS terrapop_modal_value(raster);
    DROP FUNCTION IF EXISTS terrapop_jpeg_raster_clip(bigint, bigint, integer);
    DROP FUNCTION IF EXISTS terrapop_gli_yield_areal_summarization_v2(bigint, bigint);
    DROP FUNCTION IF EXISTS terrapop_gli_harvest_areal_summarization_v6(bigint, bigint);
    DROP FUNCTION IF EXISTS terrapop_glc_binary_summarization_v7(bigint, bigint);
    DROP FUNCTION IF EXISTS terrapop_continuous_summarization_without_arearef(bigint, bigint, bigint);
    DROP FUNCTION IF EXISTS terrapop_continuous_summarization1(bigint, bigint);
    DROP FUNCTION IF EXISTS terrapop_continuous_summarization0(bigint, bigint);
    DROP FUNCTION IF EXISTS terrapop_continuous_summarization(bigint, bigint);
    DROP FUNCTION IF EXISTS terrapop_categorical_to_binary_as_tiff(bigint, bigint, integer);
    DROP FUNCTION IF EXISTS terrapop_categorical_raster_v1(bigint, bigint, integer);
    DROP FUNCTION IF EXISTS terrapop_categorical_raster_v0(bigint, bigint);
    DROP FUNCTION IF EXISTS terrapop_areal_rasterization_number(bigint, bigint, bigint, bigint, integer);
    DROP FUNCTION IF EXISTS terrapop_areal_rasterization(bigint, bigint, bigint, bigint, integer);
    DROP FUNCTION IF EXISTS terrapop_wrap_global_raster_v1(bigint, bigint, integer);    
SQL

    execute(sql)

  end
end
