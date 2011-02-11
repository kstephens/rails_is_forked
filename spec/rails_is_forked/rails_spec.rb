unless ENV['RAILS_DATABASE_YML']
  $stderr.puts "#{__FILE__}: enable test with: export RAILS_DATABASE_YML=.../database.yml"
else
  require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
  require 'rubygems'
  gem 'activerecord'
  require 'active_record'
  require 'rails_is_forked/rails'
  
  describe "RailsIsForked::Rails" do
    
    before(:all) do
      spec = ENV["RAILS_DATABASE_YML"]
      spec = YAML.load_file(spec)
      spec = spec[ENV['RAILS_ENV'] || 'development']
      case spec['adapter']
      when 'postgresql'
        gem 'pg'; require 'pg'
      end
      ActiveRecord::Base.establish_connection(spec)
    end
    
    it "should make forked children acquire new db connections." do
      parent_connection = ActiveRecord::Base.connection
      parent_connection_obj = parent_connection.instance_variable_get('@connection')
      read_pipe, write_pipe = IO.pipe
      Process.fork do 
        read_pipe.close
        child_connection = ActiveRecord::Base.connection
        child_connection_obj = child_connection.instance_variable_get('@connection')
        write_pipe.write(Marshal.dump([child_connection.object_id, child_connection_obj.object_id]))
        write_pipe.close
      end
      write_pipe.close
      child_connection_object_id, child_connection_obj_object_id = Marshal.load(read_pipe.read)
      read_pipe.close
      child_connection_object_id.should_not == parent_connection.object_id
      child_connection_obj_object_id.should_not == parent_connection_obj.object_id
      
      if true # not disconnect! before fork
        ActiveRecord::Base.connection.object_id.should == parent_connection.object_id
        ActiveRecord::Base.connection.instance_variable_get('@connection').object_id.should == parent_connection_obj.object_id
      end
    end
    
    it "should handle forks within a transaction." do
      ActiveRecord::Base.transaction do
        parent_connection = ActiveRecord::Base.connection
        parent_connection_obj = parent_connection.instance_variable_get('@connection')
        read_pipe, write_pipe = IO.pipe
        Process.fork do 
          read_pipe.close
          child_connection = ActiveRecord::Base.connection
          child_connection_obj = child_connection.instance_variable_get('@connection')
          write_pipe.write(Marshal.dump([child_connection.object_id, child_connection_obj.object_id]))
          write_pipe.close
        end
        write_pipe.close
        child_connection_object_id, child_connection_obj_object_id = Marshal.load(read_pipe.read)
        read_pipe.close
        child_connection_object_id.should_not == parent_connection.object_id
        child_connection_obj_object_id.should_not == parent_connection_obj.object_id
        
        ActiveRecord::Base.connection.object_id.should == parent_connection.object_id
        ActiveRecord::Base.connection.instance_variable_get('@connection').object_id.should == parent_connection_obj.object_id
      end
    end

  end # describe

end # unless

