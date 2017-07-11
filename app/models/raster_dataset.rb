# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RasterDataset < ActiveRecord::Base


  has_many :raster_dataset_raster_variables
  has_many :raster_variables, through: :raster_dataset_raster_variables
  has_many :raster_dataset_raster_data_types
  has_many :raster_dataset_raster_dataset_units
  has_many :raster_data_types, through: :raster_dataset_raster_data_types
  has_many :raster_dataset_units, through: :raster_dataset_raster_dataset_units
  has_many :map_unit_raster_datasets
  has_many :map_units, through: :map_unit_raster_datasets
  has_many :raster_timepoints

  belongs_to :raster_dataset_group
  belongs_to :resolution


  def api_attributes
    "TODO"
  end


  def formatted_north_extent
    north_extent.nil? ? 'N/A' : sprintf("%.2f", north_extent)
  end


  def formatted_south_extent
    south_extent.nil? ? 'N/A' : sprintf("%.2f", south_extent)
  end


  def formatted_east_extent
    east_extent.nil?  ? 'N/A' : sprintf("%.2f", east_extent)
  end


  def formatted_west_extent
    west_extent.nil?  ? 'N/A' : sprintf("%.2f", west_extent)
  end


  def map_unit
    map_units.first.nil? ? 'Unknown Units' : map_units.first.unit_long
  end


  def raster_variable_mnemonics
    raster_variables.pluck(:mnemonic)
  end


  def self.long_description(raster_datasets)
    if raster_datasets.count > 0
      datasets = {}
      str = []
      raster_datasets.each do |rd|
        ld = rd.long_description
        datasets[ld[:label]] = [] unless datasets.has_key? ld[:label]
        datasets[ld[:label]] << ld[:years]
      end
      datasets.each{ |label, years| str << label + "\t" + years.join(", ") }
      str.join("\n")
    else
      "No Raster Datasets"
    end
  end


  def long_description
    years = if begin_year == end_year
      begin_year.to_s
    else
      begin_year.to_s + "-" + end_year.to_s
    end
    
    unless raster_dataset_group.nil?
      {label: raster_dataset_group.label, years: years}
    else
      {label: "*** Dataset Group Unavailable ***", years: years}
    end
    
  end

  def self.long_citation(raster_datasets)
    
    if raster_datasets.count > 0
      groups = {}
      str = []
      raster_datasets.each do |rd|
        unless rd.raster_dataset_group.nil?
          unless groups.has_key? rd.raster_dataset_group.label
            desc = rd.raster_dataset_group.description
            
            if desc.nil?
              desc = ""
            end
            
            res_label = rd.resolution.nil? ? "Not available" : rd.resolution.label
                     
            groups[rd.raster_dataset_group.label] = {citation: "#{rd.citation}. Source data downloaded from #{rd.source}.\n" + desc + "\n" + "Resolution: #{res_label}", time_points: {}}
          end
          
          years = if rd.begin_year == rd.end_year
            rd.begin_year.to_s
          else
            rd.begin_year.to_s + "-" + rd.end_year.to_s
          end
          
          years = years.to_s
          
          unless groups[rd.raster_dataset_group.label][:time_points].has_key? years
            groups[rd.raster_dataset_group.label][:time_points][years] = rd.period
          end
          
        end
      end
      
      groups.each do |label,info|
        str << label
        str << info[:citation]
        
        if info[:time_points].count > 1
          s = "Time points:"
        else
          s = "Time point:"
        end
        
        str << s + " " + info[:time_points].keys.join(", ") + "; " + info[:time_points].values.first
        str << ""
        
      end
      
      str.join("\n")
    else
      ""
    end

  end

end
