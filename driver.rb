# frozen_string_literal: true

require 'ap'
require_relative 'cask/dsl'
require_relative 'cask/dsl/version'
require 'byebug'

content = "/Users/luis/Projects/homebrew-cask/Casks/zerobranestudio.rb"

$v = ""

lambda {

Kernel.send(:define_method, :cask) do |*args, &block|
  @dsl = Cask::DSL.new(content)
  ap block.call
end


DSL_METHODS = [ :app, :appcast, :appdir, :conflicts_with, :depends_on, :homepage,
                :language, :languages, :name, :sha256, :uninstall, :url, :zap, :version,
                :installer, :auto_updates, :appdir, :binary, :staged_path ].freeze

DSL_METHODS.each do |method_name|
  define_method(method_name) do |*args, &block|
    if $v.empty?
      $v = args.first unless args.nil? && method_name == "version"
    end

    args ||= []
    return method_name if args.nil?

    unless args.empty?
      ap  method_name.to_s + "      =>     " + args.first.to_s
    end

    if method_name.to_s == 'version'
      ap "inside version conditional"
      @x = Cask::DSL::Version.new($v)
    end

    @dsl.send(method_name, *args, &block)
  end
end
}.call

load content
