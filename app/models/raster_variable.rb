# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RasterVariable < ActiveRecord::Base


  has_one :raster_metadata, dependent: :destroy

  has_many :raster_variable_group_memberships
  has_many :raster_groups, through: :raster_variable_group_memberships
  has_many :raster_dataset_raster_variables
  has_many :raster_datasets, through: :raster_dataset_raster_variables
  has_many :area_data_rasters
  has_many :raster_categories
  has_many :raster_statistics
  has_many :raster_category_statistics
  has_many :assoc_raster_variables, class_name: "RasterVariable", foreign_key: "area_reference_id"
  has_many :second_assoc_raster_variables, class_name: "RasterVariable", foreign_key: "second_area_reference_id"
  has_many :raster_variable_classifications
  has_many :mosaic_raster_variables, through: :raster_variable_classifications
  has_many :classification_raster_variables, class_name: "RasterVariable", through: :raster_variable_classifications
  has_many :raster_variable_raster_bands
  has_many :raster_bands, through: :raster_variable_raster_bands

  has_and_belongs_to_many :topics

  belongs_to :raster_data_type
  belongs_to :raster_group
  belongs_to :area_reference, class_name: "RasterVariable", foreign_key: "area_reference_id"
  belongs_to :second_area_reference, class_name: "RasterVariable", foreign_key: "second_area_reference_id"

  PROJECTION_WGS84 = 4326

  def api_attributes
    "TODO"
  end


  def availability_by_country
    _availability_by_country = {}
    TerrapopSample.select('DISTINCT countries.full_name', :year).joins(:country).where.not(year: nil).order('countries.full_name', :year).each do |terrapop_sample|
      _availability_by_country[terrapop_sample.full_name] ||= []
      _availability_by_country[terrapop_sample.full_name] << terrapop_sample.year
    end
    _availability_by_country
  end


  def table_type
    self.class.to_s
  end


  def child_count
    1
  end


  def in_cart_count(mnemonics)
    0
  end


  def raster_datasets_count
    raster_datasets.count
  end


  def _raster_dataset_id_
    raster_datasets.count > 0 ? raster_datasets.first.id : nil
  end


  def _raster_dataset_ids
    raster_dataset_ids
  end


  def raster_dataset_mnemonics
    raster_datasets.pluck(:mnemonic)
  end


  def raster_group_mnemonic
    raster_groups.pluck(:mnemonic).first
  end

  def raster_band(year=nil)
    
    if mnemonic.match(/CRUTS_/)
      1
    elsif mnemonic.match(/IGBP/)
      
      y_p = year.to_s.split("-")
      
      rds = self.raster_datasets.where(mnemonic: "IGBP_#{y_p[0]}").first
      
      unless rds.nil?
        tp = rds.raster_timepoints.where(timepoint: y_p[0]).first
        
        unless tp.nil?
          tp.band
        else
          raise "No RasterTimepoint for #{y_p[0]}"
        end
      else
        raise "No RasterDataset for mnemonic: IGBP_#{year}"
      end
      
    else
      1
    end
    #if mnemonic.match(/CRUTS_/).nil? # NOT CRUTS! #mnemonic.match(/IGBP_/) and mnemonic.match(/CRUTS_/).nil?
    #  self.raster_bands.count >= 1 && self.raster_bands.count < 12 ? self.raster_bands.first.band_num : self.raster_datasets.where(mnemonic: "IGBP_#{year}").first.raster_timepoints.where(timepoint: year).first.band
    #else
    #  1
    #end
  end

  def is_cruts
    mnemonic.match(/CRUTS_/).nil? ? false : true
  end

  def build_raster_value_from_row(r) #, geog_instance)
    raise "Cannot build raster values without geog_instance, but it is nil." if r.geog_instance.nil?
    #result = RasterValue.new(r['sample_geog_level_id'],
    #  r['raster_variable_id'], r['raster_operation_name'],
    #  r['geog_instance_id'], r['geog_instance_label'], r['geog_instance_code'],
    #  r['raster_mnemonic'], r['raster_area'],
    #  r['summary_value'], geog_instance)
    #trsc.sample_geog_level_id   = r['sample_geog_level_id'].to_i
    #trsc.raster_variable_id     = r['raster_variable_id'].to_i
    #trsc.raster_operation_name  = r['raster_operation_name']
    #trsc.geog_instance_id       = r['geog_instance_id'].to_i
    #trsc.geog_instance_label    = r['geog_instance_label']
    #trsc.geog_instance_code     = r['geog_instance_code'].to_f
    #trsc.raster_mnemonic        = r['raster_mnemonic']
    #trsc.boundary_area          = r['boundary_area'].to_f
    #trsc.raster_area            = r['raster_area'].to_f
    #trsc.summary_value          = r['summary_value'].to_f
    #trsc.has_area_reference     = has_area_reference
    result = RasterValue.new(r)
  end


  def setup_raster_metadata(xml)
    if self.raster_metadata
      self.raster_metadata.original_metadata = xml
    else
      self.build_raster_metadata(original_metadata: xml)
    end
    raster_metadata.save
  end
  
  def srid(raster_dataset)
    
    band = raster_dataset.raster_band_index.to_i
    band = 1 if band <= 0
    
    sql = "SELECT terrapop_raster_variable_projection(#{id}, #{band})"
    
    result = ActiveRecord::Base.connection.execute(sql).first
    
    if result.nil?
      $stderr.puts "ERR: terrapop_raster_variable_projection(#{id}, #{band}) -- returned no results"
      PROJECTION_WGS84
    else
      result["terrapop_raster_variable_projection"].to_i
    end
    
  end


  def build_raster_values(level, raster_operation, raster_dataset, timepoint = nil)
    # We'll also want to get the geog_instances for the results, so get those first,
    # and put them in a hash so we can quickly find them later.
    result_geog_instances = level.geog_instances
    operation = raster_operation.opcode
    timepoint_id = nil
    s = nil
    
    unless timepoint.nil?
      timepoint_id = timepoint.id
    end

    $stderr.puts "RasterVariable::build_raster_values called - #{level}, #{raster_operation}, #{raster_dataset}" if ENV['DEBUG'].to_i > 2

    if result_geog_instances.empty?
      $stderr.puts "The level #{level} must have at least one geog_instance."
      return []
    end
    
    geog_instance_lookup = Hash.new
    result_geog_instances.each{ |e| geog_instance_lookup[e.id] = e }

    unless raster_datasets.include? raster_dataset
      $stderr.puts "**** Ignoring out-of-universe RasterDataset[#{raster_dataset.inspect}] for RasterVariable[#{mnemonic}] ****"
      return []
    end

    # call select * from terrapop_raster_summary(level.id, this.id, operation);
    # or select (terrapop_raster_summary(level.id, this.id, operation)).*
    # where level is the sample_geog_level.id, this.id is the raster_variable_id of this raster, and operation is one of
    # min, max, mean, sum, count, or mode.
    # Should return collection of results that look something like this:
    #
    # sample_geog_level_id | raster_variable_id | raster_operation_name | geog_instance_label | geog_instance_code | raster_mnemonic  |  boundary_area   | summary_value
    # ---------------------+--------------------+-----------------------+---------------------+--------------------+------------------+------------------+---------------
    #                    2 |                333 | max                   | Rondônia            |                 11 | coffee_yield_max | 237581357173.494 |        0.8789
    #                    2 |                333 | max                   | Acre                |                 12 | coffee_yield_max | 152576633081.708 |        0.9766
    #                    2 |                333 | max                   | Amazonas            |                 13 | coffee_yield_max | 1577624256765.11 |        1.1621

    #sample_geog_lvl_id bigint, raster_var_id bigint, raster_op_name varchar(32)

    band = raster_dataset.raster_band_index.to_i
    band = 1 if band <= 0

    $stderr.puts "TerrapopRasterSummaryCache.where(raster_dataset_id: #{raster_dataset.id},  sample_geog_level_id: #{level.id}, raster_variable_id: #{id}, raster_operation_name: #{clean_operation}, band_index: #{band}, raster_timepoint_id: #{timepoint_id})"  if ENV['DEBUG'].to_i > 2

    clean_operation = operation

    if clean_operation.match(/_netcdf/)
      clean_operation = clean_operation.gsub(/_netcdf/, '')
    end

    terrapop_raster_summary_caches = TerrapopRasterSummaryCache.where(raster_dataset_id: raster_dataset.id,  sample_geog_level_id: level.id, raster_variable_id: id, raster_operation_name: clean_operation, band_index: band, raster_timepoint_id: timepoint_id)

    

    has_area_reference = !area_reference.nil?

    if terrapop_raster_summary_caches.count == 0

      stored_proc_call =
        case raster_data_type.code
        when 'binary'
          
          if srid(raster_dataset) == PROJECTION_WGS84
            "SELECT * FROM terrapop_wgs84_categorical_binary_summarization_v11302016(#{level.id}, #{id}, #{band})"
          else
            "SELECT * FROM terrapop_MODIS_categorical_binary_summarization_v12012016(#{level.id}, #{id}, #{band})"
          end
          
        when 'categorical'
          
          if srid(raster_dataset) == PROJECTION_WGS84
            "SELECT * FROM terrapop_wgs84_categorical_summarization( #{level.id}, #{id}, #{band} )"
          else
            "SELECT * FROM terrapop_modis_categorical_summarization( #{level.id}, #{id}, #{band} )"
          end
          
        when 'contin'
          #raise "AreaReference nil: '#{mnemonic}' - should not be nil" if area_reference.nil?

          # RETURNS TABLE (geog_instance_id bigint, geog_instance_label character varying, min double precision, max double precision, mean double precision, count bigint, stddev double precision, total_area double precision)

          "SELECT * FROM terrapop_continuous_summarization( #{level.id}, #{id} )"

          #if raster_datasets.first.mnemonic == 'GLICROPS' or raster_datasets.first.mnemonic == 'GLIAGLAND'
          #  if /HAR$/.match(mnemonic) or mnemonic == 'CROPLAND2000' or mnemonic == 'PASTURE2000'
          #    "SELECT * FROM terrapop_gli_harvested_summarization_09292016(#{level.id}, #{id})"
          #  elsif /YLD$/.match(mnemonic)
          #    "SELECT * FROM terrapop_continous_summarization_10052016(#{level.id}, #{id})"
          #  else
          #    raise "No matching stored procedure for #{mnemonic}"
          #  end
          #else
          #  "SELECT * FROM terrapop_continuous_summarization0(#{level.id}, #{id})"
          #end
        when 'cont_ext_areaprop'
          
          "SELECT * FROM terrapop_gli_harvested_summarization( #{level.id}, #{id} )"
          
        when 'cont_ext_arearef'

          # RETURNS TABLE (geog_instance_id bigint, geog_instance_label character varying, count bigint, total_area double precision, mean double precision, stddev double precision, min double precision, max double precision)

          #"SELECT * FROM terrapop_continuous_summarization_without_arearef(#{level.id}, #{id}, #{band})"
        
          "SELECT * FROM terrapop_area_reference_summarization( #{level.id}, #{id} )"
        
        when 'contin_netcdf'
          
          if timepoint_id.nil?
            raise "Timepoint Object CANNOT be nil"
          end
          
          $stderr.puts "===> TYPE: 'contin_netcdf'"
          $stderr.puts timepoint.inspect

          #short_name = level.country_level.country.short_name.downcase

          #r = ActiveRecord::Base.connection.execute("SELECT * FROM terrapop_get_cruts_template(#{level.id}, #{id}, '/tmp/')")

          #"SELECT * FROM terrapop_cruts_timepoint_analysis( #{level.id}, #{id}, 'climate.cruts_global_#{short_name}', 'climate.cruts_322', '#{timepoint.timepoint}')"

          "SELECT * FROM terrapop_cruts_timepoint_analysis_new(#{level.id}, #{id}, '#{timepoint.timepoint}')"

          #raise "NetCDF has not been implemented"

          #

        else
          raise "Raster without area_reference has been detected: RasterVariable[#{id}]" unless has_area_reference

          $stderr.puts "++> mnemonic: #{mnemonic}"

          if /YLD$/.match(mnemonic)
            $stderr.puts "++> YLD: #{mnemonic}"
            # RETURNS TABLE (geog_instance_id bigint, geog_instance_label character varying, min double precision, max double precision, mean double precision, count bigint)
            "SELECT * FROM terrapop_gli_yield_areal_summarization_v2(#{level.id}, #{id})"
          elsif /HAR$/.match(mnemonic)
            $stderr.puts "++> HAR: #{mnemonic}"
            # RETURNS TABLE (geog_instance_id bigint, geog_instance_label character varying, percent_area double precision, harvest_area double precision)
            "SELECT * FROM terrapop_gli_harvest_areal_summarization_v6(#{level.id}, #{id})"
          else
            $stderr.puts "++> OTHER: #{mnemonic}"
            # RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying, binary_area double precision, total_area double precision, percent_area double precision)
            "SELECT * FROM terrapop_glc_binary_summarization_v7(#{level.id}, #{id})"
          end
        end

      $stderr.puts "===[RASTERVARIABLE INFO]       ===> #{mnemonic} | #{level.internal_code} [#{level.id}] | operation: #{operation} | band: #{band}"
      $stderr.puts "===[RASTER SUMMARIZATION QUERY]===> #{stored_proc_call}"

      result = ActiveRecord::Base.connection.execute(stored_proc_call)

      all_columns = ['min', 'max', 'mean', 'count', 'num_class', 'mod_class', 'binary_area', 'percent_area', 'percent', 'total_area', 'harvest_area']

      if operation.match(/_netcdf/)
        operation = operation.gsub(/_netcdf/, '')
      end

      if result.count > 0
        terrapop_raster_summary_caches = []

        seen = false

        result.each do |r|
          
          geog_instance_id =
            if r.has_key? 'geog_instance_id'
              r['geog_instance_id']
            elsif r.has_key? 'geog_instance'
              r['geog_instance']
            else
              -1
            end

          column_overlap = all_columns & r.keys
          columns_n_operations = {}

          # this is some fanciness of taking an array of hashes and squashing it down to just a hash; originally, each array element is just a single key/value pair
          column_overlap = column_overlap.map{|field| {field => get_operation(field)}}.reduce Hash.new, :merge

          unless seen
            $stderr.puts "==[COLUMNs, OPs, BAND] => [#{column_overlap.inspect}, '#{band}']=="
            seen = true
          end

          column_overlap.each do |column, op|

            #binding.pry

            unless op.nil?

              if op.match(/_netcdf/)
                op = op.gsub(/_netcdf/, '')
              end

              cnt = TerrapopRasterSummaryCache.where(raster_dataset_id: raster_dataset.id, geog_instance_id: geog_instance_id.to_i, sample_geog_level_id: level.id, raster_variable_id: id, raster_operation_name: op, band_index: band, raster_timepoint_id: timepoint_id).count

              #binding.pry

              #$stderr.puts "#{cnt}"

              if cnt == 0

                trsc = TerrapopRasterSummaryCache.new

                val = get_value(r, op).to_f

                #$stderr.puts "build_raster_values() -> val: " + val.to_s

                if op.match(/percent/)
                  val *= 100
                end

                trsc.sample_geog_level_id   = (r.has_key?('sample_geog_level_id')  ? r['sample_geog_level_id'].to_i : level.id)
                trsc.raster_variable_id     = id
                trsc.raster_operation_name  = op
                trsc.geog_instance_id       = geog_instance_id
                trsc.geog_instance_label    = r['geog_instance_label']
                trsc.geog_instance_code     = (r.has_key?('geog_instance_code')    ? r['geog_instance_code'].to_f   : -1.0)
                trsc.raster_mnemonic        = RequestRasterVariable.mnemonic(self, RasterOperation.where(opcode: op).first, raster_dataset, level, timepoint) #mnemonic + "_" + op + "_" + band.to_s
                trsc.boundary_area          = (r.has_key?('boundary_area')         ? r['boundary_area'].to_f        : -1.0)
                trsc.raster_area            = (r.has_key?('raster_area')           ? r['raster_area'].to_f          : (r.has_key?('total_area') ? r['total_area'].to_f : -1.0))
                trsc.summary_value          = val
                trsc.has_area_reference     = has_area_reference
                trsc.band_index             = band
                trsc.raster_dataset_id      = raster_dataset.id
                trsc.raster_timepoint_id    = timepoint_id
                trsc.save

                #
              end

            else
              
              $stderr.puts "**** get_operation('#{column}'), raster_data_type.code[#{raster_data_type.code}] passed thru without operation and returned nil; result had the fields: #{r.keys.join(", ")} ****"
            end
          end

        end

        ### UNCOMMENT WHEN RE-ENABLING CACHING
        terrapop_raster_summary_caches = TerrapopRasterSummaryCache.where(raster_dataset_id: raster_dataset.id, sample_geog_level_id: level.id, raster_variable_id: id, raster_operation_name: clean_operation, band_index: band, raster_timepoint_id: timepoint_id)
      
        
        
      end
      
    else
      
      $stderr.puts "Found #{terrapop_raster_summary_caches.count} results cached" if ENV['DEBUG'].to_i > 2
      
    end
    
    all_geog_instance_ids = SampleGeogLevel.find(level.id).geog_instances.map{|gi| gi.id }
    
    all_geog_instances_found = terrapop_raster_summary_caches.map{|trsc| trsc.geog_instance_id }
    all_operations = terrapop_raster_summary_caches.map{|trsc| trsc.raster_operation_name }.uniq

    geog_instances_diff = all_geog_instance_ids - all_geog_instances_found

    if geog_instances_diff.count > 0 and all_geog_instance_ids.count > 0
      all_operations.each do |op|
        geog_instances_diff.each do |gi_id|
        
          geog_instance = GeogInstance.find(gi_id)
        
          trsc = TerrapopRasterSummaryCache.new
          trsc.sample_geog_level_id   = level.id
          trsc.raster_variable_id     = id
          trsc.raster_operation_name  = op
          trsc.geog_instance_id       = geog_instance.id
          trsc.geog_instance_label    = geog_instance.label
          trsc.geog_instance_code     = geog_instance.code
          trsc.raster_mnemonic        = RequestRasterVariable.mnemonic(self, RasterOperation.where(opcode: op).first, raster_dataset, level)
          trsc.boundary_area          = -1.0
          trsc.raster_area            = -1.0
          trsc.summary_value          = 0.0
          trsc.has_area_reference     = has_area_reference
          trsc.band_index             = band
          trsc.raster_dataset_id      = raster_dataset.id

          trsc.save
        end
      end
      
      terrapop_raster_summary_caches = TerrapopRasterSummaryCache.where(raster_dataset_id: raster_dataset.id, sample_geog_level_id: level.id, raster_variable_id: id, raster_operation_name: clean_operation, band_index: band, raster_timepoint_id: timepoint_id)
    end

    output = terrapop_raster_summary_caches.map do |r|
      # build_raster_value_from_row(r, geog_instance_lookup[r.geog_instance_id.to_i])
      # build_raster_value_from_row(r)
      RasterValue.new(r)
    end
    
    #binding.pry
    
    output
  end


  def get_operation(column_name)
    case column_name
    when 'mod_class'
      'mode'
    when 'num_class'
      'num_classes'
    when 'min'
      'min'
    when 'max'
      'max'
    when 'mean'
      'mean'
    when 'count'
      'count'
    when 'binary_area'
      'binary_area'
    when 'total_area'
      if raster_data_type.code == 'cont_ext_arearef'
        'total_area_ref'
      elsif raster_data_type.code == 'binary'
        'total_area_bin'
      elsif raster_data_type.code == 'cont_ext_areaprop' or raster_data_type.code == 'contin'
        'total_area_areal'
      end
    when 'harvest_area'
      'total_area_areal'
    when 'percent'
      if raster_data_type.code == 'binary'
        'percent_area_bin'
      elsif raster_data_type.code == 'cont_ext_areaprop'
        'percent_area_areal'
      end      
    when 'percent_area'
      if raster_data_type.code == 'binary'
        'percent_area_bin'
      elsif raster_data_type.code == 'cont_ext_areaprop'
        'percent_area_areal'
      end
    else
      raise "ERR: unable to find operation for '#{column_name}'"
    end
  end


  def get_value(raster_summary_row, operation)
    # min double precision, max double precision, mean double precision, count double precision,stddev double precision, total_area double precision

    #$stderr.puts "RasterVariable::get_value() -> raster_summary_row: " + raster_summary_row.inspect
    #$stderr.puts "RasterVariable::get_value() -> operation: " + operation

    case operation
    when 'mode'
      raster_summary_row['mod_class']
    when 'num_classes'
      raster_summary_row['num_class']
    when 'min'
      raster_summary_row['min']
    when 'max'
      raster_summary_row['max']
    when 'mean'
      raster_summary_row['mean']
    when 'count'
      raster_summary_row['count']
    when 'total_area_areal'
      if raster_summary_row.has_key? 'binary_area'
        raster_summary_row['binary_area']
      #elsif raster_summary_row.has_key? 'total_area'
      #  raster_summary_row['total_area']
      elsif raster_summary_row.has_key? 'harvest_area'
        raster_summary_row['harvest_area']
      end
    when 'total_area_ref'
      raster_summary_row['total_area']
    when 'total_area'
      if raster_summary_row.has_key? 'total_area'
        raster_summary_row['total_area']
      elsif raster_summary_row.has_key? 'harvest_area'
        raster_summary_row['harvest_area']
      end
    when 'percent_area_bin'
      if raster_summary_row.has_key? 'percent_area'
        raster_summary_row['percent_area']
      elsif raster_summary_row.has_key? 'percent'
        raster_summary_row['percent']
      end
    when 'percent_area_areal'
      if raster_summary_row.has_key? 'percent'
        raster_summary_row['percent']
      elsif raster_summary_row.has_key? 'percent_area'
        raster_summary_row['percent_area']
      end
    when 'percent_area'
      if raster_summary_row.has_key? 'percent'
        raster_summary_row['percent']
      elsif raster_summary_row.has_key? 'percent_area'
        raster_summary_row['percent_area']
      end
    when 'total_area_bin'
      if raster_summary_row.has_key? 'binary_area'
        raster_summary_row['binary_area']
      else
        raster_summary_row['total_area']
      end
    when 'binary_area'
      raster_summary_row['binary_area']
    else
      raise "Unknown/Unsupported raster operation - '#{operation}'"
    end
  end


  def get_base_categorical_stats(sample_geog_level)
    sql = "select label, terrapop_sample_id, code, ST_ValueCount(rast) as category_count from (
        select label, code, terrapop_sample_id, st_union(rast) as rast from (
          SELECT sgl.terrapop_sample_id as terrapop_sample_id, gi.label as label, gi.code as code, ST_Clip(them_rasters.rast, bound.geog::geometry) as rast
          FROM sample_geog_levels sgl
          inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
          inner join boundaries bound on bound.geog_instance_id = gi.id
          inner join rasters AS them_rasters on ST_Intersects(them_rasters.rast, bound.geog::geometry)
          where sgl.id = #{sample_geog_level.id} AND them_rasters.raster_variable_id = #{id}
        ) base
        group by label, code, terrapop_sample_id
      ) unioned
      order by code"
    ActiveRecord::Base.connection.execute(sql)
  end


  def get_categorical_statistics(sample_geog_level)
    get_base_categorical_stats(sample_geog_level).map{ |result|
      result['category_count'].scan(/\(([0-9]+),([0-9]+)\)/).collect{ |category, count| {category => count} }
    }.flatten.inject(:merge)
  end


  def get_statistics(sample_geog_level)
    sample_precision = TerrapopConfiguration["application"]["environments"][Rails.env]["raster_sample_precision"]
    sql = "SELECT label, terrapop_sample_id, code, (statistics).* FROM (
            select label, terrapop_sample_id, code, _ST_SummaryStats(rast, 1, true, #{sample_precision}) as statistics from (
              select label, code, terrapop_sample_id, st_union(rast) as rast from (
                SELECT sgl.terrapop_sample_id as terrapop_sample_id, gi.label as label, gi.code as code, ST_Clip(them_rasters.rast, bound.geog::geometry) as rast
                FROM sample_geog_levels sgl
                inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                inner join boundaries bound on bound.geog_instance_id = gi.id
                inner join rasters AS them_rasters on ST_Intersects(them_rasters.rast, bound.geog::geometry)
                where sgl.id = 1 AND them_rasters.raster_variable_id = 145
              ) base
              group by label, code, terrapop_sample_id
            ) unioned
            order by code
          ) as block"
    results = ActiveRecord::Base.connection.execute(sql)
    results.first
  end


  def reclass_str
    buckets = {}
    self.raster_variable_classifications.each do |rvc|
      buckets[rvc.grouping] ||= []
      buckets[rvc.grouping] << rvc.mosaic_raster_variable
    end
    buckets
  end


  def self.long_description(raster_variables)
    str = []
    raster_variables.each{ |rv| str << rv.long_description }
    str.join("\n")
  end


  def long_description
    mnemonic + "\t" + label + "\t(" + units.to_s + ")\t" + raster_datasets.first.raster_dataset_group.label
  end


  def classification_ids
    self.classification_raster_variables.pluck(:mnemonic).uniq
  end


end
