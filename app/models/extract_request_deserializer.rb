# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class ExtractRequestDeserializer


  ATTRIBUTES = [:user_unique_id, :id, :status, :number, :comments, :created_at, :updated_at, :boundary_files, :notes, :submitted, :revision_of_id, :file_type, :uuid, :raster_only, :send_to_irods, :extract_url, :request_url, :begin_extract_time, :finish_extract_time, :total_time, :revision_of, :commit, :origin, :processing, :extract_grouping, :data, :title, :extract_filename, :submitted_at, :tp_web_build_number, :tp_xtr_build_number]

  attr_accessor *ATTRIBUTES
  attr_accessor :extract_request

  def initialize(serialized_extract_request)
    
    @extract_request = ExtractRequest.new
    
    ATTRIBUTES.each{|attr|
      if @extract_request.attributes.keys.include? attr.to_s
        @extract_request.send( "#{attr.to_s}=", serialized_extract_request.send(attr) )
      else
        $stderr.puts "#{self} does not contain #{attr}"
      end
    }
    
    @extract_request.updated_at = Time.now.to_s
    
  end

end
