# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

data = YAML::load(File.read("data/extracts.yml"))


data.each{|d|
  er = ExtractRequest.new
  er.boundary_files             = d.boundary_files
  er.notes                      = d.notes
  er.submitted                  = false
  er.created_at                 = d.created_at
  er.file_type                  = d.file_type
  er.uuid                       = d.uuid
  er.raster_only                = d.raster_only
  er.send_to_irods              = d.send_to_irods
  er.extract_url                = d.extract_url
  er.request_url                = d.request_url
  er.begin_extract_time         = d.begin_extract_time
  er.finish_extract_time        = d.finish_extract_time
  er.total_time                 = d.total_time
  er.revision_of                = d.revision_of
  er.commit                     = d.commit
  er.origin                     = d.origin
  er.processing                 = d.processing
  er.extract_grouping           = d.extract_grouping
  er.data                       = d.data
  er.title                      = d.title
  er.extract_filename           = d.extract_filename
  er.submitted_at               = d.submitted_at
  er.tp_web_build_number        = d.tp_web_build_number
  er.tp_xtr_build_number        = d.tp_xtr_build_number
  er.user_unique_id             = d.user_unique_id
  er.user_ip_address            = d.user_ip_address
  er.extract_request_format_id  = d.extract_request_format_id
  er.save
} 