# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

# implement updates to the raster summary functions to properly compute num_classes.

# My first implementation was wrong wrong wrong.

class FixRasterSummaryFunctionNumClasses < ActiveRecord::Migration
  def up
    
    execute "DROP FUNCTION IF EXISTS terrapop_num_classes_20130821221743(rast raster, OUT num_classes numeric);"
    
    rename_old_functions = <<-END_OF_PROC
ALTER FUNCTION terrapop_num_classes(rast raster, OUT num_classes numeric)
  RENAME TO terrapop_num_classes_20130821221743;
    END_OF_PROC

    new_calc_functions = <<-END_OF_PROC
CREATE OR REPLACE FUNCTION terrapop_num_classes(rast raster, OUT num_classes numeric) RETURNS numeric
  LANGUAGE plpgsql
  AS $$
BEGIN
  SELECT count(*) into num_classes
    FROM (SELECT (ST_ValueCount(rast,1)).*) As histogram;
  return;
END;
$$;
    END_OF_PROC

    execute rename_old_functions
    execute new_calc_functions
  end

  def down
    restore_old_functions = <<-END_OF_PROC
DROP FUNCTION terrapop_num_classes(rast raster, OUT num_classes numeric);
ALTER FUNCTION terrapop_num_classes_20130821221743(rast raster, OUT num_classes numeric)
  RENAME TO terrapop_num_classes;
    END_OF_PROC

    execute restore_old_functions
  end
end
