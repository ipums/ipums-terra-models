# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class UpdateRasterSummaryFunctions  < ActiveRecord::Migration


  # implement updates to the raster summary functions to handle binary rasters
  # that have been reformatted to be areal (or 0 in cases where there's no data)
  # To be able to cleanly and concisely handle downmigrations,
  # we rename the old functions in the upmigration
  # and rename them back in the downmigration
  def up

  new_calc_functions = <<-END_OF_PROC
CREATE OR REPLACE FUNCTION terrapop_raster_summary_calc(raster_op_name varchar(32), rast raster, area float) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN CASE raster_op_name
    WHEN 'max' THEN CAST((ST_SummaryStats(rast)).max as double precision)
    WHEN 'min' THEN CAST((ST_SummaryStats(rast)).min as double precision)
    WHEN 'mean' THEN CAST((ST_SummaryStats(rast)).mean as double precision)
    WHEN 'count' THEN CAST((ST_SummaryStats(rast)).count as double precision)
    WHEN 'sum' THEN CAST((ST_SummaryStats(rast)).sum as double precision)
    WHEN 'mode' THEN terrapop_modal_value(rast)
    WHEN 'num_classes' THEN terrapop_num_classes(rast)
    WHEN 'total_area_bin' THEN CAST((ST_SummaryStats(rast)).sum as double precision)
    WHEN 'percent_area_bin' THEN CAST(((ST_SummaryStats(rast)).sum  / area ) as double precision)
    WHEN 'total_area_areal' THEN CAST((ST_SummaryStats(rast)).sum as double precision)
    WHEN 'percent_area_areal' THEN CAST(((ST_SummaryStats(rast)).sum  / area ) as double precision)
    ELSE null
  END;
END;
$$;
END_OF_PROC

    execute new_calc_functions

  end

  def down
  end
end
