require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'rails_is_forked/fork_callback'

describe "ForkCallback" do
  before(:each) do
    @parent_pid = $$
    @child_pid = nil
    @child_proc_called = 0
    @child_proc = RailsIsForked::ForkCallback.add_callback_in_child! do | child_pid |
      @child_pid = child_pid
      $$.should == child_pid
      $$.should_not == @parent_pid
      @child_proc_called += 1
    end
    @parent_proc_called = 0
    @parent_proc = RailsIsForked::ForkCallback.add_callback_in_parent! do | child_pid |
      @child_pid = child_pid
      $$.should_not == child_pid
      $$.should == @parent_pid
      @parent_proc_called += 1
    end
  end

  after(:each) do
    RailsIsForked::ForkCallback.remove_callback_in_child!(@child_proc).should == @child_proc
    RailsIsForked::ForkCallback.remove_callback_in_parent!(@parent_proc).should == @parent_proc
  end

  it "should invoke callbacks with Process.fork { ... }" do
    result = Process.fork do 
      @child_pid = $$
      @child_proc_called.should == 1
    end
    # puts "#{$$} result = #{result.inspect}"
    sleep 1
    result.should_not == @parent_pid
    result.should == @child_pid
    @parent_proc_called.should == 1
  end

  it "should invoke callbacks with Process.fork" do
    result = Process.fork
    # puts "#{$$} result = #{result.inspect}"
    if result
      # In parent
      sleep 1
      @child_proc_called.should == 0
      @parent_proc_called.should == 1
      Process.wait(result)
    else
      # In child
      result.should == nil
      @child_pid.should == $$
      @child_proc_called.should == 1
      @parent_proc_called.should == 0
      Process.exit! 0
    end
  end
end
