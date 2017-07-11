# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CodapExtractFormat


  attr_reader :filename
  
  def initialize(file_name, title, geo_unit_label_column = nil, geo_unit_case_label = nil, extract_request = nil, sample_geog_levels = nil)
    codap_json_file_name = File.join(File.dirname(file_name), File.basename(file_name, ".*") + ".codap")
  
    @header_mappings = {}
    @should_lookup_class_text_mappings = {}
    
    $stderr.puts "[INFO]: Making CODAP-JSON File: '#{codap_json_file_name}'"
    $stderr.puts "[INFO]: #{sample_geog_levels.inspect}"
    
    spec = Gem::Specification.find_by_name("terrapop_models")
    gem_root = spec.gem_dir
    
    codap_template = File.open( File.join(gem_root, 'app', 'views', 'extracts', 'codap_template.json'), 'r' ) {|f| f.read}
    codap_template_json = JSON.parse(codap_template)
    
    csv_obj = CSV.table(file_name, :encoding => 'windows-1251:utf-8')
    
    #csv_obj[:geojson_url] = Array.new(csv_obj.length)
    
    sgl = sample_geog_levels.first
    
    values = []
    
    #binding.pry
    
    geog_column = csv_obj.headers[1]
    
    csv_obj[geog_column].each_with_index do |v,idx|
      
      #binding.pry
      
      gi = GeogInstance.where(code: v, sample_geog_level_id: sgl.id).first
      
      unless gi.nil?
        boundary = gi.boundaries.first
        unless boundary.nil?
          values << boundary.id
        else
          values << nil
        end
      else
        values << nil
      end
      
    end
    
    env_instance = 'sgl_demo'
    
    if Rails.env.live?
      env_instance = 'sgl_data'
    elsif Rails.env.staging?
      env_instance = 'sgl_staging'
    elsif Rails.env.internal?
      env_instance = 'sgl_internal'
    end
    
    csv_obj[:geojson_url] = values.map{|bid| 
      unless bid.nil?
        "https://geoserver.url"
      else
        nil
      end
    }
    
    headers = csv_obj.headers
    
    codap_template_json['name'] = codap_template_json['components'][0]['componentStorage']['title'] = title
    codap_template_json['contexts'][0]['collections'][0]['attrs'] = headers.map{|r| 
      
      name = r.to_s
      
      info = AreaDataRasterVariableMnemonicLookup.where(["LOWER(composite_mnemonic) = ?", r.to_s.downcase]).first
      
      cefn = CodapExtractFormatNode.new(name, info, extract_request)
              
      h = cefn.to_h
      
      @header_mappings[name] = h[:name]
      
      @should_lookup_class_text_mappings[name] = cefn.info.should_lookup_class_text
      
      h
    }
    
    # set geographic codes to 'categorical'
    
    #binding.pry
    
    codap_template_json['contexts'][0]['collections'][0]['attrs'][0]['type'] = "nominal"
    codap_template_json['contexts'][0]['collections'][0]['attrs'][1]['type'] = "nominal"
    
    codap_template_json['contexts'][0]['collections'][0]['attrs'][(headers.length - 1)]['type'] = "boundary"
    
    codap_template_json['contexts'][0]['collections'][0]['cases'] = csv_obj.map{|row| {"values" => Hash[*headers.map{|header| 
      
      hdr = header.to_s
      
      #binding.pry
      
      val = row[header]
      
      if @should_lookup_class_text_mappings[hdr]
        
        info = AreaDataRasterVariableMnemonicLookup.where(["LOWER(composite_mnemonic) = ?", hdr.to_s.downcase]).first
        
        unless info.mnemonic == 'IGBP'
          rv = RasterVariable.where(mnemonic: info.mnemonic).first
          rc = rv.raster_categories.where(code: val).first
        
          unless rc.nil?
            val = rc.label
          end
        else
          
          rv = RasterVariable.where("mnemonic LIKE 'IGBP_%'").where(classification: val).first
          
          unless rv.nil?
            val = rv.label
          end
          
        end
        
        #binding.pry
      end

      #$stderr.puts  "#{hdr} => #{val}"
      #binding.pry
      
      {@header_mappings[hdr] => val}
    
    }.collect{|h|
      #binding.pry
      h.to_a
    }.flatten]} }
    
    #binding.pry
    
    begin
      unless geo_unit_label_column.nil?
        
        codap_template_json['contexts'][0]['collections'][0]['cases'] = codap_template_json['contexts'][0]['collections'][0]['cases'].sort{|a,b| a["values"][geo_unit_label_column.to_s.downcase] <=> b["values"][geo_unit_label_column.to_s.downcase]}

      end
    rescue Exception => e
      $stderr.puts e
    end
    
    #binding.pry
    
    unless geo_unit_case_label.nil?
      codap_template_json['contexts'][0]['collections'][0]['name']  = geo_unit_case_label
      codap_template_json['contexts'][0]['collections'][0]['title'] = geo_unit_case_label
    end
    
    #### set code book
    
    cb_txt = File.open( File.join(gem_root, 'app', 'views', 'extracts', 'codap_codebook.txt'), 'r' ) {|f| f.read}

    #b = binding
    
    variable_descriptions = []
    
    headers.each{|r| 

      info = AreaDataRasterVariableMnemonicLookup.where(["LOWER(composite_mnemonic) = ?", r.to_s.downcase]).first
      
      unless info.nil?
      
        vdn = VariableDescriptionNode.new(info.mnemonic)
      
        d = AreaDataRasterVariableMnemonicLookup::remap_description(vdn.description, info.mnemonic)
        
        #binding.pry
      
        if vdn.toggle == 0 || vdn.toggle == 1
          
          unless d.nil?
            d = d.sub("\t", ":")
            d = d.gsub("\t", ";")
          end
        else
          d = info.description
        end
        
        #binding.pry
        
        variable_descriptions << [@header_mappings[r.to_s], d]
        
      end
    }
    
    @columns_descriptions = variable_descriptions
    @mean_variables = []
    @percent_variables = []
    @num_class_variables = []
    @has_land_cover_classes = false
    @has_glc                = false
    @has_modis              = false
    
    str = []
    extract_request.extract_data_artifacts.each do |eda|
      eda.nil? && next
      #binding.pry
      if headers.include? eda.variables_description['columns'][0].downcase.to_sym
        str << "The rows represent the " + eda.variables_description['country_level'] + " of " + eda.variables_description['country']
        str << ""
        
        eda.variables_description['columns'].each do |column|
          
          info = AreaDataRasterVariableMnemonicLookup.where(["LOWER(composite_mnemonic) = ?", column.downcase]).first
      
          cefn = CodapExtractFormatNode.new(column.downcase, info, extract_request)
              
          h = cefn.to_h
          
          #binding.pry
          
          if column.downcase.match(/mean/)
            @mean_variables      << "    " + h[:name]
          elsif column.downcase.match(/percent/)
            @percent_variables   << "    " + h[:name]
          elsif column.downcase.match(/mode/) or column.downcase.match(/num_classes/)
            
            if column.downcase.match(/^lc/)
              @has_glc = true
            elsif column.downcase.match(/igbp/)
              @has_modis = true
            end
            
            if column.downcase.match(/mode/)
              @has_land_cover_classes = true
              @num_class_variables << "    " + h[:name] + "  indicates the most common land cover class in the unit."
            else
              @num_class_variables << "    " + h[:name] + "  indicates the number of different land cover classes found in the unit."
            end
          end
        end
        
        
      end
    end
    
    @geographic_representation = str
    
    @has_rasters = (extract_request.raster_variables.count == 0) ? false : true
    
    @request = extract_request
    
    #variable_descriptions = variable_descriptions.reject{|vd| vd.nil? }
    
    #binding.pry
    
    cb_txt = ERB.new(cb_txt).result(binding)
    
    codap_template_json['components'][1]['componentStorage']['text'] = cb_txt
    
    File.open(codap_json_file_name, 'w') { |f| f.write(codap_template_json.to_json) }
    
    @filename = codap_json_file_name
  end
  
  class VariableDescriptionNode
    attr_reader :variable_obj
    attr_reader :toggle
    attr_reader :description
    
    def initialize(mnemonic) 
      
      v0 = AreaDataVariable.where(mnemonic: mnemonic).first
      v1 = RasterVariable.where(mnemonic: mnemonic).first

      if v0.nil? and v1.nil?
        @variable_obj = nil
        @toggle       = -1
        @description  = nil
      elsif v0 and v1.nil?
        @variable_obj = AreaDataVariable
        @toggle       = 0
        @description  = v0.long_description
      elsif v1 and v0.nil?
        @variable_obj = RasterVariable
        @toggle       = 1
        @description  = v1.long_description
      end

    end
      
  end
  
  class CodapExtractFormatNode
    
    attr_reader :name
    attr_reader :info
    
    def initialize(name = '', info = nil, extract_request = nil)
      
      name_obj = NameInformation.new(name, info, extract_request)
      
      @name        = name_obj.name
      
      #binding.pry
      
      info_obj = case info
      when nil
        NilInformation
      else
        BasicInformation
      end
      
      @info = info_obj.new(info)
      
    end
    
    def to_h
      info.description.gsub!(/\(binary\)/, '') # <== unfortunately, we have to do this
      info.description.gsub!(/\(areal\)/, '')
      
      {name: name, description: info.description, unit: info.unit, type: info.type}
    end
    
    class BasicInformation
      attr_reader :description
      attr_reader :unit
      attr_reader :type
      attr_reader :is_raster
      attr_reader :should_lookup_class_text
      
      def initialize(info)
        @description = info.description
        @is_raster = false
        @should_lookup_class_text = false
        rv = RasterVariable.where(mnemonic: info.mnemonic).first
        
        rv_obj = case rv
        when nil
          rv = AreaDataVariable.where(mnemonic: info.mnemonic).first
          if rv.nil?
            NilRasterInformation
          else
            BasicAreaDataVariableInformation
          end
        else
          @is_raster = true
          BasicRasterInformation
        end
        
        rv_info = rv_obj.new(rv)
        
        @unit = rv_info.unit
        @type = "numeric"
        
        if @is_raster
          
          data_type = rv.raster_data_type.code
          
          if data_type == 'categorical'
            @type = "nominal"
          end
          
          if info.raster_operation_opcode == 'mode'
            @should_lookup_class_text = true
          end
          
        end
        
        if (@unit == "binary" or @unit == "not applicable") and info.raster_operation_opcode.match(/percent/)
          @unit = "percent"
        elsif (@unit == "binary" or @unit == "not applicable") and info.raster_operation_opcode.match(/total_area/)
          @unit = "numeric"
        elsif @description.match(/num_classes/)
          @type = @unit = "numeric"
        end
        
        @description = AreaDataRasterVariableMnemonicLookup::remap_description(@description)
          
        #binding.pry
        
      end
      
    end

    class NilInformation < BasicInformation
      def initialize(info)
        @description              = ""
        @unit                     = ""
        @is_raster                = false
        @should_lookup_class_text = false
      end
    end
    
    #####
    
    class BasicAreaDataVariableInformation
      attr_reader :unit
      def initialize(variable)
        @unit = variable.measurement_type.label
      end
    end
    
    class BasicRasterInformation
      attr_reader :unit
      def initialize(raster_variable)
        @unit = raster_variable.units
      end
    end
    
    class NilRasterInformation < BasicRasterInformation
      def initialize(raster_variable)
        @unit = ""
      end
    end
    
    class NameInformation
      attr_reader :name
      attr_reader :info
      
      def initialize(name, info, extract_request = nil)
        
        info_obj = case info
        when nil
          NilNameInformation
        else
          ExpandedNameInformation
        end
        
        obj = info_obj.new(name, info, extract_request)
        
        @name = obj.name
        
      end
      
    end

    class NilNameInformation < NameInformation
      def initialize(name, info, extract_request = nil)
        @name = name
      end
    end
    
    class ExpandedNameInformation < NameInformation
      attr_reader :operation
      attr_reader :mnemonic
      attr_reader :data_year
      
      def initialize(name, info, extract_request = nil)
        
        @operation = nil
        @mnemonic  = name
        @data_year = nil
        @name      = ""
        
        @operation = info.raster_operation_opcode
                
        @name += if operation.nil?
          ""
        else
          operation + " "
        end
        
        unless @mnemonic.match(/^geo/)
          
          @name += info.mnemonic
          
          ds = nil
          
          unless info.dataset_label == 'not null'
            
            ds = RasterDataset.where(mnemonic: info.dataset_label).first
            
            if ds.nil?
              
              ds = Sample.where(name: info.dataset_label).first
              
              if ds.nil?
                
                country_code = info.dataset_label[0..1].downcase
                year         = info.dataset_label[2..5]
                
                ds = TerrapopSample.where(short_country_name: country_code, year: year.to_i).first
                
              end
              
            end
            
            
            unless ds.nil?
              
              @name += " "
              
              if ds.is_a? RasterDataset
                
                @name += ds.begin_year.to_s
                
                if ds.begin_year != ds.end_year
                  @name += " " + ds.end_year.to_s
                end
                
              else
                
                @name += ds.year.to_s
                
              end
              
            end
            
          end
        
        else
          @name += @mnemonic
        end
        
        
        #binding.pry
        
      end
      
    end
    
  end

end
