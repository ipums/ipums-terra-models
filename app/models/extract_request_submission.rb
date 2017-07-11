# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class ExtractRequestSubmission < ActiveRecord::Base

  belongs_to :extract_request

  scope :most_recent, -> { joins("INNER JOIN extract_requests ON extract_requests.id = extract_request_submissions.extract_request_id").where("extract_requests.id = extract_request_submissions.extract_request_id").order("extract_request_submissions.submitted_at DESC") }

  def self.dump_all
    {
      self.to_s.underscore.pluralize => self.all.map{|ers|
        unless ers.extract_request.user_unique_id.nil?
          {
            'extract_request_id' => ers.extract_request.uuid,
            'submitted_at'       => ers.submitted_at
          }
        end
      }.reject{|x| x.nil? }
    }
  end

end
