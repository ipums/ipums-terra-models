# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class TerrapopExtractInformation


  attr_reader :request

  def initialize(request)
    @request = request
  end


  def build_information_file
    request.create_directories
    user = request.get_user
    File.open(filename, "w") {|f|
      f.puts "User: " + user.to_s + " (" + user.email + ")"

      begin
        f.puts "TP Build: " + Rails.configuration.build_number
      rescue Exception => e
        $stderr.puts "*** Unable to determine build number for deployment"
      end


      f.puts "Extract Date: " + request.updated_at.strftime("%B %e, %Y - %H:%M:%S %Z")

      t = request.total_time.to_i

      ss, ms = t.divmod(1000)          #=> [270921, 0]
      mm, ss = ss.divmod(60)           #=> [4515, 21]
      hh, mm = mm.divmod(60)           #=> [75, 15]
      dd, hh = hh.divmod(24)           #=> [3, 3]
      #puts "%d days, %d hours, %d minutes and %d seconds" % [dd, hh, mm, ss]

      total_time = ""

      times = ActiveSupport::OrderedHash.new

      #times = {"day" => dd, "hour" => hh, "min" => mm, "sec" => ss, "ms" => ms}

      times[:day]  = dd
      times[:hour] = hh
      times[:min]  = mm
      times[:sec]  = ss
      #times[:ms]   = ms

      time_str = times.map{|key,amt|
        if amt > 0
          "#{amt} #{key.to_s}"
        end
      }.reject{|f| f.nil? }.join(", ")

      f.puts "Extract Time: " + time_str

    }

    filename
  end


  def filename
    File.join(request.location, request.name + "_info.txt")
  end


end
