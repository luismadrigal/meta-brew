# frozen_string_literal: true

# require_relative "caskroom"
require_relative "exceptions"

require_relative "dsl/appcast"
# require_relative "dsl/base"
# require_relative "dsl/caveats"
require_relative "dsl/conflicts_with"
require_relative "dsl/depends_on"
require_relative "dsl/version"
require_relative "utils"



require 'ap'
require 'set'
require 'pathname'
require_relative "url"

module Cask
  class DSL

  DSL_METHODS = Set.new([:app, :appcast, :appdir, :appdir, :auto_updates, :binary, :conflicts_with,
                         :depends_on, :homepage, :installer, :language, :languages, :name, :sha256,
                         :staged_path, :uninstall, :url, :version, :zap ]).freeze

    attr_reader :cask, :token

    def initialize(cask)
      @cask = cask
      @token = token(cask)
    end

    def token(cask)
      Pathname.new(cask).basename(".rb").to_s
    end

    def name(*args)
      # ap "from inside name method"
      @name ||= []
      return @name if args.empty?

      @name.concat(args.flatten).first
    end

    def set_unique_stanza(stanza, should_return)
      return instance_variable_get("@#{stanza}") if should_return

      if instance_variable_defined?("@#{stanza}")
        raise CaskInvalidError.new(cask, "'#{stanza}' stanza may only appear once.")
      end

      instance_variable_set("@#{stanza}", yield)
    rescue CaskInvalidError
      raise
    rescue => e
      raise CaskInvalidError.new(cask, "'#{stanza}' stanza failed with: #{e}")
    end

    def homepage(homepage = nil)
      set_unique_stanza(:homepage, homepage.nil?) { homepage }
    end

    def language(*args, default: false, &block)
      if args.empty?
        language_eval
      elsif block_given?
        @language_blocks ||= {}
        @language_blocks[args] = block

        return unless default

        unless @language_blocks.default.nil?
          raise CaskInvalidError.new(cask, "Only one default language may be defined.")
        end

        @language_blocks.default = block
      else
        raise CaskInvalidError.new(cask, "No block given to language stanza.")
      end
    end

    def language_eval
      return @language if instance_variable_defined?(:@language)

      return @language = nil if @language_blocks.nil? || @language_blocks.empty?

      raise CaskInvalidError.new(cask, "No default language specified.") if @language_blocks.default.nil?

      locales = MacOS.languages
                     .map do |language|
                       begin
                         Locale.parse(language)
                       rescue Locale::ParserError
                         nil
                       end
                     end
                     .compact

      locales.each do |locale|
        key = locale.detect(@language_blocks.keys)

        next if key.nil?

        return @language = @language_blocks[key].call
      end

      @language = @language_blocks.default.call
    end

    def languages
      return [] if @language_blocks.nil?

      @language_blocks.keys.flatten
    end

    def url(*args)
      set_unique_stanza(:url, args.empty? && !block_given?) do
        if block_given?
          ap "lazy object"
          # ap yield
          LazyObject.new { URL.new(*yield) }
        else
          ap "regular object"
          # ap *args
          URL.new(*args)
        end
      end
    end

    def app(*args); end
    def appcast(*args); end
    def appdir(*args); end
    def auto_updates(*args); end
    def binary(*args); end
    def installer(*args); end
    def staged_path(*args); end
    def uninstall(*args); end
    def zap(*args); end


    def version(arg = nil)
      # ap " Hello from version == "
      set_unique_stanza(:version, arg.nil?) do
        if !arg.is_a?(String) && arg != :latest
          raise CaskInvalidError.new(cask, "invalid 'version' value: '#{arg.inspect}'")
        end

        DSL::Version.new(arg)
      end
    end

    def sha256(arg = nil)
      set_unique_stanza(:sha256, arg.nil?) do
        if !arg.is_a?(String) && arg != :no_check
          raise CaskInvalidError.new(cask, "invalid 'sha256' value: '#{arg.inspect}'")
        end

        arg
      end
    end

    # depends_on uses a load method so that multiple stanzas can be merged
    def depends_on(*args)
      @depends_on ||= DSL::DependsOn.new
      return @depends_on if args.empty?

      begin
        @depends_on.load(*args)
      rescue RuntimeError => e
        raise CaskInvalidError.new(cask, e)
      end
      @depends_on
    end

    def conflicts_with(*args)
      # TODO: remove this constraint, and instead merge multiple conflicts_with stanzas
      set_unique_stanza(:conflicts_with, args.empty?) { DSL::ConflictsWith.new(*args) }
    end

    def method_missing(method, *)
      if method
        # ap method
        Utils.method_missing_message(method, token)
        nil
      else
        super
      end
    end

    def respond_to_missing?(*)
      true
    end

  end
end
