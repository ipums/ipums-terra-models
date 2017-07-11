# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'nhgis_database'

module Nhgis
  class Dataset < NhgisActiveRecord::Base
    has_many :data_tables
    has_many :data_groups
    has_many :geog_vars
    has_many :agg_data_vars, through: :data_tables
    has_many :breakdown_vars
    has_many :time_series_table_datasets
    has_many :time_series_tables , through: :time_series_table_datasets
    belongs_to :dataset_group


    def terrapop_label
      label_extension = ""                                #assume that a label extension will not be required
      base_label = dataset_group.label                    #start with the dataset group label as the base label

      if base_label.include? "American Community Survey"          #dataset is an American Community Survey dataset - which can cover multiple years
        years = terrapop_years.join("-")                          #expecting two years for ACS datasets e.g. [2008, 2012] => "2008-2012"
        base_label = "#{years} American Community Survey"         #prepend the base label with the years
        label_extension = ": #{label.split("#{years}, ").last.gsub("]", "")}"

      else                                                #dataset is NOT an ACS dataset; assumption - dataset has but one year
        #leave the base_label as it is
        if dataset_group.datasets.size > 1                #provide the label extension when the dataset group has multiple datasets
          if label.include? " - "
            label_extension = ": #{label.split(" - ").first}"
          else
            label_extension = ": #{label}"
          end
        end
      end

      "United States #{base_label} (NHGIS#{label_extension})"
    end


    def terrapop_short_label
      short_label = ""
      base_label = terrapop_label
      if base_label.include? "NHGIS: "
        short_label = base_label.split("NHGIS: ").last.chomp(")")
      end
      if base_label.include? "American Community Survey"
        short_label = "ACS #{short_label}"
      end
      short_label
    end


    def terrapop_years
      #answer an array of years (strings) that define the scope of years for the receiver's data groups data (i.e. datatime, not geotime)
      # e.g. 1790cPop answers [1790]
      # e.g. 2008_2012_ACSa answers [2008, 2012]
      # e.g. 1988_1997_CBP answers [1988, 1989, 1990, 1991, 1992, 1993, 1994, 1995, 1996, 1997]
      years = data_groups.map{|dg|dg.datatime.label}.uniq
      years = years.map{|label| label.split("-")}.flatten.uniq.sort
      raise "years cannot contain a '-'" unless years.select{|string| string.include? "-"}.empty?
      years
    end


    def self.terrapop_datasets
      #answer a list of NHGIS datasets referenced by a TimeSeriesTable that have only nation-, state-, or county-level data
      # Any dataset that is not referenced by a TimeSeriesTable is excluded from the list.
      Nhgis::Dataset
          .joins("JOIN time_series_tables_x_datasets ON time_series_tables_x_datasets.dataset_id = datasets.id")
          .joins("JOIN data_groups ON data_groups.dataset_id = datasets.id AND data_groups.relative_pathname IS NOT NULL")
          .joins("JOIN geotimes ON geotimes.id = data_groups.geotime_id")
          .joins("JOIN geog_levels ON geog_levels.id = geotimes.geog_level_id AND geog_levels.istads_id IN ('nation', 'state', 'county', 'tract')").uniq
    end


  end

end
