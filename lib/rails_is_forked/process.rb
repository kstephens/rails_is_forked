require 'rails_is_forked/fork_callback'
require 'ostruct'
require 'thread' # Mutex

module RailsIsForked
  # Adds Process.current[] variables that are cleared in child processes.
  module Process
    def self.included target
      super
      target.extend(ModuleMethods)
      ForkCallback.add_callback_in_child! do
        ::Process.parent = ::Process._current
        ::Process.current = nil
      end
    end

    module ModuleMethods
      @@mutex = Mutex.new

      @@current = nil
      def _current
        @@current
      end
      def current
        @@mutex.synchronize do
          unless @@current
            @@current = OpenStruct.new(:process_id => $$, :variables => { }, :parent => parent)
            def @@current.[] k
              variables[k]
            end
            def @@current.[]= k, v
              variables[k] = v
            end
          end
          @@current
        end
      end

      def current= x
        @@current = x
      end

      @@parent = nil
      def parent
        @@parent
      end
      def parent= x
        @@parent = x
      end
    end

    ::Process.send(:include, self)
  end

end
