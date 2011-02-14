require 'rails_is_forked/fork_callback'

require 'active_record/connection_adapters/abstract/connection_pool'

module RailsIsForked
  module ConnectionPoolDisconnectOnFork
    @@once = false

    def self.included target
      super

      return if @@once
      @@once = true

      # Register callback to call forget connections in child processes.
      proc = RailsIsForked::ForkCallback.add_callback_in_child! do | child_pid |
        ActiveRecord::Base.connection_handler.connection_pools.each_value do | pool |
          # $stderr.puts "#{$$}: #{pool}.disconnect!"
          pool.forget_all_connections!
        end
      end
      # $stderr.puts "Registered callback #{proc}"
    end

    # Forgets all reserved connections and live connections,
    # without calling #disconnect! on each of them.
    # See also #disconnect!
    def forget_all_connections!
      @reserved_connections = {}
      @connections = []
    end

   ::ActiveRecord::ConnectionAdapters::ConnectionPool.send(:include, self)
  end
end

