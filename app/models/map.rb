# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class Map < ActiveRecord::Base


  has_many :boundaries
  belongs_to :country
  belongs_to :country_level
  belongs_to :terrapop_sample

  alias_attribute :dataset_id, :terrapop_sample_id


  # Be sure to call construct_instances before calling construct_boundaries
  def construct_instances_for_terrapop_sample(tps, parent_level = nil, code_column = 'ipums_code', include_numeric_code = true)
    my_sgl = tps.sample_geog_level_for_country_level(self.country_level)
    unless my_sgl.nil?
      geog_unit_code = my_sgl.country_level.geog_unit.code

      if self.terrapop_sample_id.nil?
        self.terrapop_sample_id = tps.id
        self.save
      end

      geog_code = nil
      short_name = tps.country.short_name.upcase #my_sgl.terrapop_sample.country.short_name.upcase

      if geog_unit_code == 'NAT'
        geog_code = 'CNTRY'
      elsif geog_unit_code == 'HFLAD'
        geog_code = 'GEO1_' + short_name
      elsif geog_unit_code == 'FLAD'
        geog_code = 'GEO1_' + short_name + tps.year.to_s
      elsif geog_unit_code == 'HSLAD'
        geog_code = 'GEO2_' + short_name
      elsif geog_unit_code == 'SLAD'
        geog_code = 'GEO2_' + short_name + tps.year.to_s
      end

      #$stderr.puts "----------------------------------------------------------------------------"
      #$stderr.puts "#{my_sgl.terrapop_sample.country.full_name} => #{my_sgl.country_level.geog_unit.code} ==> #{geog_code.to_s}"
      #$stderr.puts "----------------------------------------------------------------------------"

      # the insert statement for the national level is simpler than others, so if parent-level is nil.
      # check that we're doing national.
      #if parent_level.nil? and my_sgl.internal_code.rindex('NAT').nil?
      #  raise "attempt to call construct_instances_for_terrapop_sample with no parent_level: #{my_sgl.internal_code}"
      #end

      # once there's a shape_area column on all the maps, we can populate that from here

      inc = include_numeric_code

      geog_instances_count = GeogInstance.where({sample_geog_level_id: my_sgl.id, geog_code: geog_code.to_s}).count

      #GeogInstance.delete_all(["sample_geog_level_id = ? AND geog_code = ?", my_sgl.id, geog_code.to_s])

      if geog_instances_count == 0

        insert_stmt = if parent_level.nil?
          "insert into geog_instances(sample_geog_level_id, parent_id, #{inc ? 'code,' : ''} label, geog_code, str_code, terrapop_sample_id)
          select #{my_sgl.id}, NULL, #{inc ? "CAST(shape.#{code_column} as numeric) as code," : ''} shape.label, '#{geog_code.to_s}', shape.#{code_column}, #{tps.id}
          from #{self.shape_table_name} shape WHERE shape.#{code_column} IS NOT NULL"
        else
          
          ret = ActiveRecord::Base.connection.execute("select #{my_sgl.id}
                from #{self.shape_table_name} shape
                  inner join geog_instances parent ON parent.code = CAST(shape.parent as numeric) AND 
                    parent.sample_geog_level_id = #{parent_level.id} WHERE shape.#{code_column} IS NOT NULL")
          
          if ret.size == 0
            $stderr.puts "*** ERROR: #{self.source_file} does not contain linking codes to its parent (#{parent_level})"
          end
          
          "insert into geog_instances(sample_geog_level_id, parent_id, #{inc ? 'code, ' : ''} label, geog_code, str_code, terrapop_sample_id)
            select #{my_sgl.id}, parent.id, #{inc ? "CAST(shape.#{code_column} as numeric) as code," : ''} shape.label, '#{geog_code.to_s}', shape.#{code_column}, #{tps.id}
            from #{self.shape_table_name} shape
            inner join geog_instances parent ON parent.code = CAST(shape.parent as numeric) AND parent.sample_geog_level_id = #{parent_level.id} WHERE shape.#{code_column} IS NOT NULL"            
        end

        records = ActiveRecord::Base.connection.execute(insert_stmt)

      else
        $stderr.puts "Found GeogInstances for SampleGeogLevel[#{my_sgl.id}], geog_code: #{geog_code.to_s}"

        #if parent_level.nil?
          sql = "select #{my_sgl.id} AS sample_geog_level_id, NULL AS parent_id, #{inc ? "CAST(shape.#{code_column} as numeric) as code," : ''} shape.label AS label, '#{geog_code.to_s}' AS geog_code, shape.#{code_column} AS str_code, #{tps.id} AS terrapop_sample_id FROM #{self.shape_table_name} shape WHERE shape.#{code_column} IS NOT NULL"
        #else
        #  sql = "select #{my_sgl.id} AS sample_geog_level_id, parent.id AS parent_id, #{inc ? "CAST(shape.#{code_column} as numeric) as code," : ''} shape.label AS label, '#{geog_code.to_s}' AS geog_code, shape.#{code_column} AS str_code, #{tps.id} AS terrapop_sample_id from #{self.shape_table_name} shape inner join geog_instances parent ON parent.code = CAST(shape.parent as numeric) and parent.sample_geog_level_id = #{parent_level.id} WHERE shape.#{code_column} IS NOT NULL"
        #end

        records = ActiveRecord::Base.connection.execute(sql)

        geog_instances = GeogInstance.where({sample_geog_level_id: my_sgl.id, geog_code: geog_code.to_s})

        geog_instances.each{|geog_instance|

          records.each{|record|

            if geog_instance.label == record['label']
              geog_instance.parent_id = record['parent_id']

              if inc
                geog_instance.code = record['code']
              end

              geog_instance.geog_code = record['geog_code']
              geog_instance.str_code  = record['str_code']

              geog_instance.save

            end

          }
        }

      end
    else
      $stderr.puts "=*=*=> No SampleGeogLevel for #{tps.inspect} at #{self.country_level.inspect}"
    end
  end

  def construct_boundaries_for_terrapop_sample(tps, code_column = 'ipums_code')
    my_sgl = tps.sample_geog_level_for_country_level(self.country_level)
    unless my_sgl.nil?

      boundaries_count = Boundary.where({map_id: self.id}).count

      if boundaries_count > 0
        $stderr.puts " Found Boundary[map_id: #{self.id}]"
        #Boundary.where({map_id: self.id}).destroy_all
      else
        insert_stmt =
          "insert into boundaries(map_id, geog_instance_id, code, description, geog, geom)
            select #{self.id}, gi.id, CAST(shape.#{code_column} as numeric) as code, shape.label, shape.geog, shape.geom
            from #{self.shape_table_name} shape
            inner join geog_instances gi
              on gi.sample_geog_level_id = #{my_sgl.id} and gi.code = CAST(shape.#{code_column} as numeric) WHERE shape.#{code_column} <> ''"

        records = ActiveRecord::Base.connection.insert(insert_stmt)
      end
    end
  end

  def construct_instances_for_nhgis_terrapop_sample(nhgis_tps, sgl, parent_sgl = nil)
    return nil if nhgis_tps.nhgis_dataset_id.nil?       #get out when the terrapop sample is NOT related to an NHGIS dataset

    $stderr.puts "----------------------------------------------------------------------------"
    $stderr.puts "#{nhgis_tps.country.full_name} => #{sgl.country_level.geog_unit.code} ==> 'GISJOIN'"
    $stderr.puts "----------------------------------------------------------------------------"

    # the insert statement for the national level is simpler than others, so if parent-level is nil.
    # check that we're doing national.
    if parent_sgl.nil?
      if sgl.internal_code.rindex('NAT').nil? and sgl.internal_code.rindex('FLAD').nil?
        raise "attempt to call construct_instances_for_terrapop_sample with no parent_level: #{sgl.internal_code}"
      end
    end

    (schema, table) = self.shape_table_name.split(".", 2)

    columns_stmt = "SELECT column_name FROM information_schema.columns where table_schema = '#{schema}' AND table_name = '#{table}'"

    columns_records = ActiveRecord::Base.connection.execute(columns_stmt).map{|c| c['column_name']}.uniq

    # once there's a shape_area column on all the maps, we can populate that from here
    join_clause = ""
    if !sgl.internal_code.rindex("NAT").nil?                        #nation-level GISJOIN code format varies: e.g. "G1," "G010" depending on the year
      label_column_source = "'United States'"

    elsif !sgl.internal_code.rindex("FLAD").nil?                    #state-level GISJOIN code format: "G" + "SSS" -- 3 of which is numeric

      potential_names = ['statenam', 'name10', 'name']

      overlap = columns_records & potential_names

      if overlap.count == 0
        raise "'potential_names' does not contain an overlap with '#{columns_records.join(", ")}' - #{table}"
      end

      label_column_source = "shape.#{overlap.first}"                        #in NHGIS, states do not have parents

    elsif !sgl.internal_code.rindex("SLAD").nil?
      #when working with a county, the GISJOIN code will be 8 characters long: "G" + "SSS" + "CCCC" -- 7 of which is numeric

      potential_names = ['nhgisnam', 'name10', 'name']

      overlap = columns_records & potential_names

      if overlap.count == 0
        raise "'potential_names' does not contain an overlap with '#{columns_records.join(", ")}' - #{table}"
      end

      label_column_source = "shape.#{overlap.first}"

      join_clause = "INNER JOIN geog_instances parent ON parent.sample_geog_level_id = #{parent_sgl.id} AND parent.code = CAST(SUBSTR(shape.gisjoin,2,3) AS NUMERIC)"

    else
      raise "SampleGeogLevel was neither 'NAT', 'FLAD', nor 'SLAD' -- unable to generate an select/insert statement for #{self.source_file}"
    end

    parent_id_column_source = join_clause.empty? ? "NULL" : "parent.id"

    #the select statement will serve as the select for the bulk insert.  The select statement could also be used for debugging purposes
    select_stmt = "SELECT #{sgl.id}                            AS sample_geog_level_id,
                             #{parent_id_column_source}        AS parent_id,
                             #{self.gisjoin_as_numeric_clause} AS code,
                             #{label_column_source}            AS label,
                             ST_Area(shape.geog)               AS shape_area,
                             'GISJOIN'                         AS geog_code,
                             shape.gisjoin                     AS str_code,
                             #{self.terrapop_sample_id}        AS terrapop_sample_id
                        FROM #{self.shape_table_name} shape
                       #{join_clause}
                        WHERE shape.gisjoin <> ''"

    insert_stmt = "INSERT INTO geog_instances(sample_geog_level_id, parent_id, code, label, shape_area, geog_code, str_code, terrapop_sample_id)
                      #{select_stmt}"
    begin
      $stderr.puts "inserting geog instances...".color(:magenta)
      $stderr.puts insert_stmt
      #p ActiveRecord::Base.connection.exec_query(select_stmt)
      records = ActiveRecord::Base.connection.insert(insert_stmt)
    rescue Exception => e
      raise e.message.color(:red)
    end
  end

  def construct_boundaries_for_nhgis_terrapop_sample(sgl)

    #select_stmt provides the values to be inserted into boundaries
    select_stmt = "SELECT #{self.id} AS map_id,
                          gi.id      AS geog_instance_id,
                          gi.code    AS code,
                          gi.label   AS description,
                          shape.geog AS geog,
                          shape.geom AS geom
                    FROM #{self.shape_table_name} shape
                    INNER JOIN geog_instances gi ON gi.sample_geog_level_id = #{sgl.id} AND gi.code = #{self.gisjoin_as_numeric_clause}
                    WHERE shape.gisjoin <> ''"

    #prepare the insert statement using the select statement above
    insert_stmt = "INSERT INTO boundaries(map_id, geog_instance_id, code, description, geog, geom)
                    #{select_stmt}"

    #execute the insert statement and catch any errors presenting them to the user.  NOTE: duplicates are not checked and will be added when run twice.
    begin
      $stderr.puts "inserting boundaries...".color(:magenta)
      puts insert_stmt
      #p ActiveRecord::Base.connection.exec_query(select_stmt)            #slow: the selects can take a while with the geometry and all...
      records = ActiveRecord::Base.connection.insert(insert_stmt)
    rescue Exception => e
      $stderr.puts e.message.color(:red)
    end

  end

  def shape_table_name
    #using the map's source file, generate the table name for the corresponding shape file table.
    Rails.configuration.database_configuration[Rails.env]['gis_schema_name'] + '.' + self.source_file.gsub('/', '_')
  end

  def gisjoin_as_numeric_clause
    "CAST(SUBSTR(shape.gisjoin,2,LENGTH(shape.gisjoin)-1) AS NUMERIC)"   #same for all levels, just abstracting away complexity
  end

end
