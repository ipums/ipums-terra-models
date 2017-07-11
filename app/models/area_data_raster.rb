# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AreaDataRaster < ActiveRecord::Base

  
  #extend ActiveRecord::Sanitization
  
  belongs_to :area_data_variable
  belongs_to :sample_geog_level
  belongs_to :raster_variable

  def self.rasterize(area_data_variable_id, sample_geog_level_id, reference_raster_variable_id)
    adv = sgl = rr = nil
    
    if area_data_variable_id.to_s.is_i?
      adv = AreaDataVariable.where({id: area_data_variable_id}).first
    else
      adv = AreaDataVariable.where({mnemonic: area_data_variable_id}).first
    end
    
    if sample_geog_level_id.to_s.is_i?
      sgl = SampleGeogLevel.where({id: sample_geog_level_id}).first
    else
      sgl = SampleGeogLevel.where({internal_code: sample_geog_level_id}).first
    end
    
    if reference_raster_variable_id.to_s.is_i?
      rr = RasterVariable.where({id: reference_raster_variable_id}).first
    else
      rr = RasterVariable.where({mnemonic: reference_raster_variable_id}).first
    end
    
    if adv.nil? or sgl.nil? or rr.nil?
      if adv.nil?
        $stderr.puts "AreaDataVariable is nil (from: #{area_data_variable_id})"
      end

      if sgl.nil?
        $stderr.puts "SampleGeogLevel is nil (from: #{sample_geog_level_id})"
      end

      if rr.nil?
        $stderr.puts "RasterVariable is nil (from: #{reference_raster_variable_id})"
      end
        
      return false
    end
    
    area_data_values_count = AreaDataValue.joins(:sample_level_area_data_variable).joins("INNER JOIN area_data_variables adv ON adv.id = sample_level_area_data_variables.area_data_variable_id").joins("INNER JOIN sample_geog_levels sgl ON sgl.id = sample_level_area_data_variables.sample_geog_level_id").where({"adv.id" => adv.id, "sgl.id" => sgl.id}).count
    
    if area_data_values_count > 0
    
      adrs = AreaDataRaster.where(["area_data_variable_id = ? AND sample_geog_level_id = ? AND raster_variable_id = ? AND is_valid = TRUE", adv.id, sgl.id, rr.id]).select("id, area_data_variable_id, label, mnemonic, sample_geog_level_id, raster_variable_id, is_valid, raster_size, updated_at, created_at")
    
      if adrs.to_a.count == 0
        index = 1
        raster_size = 1
        right_size = true
        band = 1
        
        sql = "SELECT terrapop_raster_cellcount(?, ?, ?) AS right_size"
      
        while right_size and index < 16
      
          sql0 = AreaDataRaster.send(:sanitize_sql_array, [sql, sgl.id, rr.id, raster_size])
          results = connection.execute(sql0).first
        
          right_size = results['right_size']
        
          if right_size
            raster_size = index
          end
        
          index += 1
        end
      
        if index >= 8 and right_size
          $stderr.puts "Unable to find a decent size for rasterizing area-level data (#{adv.mnemonic}), right_size: #{right_size}"
          return false
        end
        
        if adv.measurement_type.label == "Percentage" or adv.measurement_type.label == "Mean"
          function = "terrapop_areal_rasterization_number"
        else
          function = "terrapop_areal_rasterization"
        end
      
        sql = <<-SQL_O_MATIC
          INSERT INTO area_data_rasters (sample_geog_level_id, raster_variable_id, area_data_variable_id, is_valid, raster_size, label, mnemonic, rast )
            SELECT results.sample_geog_level_id, results.raster_variable_id, results.area_data_variable_id, results.is_valid, results.raster_size, results.label, results.mnemonic, results.rast FROM
              (SELECT ? AS sample_geog_level_id, ? AS raster_variable_id, ? AS area_data_variable_id, TRUE AS is_valid, ? AS raster_size, ? AS label, ? AS mnemonic, (#{function}( ?, ?, ?, ?, ? )).raster AS rast) results
          SQL_O_MATIC

        
        sql = AreaDataRaster.send(:sanitize_sql_array, [sql, sgl.id, rr.id, adv.id, raster_size, "#{sgl.label} - #{adv.mnemonic}", "#{adv.mnemonic}", sgl.id, rr.id, adv.id, raster_size, band])
      
        $stderr.puts "AREADATA->RASTER [#{sql}]"
      
        #begin
        connection.execute(sql)
        #rescue Exception => e
        #  $stderr.puts e.backtrace
        #  return false
        #end
      
        adrs = AreaDataRaster.where(["area_data_variable_id = ? AND sample_geog_level_id = ? AND raster_variable_id = ? AND is_valid = TRUE", adv.id, sgl.id, rr.id]).select("id, area_data_variable_id, label, mnemonic, sample_geog_level_id, raster_variable_id, is_valid, raster_size, updated_at, created_at")
      end

      adrs.to_a
    else
      $stderr.puts "==[ERR]==> No AreaDataValues for AreaDataVariable[#{adv.mnemonic}] at #{sgl.label}"
      []
    end
  end
  
  def tiff_filename
    self.label.gsub(/ +/, '').gsub(/:/, '-').gsub(/,/, '-')
  end
  
  def raster_as_tiff
    
    sql = "SELECT ST_AsTiff(adr.rast,'LZW', ST_SRID(adr.rast)) AS geotiff, label, mnemonic, id, raster_size, sample_geog_level_id, raster_variable_id, area_data_variable_id FROM area_data_rasters AS adr WHERE id = ?"
    sql = AreaDataRaster.send(:sanitize_sql_array, [sql, self.id])
    
    AreaDataRaster.connection.execute(sql).first

  end
  
end
