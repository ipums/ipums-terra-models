# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

# Provisional codebook generator

# This might better live in /lib/extract_engine or /app/classes.
class Codebook

  attr_reader :request

  def initialize(request)
    @request = request
  end


  def extra_files
    @extra_files || []
  end


  def generate_file
    @extra_files = []
    request.create_directories
    codebook_text = generate
    Rails.logger.debug codebook_text

    begin
      File.open(codebook_filename, 'w:UTF-8') {|f| f.puts(codebook_text.force_encoding("UTF-8"))}
    rescue Exception => e
      Rails.logger.debug e.backtrace
      begin
        File.open(codebook_filename, 'w') {|f| f.puts(codebook_text)}
      rescue Exception => ee
        Rails.logger.debug ee.backtrace
      end
    end

    Rails.logger.debug "Codebook for "  + @request.extract_type.to_s

    if request.samples.count > 0
      # Microdata Citation(s) needed
    end

    if request.terrapop_samples.count > 0
      # Area-data Citation(s) needed
    end

    if request.raster_datasets.count > 0
      # raster citation(s) needed
    end

    if request.extract_type == ExtractRequest::ExtractTypeConst::RASTER
      Rails.logger.debug "Write raster codebook #{request.name}"
      xml_metadata_file = request.location # File.join(request.location, request.name)
      write_original_raster_metadata(xml_metadata_file)
    end

  end


  def generate_codebook
    @extra_files = []
    request.create_directories

    str = File.open(File.join(Rails.root, 'app/views/codebooks/arealevel_with_raster.txt.erb'), 'r:UTF-8'){|f| f.read}
    b = binding

    File.open(new_codebook_filename, 'w:UTF-8') do |f|
      f.write(ERB.new(str).result(b))
    end

  end

  def codebook_filename
    File.join(request.location, request.name + ".txt")
  end


  def new_codebook_filename
    File.join(request.location, request.name + ".txt")
  end


  def generate
    request.extract_type == ExtractRequest::ExtractTypeConst::RASTER ? generate_raster_codebook : generate_micro_or_area_data_codebook
  end


  def generate_raster_codebook
    output = ["Code book generated on #{Time.now.to_s}."]
    output += ["filename\tmnemonic\tvariable name\tsource dataset"]

    request.expanded_request_raster_variables.each do |v|
      unless v.raster_dataset.nil?
        v.raster_variable.raster_datasets.each{|rd|
          output << "#{v.raster_variable.filename}\t#{v.mnemonic}\t#{v.raster_variable.long_mnemonic}\t#{rd.source}"
        }
      end
    end

    output << ""

    request.expanded_request_raster_variables.each do |v|
      unless  v.raster_variable.raster_categories.empty?
        output << "#{v.mnemonic} codes and labels"
        output << ""
        begin
          v.raster_variable.raster_categories.each do |category|
            output << "#{category.code}\t#{category.label}"
          end
        rescue
          $stderr.puts "RasterVariable does not have contain RasterCategories"
        end

      end
    end

    output.join("\n")
  end


  def write_original_raster_metadata(codebook_name_location)
    request.expanded_request_raster_variables.each {|v|
      variable_metadata_file = File.join(codebook_name_location, v.mnemonic + ".tiff.xml")
      f = File.open(variable_metadata_file,"w:UTF-8")
      if v.raster_variable.raster_metadata
        f.write(v.raster_variable.raster_metadata.original_metadata)
      else
        f.write("No metadata available")
      end
      f.close
      @extra_files << variable_metadata_file
    }
  end


  def generate_micro_or_area_data_codebook
    output = ["Code book generated on #{Time.now.to_s}."]
    output += [heading]
    output << ""
    output << "Datasets: "
    output << "Name\tDescription\tDensity"
    output << samples_used
    output << ""

    if request.has_area_data_variables?
      output << "Area-level Variables"
      output << "Mnemonic\tLabel\tMeasurement Type"
      output << area_variables
    end

    if request.has_raster_variables?
      output << ""
      output << "Raster Variables"
      output << "Mnemonic\tLabel\tOperation\tUnits"
      output << raster_variables
    end

    if request.has_microdata_variables?
      output << ""
      output << "Microdata Variables"
      output << "Mnemonic\tLabel\tRecord Type\tImplied Decimals"
      output << microdata_variables
      output <<  ""
      output << variable_categories
    end

    lines = ""

    begin
      lines = output.flatten.map { |ele|
        ele.force_encoding("UTF-8")
      }.join("\n")
    rescue Exception => e
      Rails.logger.debug "======================================================\n\n\n"
      output.flatten.each{|line| Rails.logger.debug line.encoding.to_s + " == '" + line + "'"}
      raise e
    end

    lines
  end



  private


  def samples_used
    request.terrapop_samples.map do |sample|
      sample_line(sample)
    end
  end


  def sample_line(terrapop_sample)
    if terrapop_sample.sample.nil?
      "N/A\tN/A\tN/A"
    else
      ([] << terrapop_sample.sample.name << terrapop_sample.sample.long_description << terrapop_sample.sample.density.to_s ).join("\t")
    end
  end


  def area_variables
    request.expanded_request_area_data_variables.map do |v|
      "#{v.mnemonic.to_s}\t#{v.label}\t#{v.measurement_type.label}"
    end
  end


  def raster_variables
    request.expanded_request_raster_variables.map do |rrv|
      rv = rrv.raster_variable
      "#{rrv.mnemonic}\t#{rv.long_mnemonic}\t#{rrv.operation}\t#{rv.units}"
    end
  end


  def microdata_variables
    request.variables.map do |v|
      "#{v.mnemonic}\t#{v.label}\t#{v.record_type}\t#{v.implied_decimal_places}"
    end
  end


  def variable_categories
    request.variables.map do |v|
      ["#{v.mnemonic} codes and categories:",
      v.categories.map{|c| "#{c.code}\t#{c.label}"}].flatten
    end.flatten
  end


  def heading
    "Extract Type: #{request.extract_type.to_s.gsub("_"," ").upcase}"
  end


end

