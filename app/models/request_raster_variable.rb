# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RequestRasterVariable < ActiveRecord::Base


  belongs_to :extract_request
  belongs_to :raster_variable
  belongs_to :raster_dataset
  belongs_to :raster_operation
  belongs_to :sample_geog_level

  attr_accessor :raster_timepoint

  def mnemonic
    RequestRasterVariable.mnemonic(raster_variable, raster_operation, raster_dataset, sample_geog_level, raster_timepoint)
  end

  def self.mnemonic(raster_variable, raster_operation, raster_dataset, sample_geog_level, timepoint=nil)
    #band = (!raster_dataset.nil? && !raster_dataset.raster_band_index.nil?) ? raster_dataset.raster_band_index : 1
    #band = 1 if band <= 0
    
    geography_name = SampleGeogLevel.geography_name(sample_geog_level)
    
    operation = raster_operation.nil? ? "" : "#{raster_operation.opcode}"
    
    if operation.match(/_netcdf/)
      operation = operation.gsub(/_netcdf/, '')
    end
    
    dataset_mnemonic = raster_dataset.nil? ? "" : "#{raster_dataset.mnemonic}"
    
    mnem = "#{raster_variable.mnemonic}_#{operation}_#{geography_name}_#{dataset_mnemonic}"

    tp = ""
    
    unless timepoint.nil?
      $stderr.puts "RequestRasterVariable: #{mnem} has timepoint => #{timepoint.inspect}"
      tp_parts    = timepoint.timepoint.split(/-/)
      mnem += "_" + tp_parts[0].to_s + tp_parts[1].to_s #tp.to_s.gsub(/\-/, '')
    end
    
    # AreaDataRasterVariableMnemonicLookup(composite_mnemonic: string, mnemonic: string, raster_operation_opcode: string, geog_level: string, dataset_label: string, description: text)
    
    adrvml = AreaDataRasterVariableMnemonicLookup.where(["LOWER(composite_mnemonic) = ?", mnem.downcase]).first
    
    if adrvml.nil? and !raster_dataset.nil?
      
      rd_desc = raster_dataset.long_description
      desc = raster_variable.label + "; " + rd_desc[:years] + "; " + (raster_operation.nil? ? "" : raster_operation.name) + "(" + raster_variable.units + ")" 
      
      unless timepoint.nil?
        desc += " timepoint: " + tp
      end
      
      AreaDataRasterVariableMnemonicLookup.create!(composite_mnemonic: mnem, mnemonic: raster_variable.mnemonic, raster_operation_opcode: operation, geog_level: geography_name, dataset_label: raster_dataset.mnemonic, description: desc, timepoint: tp)
    end
    
    #"#{raster_variable.mnemonic}_#{operation}_#{band}_#{geography_name}"
    
    $stderr.puts "==> RasterVariable mnemonic ==> #{mnem}"
    
    mnem
  end
  
  
  ### Moved to SampleGeogLevel
  #def self.geography_name(sample_geog_level)
  #  if sample_geog_level.nil?
  #    ""
  #  else
  #    if sample_geog_level.geolink_variable.nil?
  #      sample_geog_level.terrapop_sample.short_country_name.upcase + "_" + sample_geog_level.country_level.geog_unit.code.upcase
  #    else
  #      sample_geog_level.geolink_variable.mnemonic
  #    end
  #  end
  #end

  def geography_name
    RequestRasterVariable.geography_name(sample_geog_level)
  end


  def mnemonic_sym
    mnemonic.to_sym
  end


  def is_summary?
    raster_operation.nil?
  end


  # raster_operation might be nil if this is a raster-only extract.
  def operation
    raster_operation.nil? ? "" : "#{raster_operation.opcode}"
  end


  # methods needed for syntax file generation.
  # For Variable, they're in the database.
  # For Area_Data_Variable, they're hardcoded similar to the structure here.
  def filename
    raster_variable.filename
  end


  def long_mnemonic
    raster_variable.long_mnemonic
  end


  def raster_categories
    raster_variable.raster_categories
  end


  def data_type
    "decimal"
  end


  # shouldn't matter for CSV extracts.
  def len
    10
  end


  def implied_decimal_places
    0
  end


  def categories
    []
  end


  def label
    mnemonic
  end


  def to_s
    mnemonic
  end

  def self.long_description(request_raster_variables)
    if request_raster_variables.count > 0
      mnemonics_operations = {}
      str = []
      
      request_raster_variables.each do |rrv|
        unless mnemonics_operations.has_key? rrv.raster_variable.mnemonic
          mnemonics_operations[rrv.raster_variable.mnemonic] = []
        end
        mnemonics_operations[rrv.raster_variable.mnemonic] << (rrv.raster_operation.nil? ? "unknown operation" : rrv.raster_operation.name)
      end
      
      mnemonics_operations.each do |mnemonic,operations|
        m = mnemonic.dup
        str << m.widthize(16) + operations.uniq.join(", ")
      end
      
      str.join("\n")
    else
      "No Raster Operations"
    end
  end

end
