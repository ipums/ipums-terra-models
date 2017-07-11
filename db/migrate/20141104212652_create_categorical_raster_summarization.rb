# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateCategoricalRasterSummarization < ActiveRecord::Migration

  def change

    geog_instances = GeogInstance.where({}).limit(10)
    raster_variables = RasterVariable.where({}).limit(1)

    results_sql = <<-RASTER_O_MATIC
SELECT clip.description, (clip.rd).value::integer as int_cat, upper(clip.mnemonic) || '_' || ((clip.rd).value::text) as cat, SUM((clip.rd).count) as numcells
FROM (
  select ST_ValueCount(ST_Clip(r.rast, p.geog::geometry)) as rd, p.description, p.code, rv.mnemonic
  from boundaries p
    INNER JOIN rasters r on ST_Intersects(r.rast, p.geog::geometry)
    INNER JOIN raster_variables rv ON rv.id = r.raster_variable_id
  WHERE p.geog_instance_id IN (#{geog_instances.map{|gi| gi.id}.join(", ")}) AND r.raster_variable_id IN (#{raster_variables.map{|rv| rv.id}.join(", ")})
) clip
WHERE (clip.rd).value IN (select DISTINCT (clip.rd).value::integer as all_LC
      from(
        SELECT ST_ValueCount(r.rast) as rd FROM boundaries p INNER JOIN rasters r on ST_Intersects(r.rast, p.geog::geometry) WHERE p.geog_instance_id IN (#{geog_instances.map{|gi| gi.id}.join(", ")}) AND r.raster_variable_id IN (#{raster_variables.map{|rv| rv.id}.join(", ")})
  ) as lc
ORDER BY all_LC)
GROUP BY clip.description, (clip.rd).value, cat
ORDER BY 1,2
END;
$$;
RASTER_O_MATIC

    category_sql = <<-RASTER_O_MATIC
select DISTINCT upper(clip.mnemonic) || '_' || ((clip.rd).value::text) as cat, (clip.rd).value::integer as int_cat
  from(
    SELECT ST_ValueCount(r.rast) as rd, rv.mnemonic FROM boundaries p
      INNER JOIN rasters r on ST_Intersects(r.rast, p.geog::geometry)
      INNER JOIN raster_variables rv ON rv.id = r.raster_variable_id WHERE p.geog_instance_id IN (#{geog_instances.map{|gi| gi.id}.join(", ")}) AND r.raster_variable_id IN (#{raster_variables.map{|rv| rv.id}.join(", ")})
  ) clip ORDER BY (clip.rd).value::integer
END;
$$;
RASTER_O_MATIC
  
  end
end
