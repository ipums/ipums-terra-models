# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class Country < ActiveRecord::Base


  has_many :samples
  has_one  :sample_design
  has_many :country_levels
  has_many :maps
  has_many :terrapop_samples
  belongs_to :global_region


  def country_year_and_highest_geography
    all_country_years_and_ranked_geography(true)
  end


  def all_country_years_and_ranked_geography(once = false, scoped = true)
    geog_unit_codes = ['NAT', 'HFLAD', 'HSLAD', 'FLAD', 'SLAD']
    geog_units = GeogUnit.all.map{ |gu| {gu.code => gu} }.reduce Hash.new, :merge
    if scoped
      tps = terrapop_samples.where.not(year: nil).order(year: :desc).to_a
    else
      tps = TerrapopSample.unscoped.load.where(country_id: id).where().not(year: nil).order(year: :desc).to_a
    end
    results = []
    tps.each do |terrapop_sample|
      temp_geog_unit_codes = geog_unit_codes.clone
      year = terrapop_sample.year
      countryyear = short_name.upcase + year.to_s
      until temp_geog_unit_codes.empty?
        geog_unit_code = temp_geog_unit_codes.shift
        geog_unit_code.nil? && next
        map = terrapop_sample.maps.joins("INNER JOIN country_levels cl ON maps.country_level_id = cl.id").where(["cl.geog_unit_id = ?", geog_units[geog_unit_code].id]).first
        map.nil? && next
        sample_geog_level = terrapop_sample.sample_geog_level_for_country_level(map.country_level)
        if !sample_geog_level.nil?
          once && (return {countryyear: countryyear, sample_geog_level: sample_geog_level})
          results << {countryyear: countryyear, sample_geog_level: sample_geog_level}
        end
      end
    end
    results
  end


end
