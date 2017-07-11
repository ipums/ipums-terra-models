# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddTerraScopeRelatedThings < ActiveRecord::Migration

  def change
    sql1 =<<SQL
    WITH national_boundaries as
    (
    select sgl.id, sgl.country_level_id, c.full_name as country_name, c.short_name as iso_code, g.code,
    right(sgl.label,4)::numeric as year, sgl.label
    from sample_geog_levels sgl
    inner join geog_instances gi on (gi.sample_geog_level_id = sgl.id)
    inner join boundaries b on (gi.id = b.geog_instance_id)
    inner join country_levels cl on (cl.id = sgl.country_level_id)
    inner join geog_units g on (g.id = cl.geog_unit_id)
    inner join countries c on (c.id = cl.country_id)
    WHERE g.code = 'NAT'
    order by country_name, year desc
    ), bound_window as
    (
    select iso_code, max(year) over w as year, first_value(id) over w as bound_id
    from national_boundaries 
    window w as (Partition by country_level_id order by country_level_id, year desc)
    ), current_national_boundaries as
    (
    select distinct iso_code, year, bound_id
    from bound_window
    ), country_years as
    (
    select country_level_id, array_agg(year) as sample_years, count(year) as num_years
    from national_boundaries
    group by country_level_id order by 2 
    ), country_geog_levels as
    (
    select c.short_name as iso_code, g.code as geog_level,
    sgl.id as sample_id, right(sgl.label,4)::numeric as year, sgl.label as boundary_label
    from countries c
    inner join country_levels cl on (cl.country_id = c.id)
    inner join geog_units g on (g.id = cl.geog_unit_id)
    inner join sample_geog_levels sgl on (sgl.country_level_id = cl.id)
    order by c.short_name, g.id asc
    ),country_aggs as
    (
    select iso_code, year, array_agg(sample_id) as samples, array_agg(geog_level) as geog_levels
    from country_geog_levels 
    group by iso_code, year
    )
    select sgl.id, sgl.label, cnb.iso_code, b.geog::geometry as geom, sgl.country_level_id, cy.sample_years, 
    cy.num_years, cnb.year as current_year, ca.samples, ca.geog_levels
    from sample_geog_levels sgl inner join geog_instances gi on (sgl.id = gi.sample_geog_level_id)
    inner join boundaries b on (b.geog_instance_id = gi.id)
    inner join current_national_boundaries cnb on (cnb.bound_id = sgl.id)
    inner join country_years cy on (cy.country_level_id = sgl.country_level_id)
    inner join country_aggs ca on (ca.iso_code = cnb.iso_code and ca.year = cnb.year)
    order by sgl.label
SQL

    sql2 = "CREATE SCHEMA IF NOT EXISTS terrascope"

    sql3 = "DROP TABLE IF EXISTS terrascope.geographic_boundaries"

    sql4 =<<SQL
    With boundaries as
    (
    SELECT b.id, sgl.id as sgl_id, gi.id::text as gi_id, gi.label as feat_label, ts.short_label, b.geom
    FROM sample_geog_levels sgl
    inner join geog_instances gi on (sgl.id = gi.sample_geog_level_id )
    inner join boundaries b on (b.geog_instance_id = gi.id)
    inner join terrapop_samples ts on (sgl.terrapop_sample_id =  ts.id)
    )
    SELECT b.id, b.sgl_id, b.gi_id::text as gi_id, b.feat_label, b.short_label, b.geom,
    st_simplifypreservetopology(geom, .01) as geom_1, st_simplifypreservetopology(geom, .05) as geom_2
    into terrascope.geographic_boundaries
    FROM boundaries b
SQL

    sql5 =<<SQL
    CREATE OR REPLACE VIEW terrascope.sgl_view AS 
    SELECT id, sgl_id, gi_id, feat_label, short_label, geom, st_simplifypreservetopology(geom, .01) as geom_1, st_simplifypreservetopology(geom, .05) as geom_2, st_simplifypreservetopology(geom, .1) as geom_3
    FROM terrascope.geographic_boundaries

SQL

    sql6 =<<SQL
    CREATE INDEX ON terrascope.geographic_boundaries USING btree ( sgl_id );
SQL

    execute(sql1)
    execute(sql2)
    execute(sql3)
    execute(sql4)
    execute(sql5)
    execute(sql6)
    
  end
end
