# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

# == RasterValue

#    provides a non-ActiveRecord-based class to hold the results of a call
#    to the terrapop_raster_summary() stored proc.
#
# Code based on http://asciicasts.com/episodes/219-active-model
# and http://www.deploymentzone.com/2012/04/09/postgres-table-value-functions-and-rails-3/

class RasterValue
  include ActiveModel::Validations  # these might not be necessary.
  include ActiveModel::Conversion  
  extend ActiveModel::Naming

  attr_reader :sample_geog_level_id, :raster_variable_id, :geog_instance_id, :raster_operation_name
  attr_reader :raster_mnemonic, :boundary_area, :summary_value, :geog_instance

  def initialize(r)
    
    @sample_geog_level_id         = r.sample_geog_level_id
    @raster_variable_id           = r.raster_variable_id
    @raster_operation_name        = r.raster_operation_name
    @geog_instance_id             = r.geog_instance_id
    @internal_geog_instance_label = r.geog_instance_label
    @internal_geog_instance_code  = r.geog_instance_code
    @raster_mnemonic              = r.raster_mnemonic
    @boundary_area                = r.has_area_reference ? r.raster_area : r.boundary_area
    @summary_value                = r.summary_value
    @geog_instance                = r.geog_instance
    @raster_band_idx              = r.band_index
    @raster_dataset               = RasterDataset.find(r.raster_dataset_id)
    
    if @geog_instance.nil?
      raise "Must supply a geog_instance when creating a RasterValue"
    end
  end
  
  def persisted?  
    false
  end

  def value
    @summary_value
  end

  def geog_instance_code
    geog_instance.code
  end

  def geog_instance_label
    geog_instance.label
  end
  
  def geog_instance_id
    geog_instance.id
  end
  
  def construct_synthetic_mnemonic
    #sample_geog_level = SampleGeogLevel.find(sample_geog_level_id)
    #geog_level_name = ""
    
    #unless sample_geog_level.geolink_variable.nil?
    #  geog_level_name = sample_geog_level.geolink_variable.mnemonic
    #else
    #  geog_level_name = sample_geog_level.country_level.country.short_name.upcase + "_" + sample_geog_level.country_level.geog_unit.code
    #end
    
    #"#{@raster_mnemonic}_#{geog_level_name}"
    @raster_mnemonic
  end
  
  def mnemonic
    @raster_mnemonic
  end

  def mnemonic_sym
    @raster_mnemonic.to_sym
  end

  def to_s
    value.nil? ? "<not set>" : @raster_mnemonic + ": #{value}"
  end


end
