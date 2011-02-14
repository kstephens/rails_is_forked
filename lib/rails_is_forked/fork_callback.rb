
module RailsIsForked
  module ForkCallback
    def self.included target
      super
      target.class_eval do
        include ModuleMethods
        alias :fork_without_callback :fork unless method_defined? :fork_without_callback
        alias :fork :fork_with_callback
      end
    end

    def self.extended target
      super
      target.extend(ModuleMethods)
      target.instance_eval do
        alias :fork_without_callback :fork unless method_defined? :fork_without_callback
        alias :fork :fork_with_callback
      end
    end

    CALLBACK_IN_CHILD  = [ ] unless defined? CALLBACK_IN_CHILD
    CALLBACK_BEFORE_CHILD = [ ] unless defined? CALLBACK_BEFORE_CHILD
    CALLBACK_IN_PARENT = [ ] unless defined? CALLBACK_IN_PARENT

    def self.add_callback_in_child! proc = nil, &block
      proc ||= block
      CALLBACK_IN_CHILD << proc
      proc
    end
    def self.remove_callback_in_child! proc
      CALLBACK_IN_CHILD.delete(proc)
    end

    def self.add_callback_before_child! proc = nil, &block
      proc ||= block
      CALLBACK_BEFORE_CHILD << proc
      proc
    end
    def self.remove_callback_before_child! proc
      CALLBACK_BEFORE_CHILD.delete(proc)
    end

    def self.add_callback_in_parent! proc = nil, &block
      proc ||= block
      CALLBACK_IN_PARENT << proc
      proc
    end
    def self.remove_callback_in_parent! proc
      CALLBACK_IN_PARENT.delete(proc)
    end

    module ModuleMethods
      # TODO: Might need to do this in a critical section.
      def fork_with_callback *args
        CALLBACK_BEFORE_CHILD.each { | proc | proc.call($$) }
        if block_given?
          result = fork_without_callback do
            CALLBACK_IN_CHILD.each { | proc | proc.call($$) }
            yield
          end
          CALLBACK_IN_PARENT.each { | proc | proc.call(result) }
          result
        else
          result = fork_without_callback
          if result 
            # in parent
            CALLBACK_IN_PARENT.each { | proc | proc.call(result) }
          else
            # in child
            CALLBACK_IN_CHILD.each { | proc | proc.call($$) }
          end
          result
        end
      end
    end

    ::Kernel.send(:include, self)
    ::Process.send(:extend, self)
  end

end
