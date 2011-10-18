require 'spec_helper'
require 'boxer'

module MyTestModule
  def my_test_method; 42 end
end

module MySecondTestModule
  def my_second_test_method; 43 end
end

describe Boxer do

  describe ".box" do
    it "can create a box based on a simple hash" do
      Boxer.box(:foo) do
        {:working => true}
      end

      Boxer.ship(:foo).should eq({:working => true})
    end

    it "defaults to shipping the base view, when it exists" do
      Boxer.box(:foo) do |box|
        box.view(:base) { {:working => true} }
      end

      Boxer.ship(:foo).should eq({:working => true})
    end

    it "fails if views are specified, but :base is missing" do
      Boxer.box(:foo) do |box|
        box.view(:face) { {:working => true} }
      end

      expect {
        Boxer.ship(:foo).should eq({:working => true})
      }.to raise_exception(Boxer::ViewMissingError)
    end

    it "executes its block in a sandbox context, not a global one" do
      Boxer.box(:foo) do |box|
        self
      end

      context_obj = Boxer.ship(:foo)
      context_obj.inspect.should_not include('RSpec')
      context_obj.inspect.should include('Class')
    end

    it "raises a ViewMissing error if given a non-existent view" do
      Boxer.box(:foo) do |box|
        box.view(:face) { {:working => true} }
      end

      expect {
        Boxer.ship(:foo).should eq({:working => true})
      }.to raise_exception(Boxer::ViewMissingError)
    end
  end

  describe ".clear!" do
    it "clears all boxes" do
      Boxer.box(:foo) { {:working => true} }
      Boxer.clear!
      Boxer.boxes.should be_empty
    end
  end

  describe ".configure" do
    it "sets config.box_includes via its supplied block" do
      Boxer.config.box_includes = []
      Boxer.configure {|config| config.box_includes = [MyTestModule] }
      Boxer.config.box_includes.should include(MyTestModule)
    end
  end

  describe ".ship" do
    it "accepts arguments and passes them to a box for shipping" do
      Boxer.box(:bar) do |box, x, y, z|
        box.view(:base) { {:working => true, :stuff => [x, y, z]} }
      end

      Boxer.ship(:bar, 1, 2, 3).should eq(
        {:working => true, :stuff => [1, 2, 3]}
      )
    end

    it "allows a hash as the final argument" do
      Boxer.box(:bar) do |box, x, y, z|
        box.view(:base) { {:working => true, :stuff => [x, y, z]} }
      end

      Boxer.ship(:bar, 1, 2, :banana => true).should eq(
        {:working => true, :stuff => [1, 2, {:banana => true}]}
      )
    end

    it "includes modules from config.box_includes in shipping boxes" do
      Boxer.config.box_includes = [MyTestModule, MySecondTestModule]
      Boxer.box(:bar) do |box|
        box.view(:base) { {:a => my_test_method, :b => my_second_test_method} }
      end

      Boxer.ship(:bar).should eq({:a => 42, :b => 43})
    end
  end

  describe "#precondition" do
    it "ships the value emitted in the precondition" do
      Boxer.box(:foo) do |box, obj|
        box.precondition {|resp| resp.emit({}) if obj.nil? }
        box.view(:base) { {:working => true} }
      end

      Boxer.ship(:foo, nil).should eq({})
    end

    it "disregards the precondition if no value is emitted" do
      Boxer.box(:foo) do |box, obj|
        box.precondition {|resp| resp.emit({}) if obj.nil? }
        box.view(:base) { {:working => true} }
      end

      Boxer.ship(:foo, Object.new).should eq({:working => true})
    end

    it "can handle nil as an emitted precondition value" do
      Boxer.box(:foo) do |box, obj|
        box.precondition {|resp| resp.emit(nil) if obj.nil? }
        box.view(:base) { {:working => true} }
      end

      Boxer.ship(:foo, nil).should eq(nil)
    end

    it "doesn't remember a fallback value from a previous shipping" do
      Boxer.box(:foo) do |box, obj|
        box.precondition {|resp| resp.emit({}) if obj.nil? }
        box.view(:base) { {:working => true} }
      end

      Boxer.ship(:foo, nil).should eq({})
      Boxer.ship(:foo, Object.new).should eq({:working => true})
    end
  end

  describe "#view" do
    it "allow extending of other views" do
      Boxer.box(:foo) do |box|
        box.view(:base) { {:working => true} }
        box.view(:face, :extends => :base) { {:awesome => true} }
      end

      Boxer.ship(:foo, :view => :face).should eq(
        {:working => true, :awesome => true}
      )
    end

    it "extends by smashing lesser (extended) views" do
      Boxer.box(:foo) do |box|
        box.view(:base) { {:working => true} }
        box.view(:face, :extends => :base) { {:working => :awesome} }
      end

      Boxer.ship(:foo, :view => :face).should eq(
        {:working => :awesome}
      )
    end

    it "extends by merging nested keys without overriding" do
      Boxer.box(:foo) do |box|
        box.view(:base) { {:working => {:a => 1}} }
        box.view(:face, :extends => :base) { {:working => {:b => 2}} }
      end

      Boxer.ship(:foo, :view => :face).should eq(
        {:working => {:a => 1, :b => 2}}
      )
    end

    it "allows extending in a chain of more than two views" do
      Boxer.box(:foo) do |box|
        box.view(:base) { {:working => {:a => 1}} }
        box.view(:face, :extends => :base) { {:working => {:b => 2}} }
        box.view(:race, :extends => :face) { {:working => {:c => 3}} }
      end

      Boxer.ship(:foo, :view => :race).should eq(
        {:working => {:a => 1, :b => 2, :c => 3}}
      )
    end
  end

end
