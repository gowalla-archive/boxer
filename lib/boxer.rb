require 'boxer/version'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/hash/deep_merge'
require 'ostruct'

class Boxer
  cattr_accessor :config

  self.config = OpenStruct.new({
    :box_includes => [],
  })

  class ViewMissingError < StandardError; end

  def initialize(name, options={}, &block)
    @name = name
    @block = block
    @fallback = []
    @views = {}
    @views_chain = {}
    @view_defaults = options[:views] || {}
    @options = options
  end

  ## class methods

  def self.box(name, options={}, &block)
    (@boxes ||= {})[name] = self.new(name, options, &block)
  end

  def self.boxes
    @boxes
  end

  def self.clear!
    @boxes = {}
  end

  def self.configure
    yield config
  end

  def self.ship(name, *args)
    fail "Unknown box: #{name.inspect}" unless @boxes.has_key?(name)
    @boxes[name].ship(*args)
  end

  ## instance methods

  def emit(val)
    @fallback = [val]
  end

  def ship(*args)
    if args.last.is_a?(Hash)
      view = args.last.delete(:view)
      args.slice!(-1) if args.last.empty?
    end
    view ||= :base

    modules = self.class.config.box_includes
    black_box = Class.new do
      modules.each do |mod|
        include mod
      end
    end
    block_result = black_box.new.instance_exec(self, *args, &@block)

    if @fallback.length > 0
      return @fallback.pop
    elsif @views_chain.any?
      unless @views_chain.has_key?(view)
        fail ViewMissingError.new([@name, view].map(&:inspect).join('/'))
      end
      return @views_chain[view].inject({}) do |res, view_name|
        res.deep_merge(@views[view_name].call(*args))
      end
    else
      return block_result
    end
  end

  def precondition
    yield self
  end

  def view(name, opts={}, &block)
    @views_chain[name] = []
    if opts.has_key?(:extends)
      ancestors = Array(opts[:extends]).map do |parent|
        (@views_chain[parent] || []) + [parent]
      end.flatten.uniq
      @views_chain[name] += ancestors
    end
    @views_chain[name] << name

    @views[name] = block
  end
end
