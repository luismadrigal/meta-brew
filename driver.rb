require 'ap'
require_relative 'cask/dsl'
require_relative 'cask/dsl/version'

content = "/Users/luis/Projects/homebrew-cask/Casks/raptor.rb"
$v = ""
lambda {
  bloque = {}
  stanzas = []


DSL_METHODS = [ :app, :appcast, :appdir, :conflicts_with, :depends_on, :homepage,
                :language, :languages, :name, :sha256, :uninstall, :url, :version, :zap,
                :installer, :auto_updates, :appdir, :binary, :staged_path ].freeze

DSL_METHODS.each do |method_name|
  define_method(method_name) do |*args, &block|
    # ap "inside #{method_name}"
    # ap content
    $v = args.first unless args.nil? && method_name == "version"

    @dsl = Cask::DSL.new(content)
    args ||= []
    return args if args.nil?

    unless args.empty?
      ap  method_name.to_s + "      =>     " + args.first.to_s
    end

    if method_name.to_s == "version"
      ap "inside version"
      ap $v
      @x = Cask::DSL::Version.new($v)
    end

    # @dsl.instance_eval(method_name.to_s, &block)
    @dsl.send(method_name, *args, &block)
  end
end

Kernel.send(:define_method, :cask) do |*args, &block|
  @dsl = Cask::DSL.new(content)
  # ap @dsl.instance_variables
  @x = Cask::DSL::Version.new("1.0")
  ap @x.to_s
  # ap @dsl.instance_eval(&block)
  ap block.call(@dsl)
  if block_given?()
    ap "block given!"
    # ap block.call()
  end
end

}.call

load content
