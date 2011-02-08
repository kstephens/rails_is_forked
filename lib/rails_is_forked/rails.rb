require 'rails_is_forked/fork_callback'

require 'active_record/connection_adapters/abstract/connection_pool'

module RailsIsForked
  module ConnectionPoolDisconnectOnFork
    @@once = false

    def self.included target
      super

      return if @@once
      @@once = true

      # Register callback to call ConnectionPool#disconnect! on all instances.
      proc = RailsIsForked::ForkCallback.add_callback_in_child! do | child_pid |
        ActiveRecord::Base.connection_handler.connection_pools.each_value do | pool |
          # $stderr.puts "#{$$}: #{pool}.disconnect!"
          pool.disconnect!
        end
      end
      # $stderr.puts "Registered callback #{proc}"
    end

   ::ActiveRecord::ConnectionAdapters::ConnectionPool.send(:include, self)
  end
end

