module Structor
  class Preloader
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Association
      autoload :SingularAssociation
      autoload :CollectionAssociation
      autoload :ThroughAssociation

      autoload :HasMany
      autoload :HasManyThrough
      autoload :HasOne
      autoload :HasOneThrough
      autoload :BelongsTo
    end

    attr_reader :owners, :associations, :options

    def initialize(associations, owners, options = {})
      @owners =  Array.wrap(owners).compact.uniq
      @associations = Array.wrap(associations)
      @options = options
    end

    def klass
      options[:klass]
    end

    def preload
      if @owners.empty?
        []
      else
        @associations.flat_map { |association|
          preloaders_on association
        }
      end
    end

    def self.preload(associations, owners, options = {})
      self.new(associations, owners, options).preload
    end

    private


    def preloaders_on(association)
      case association
        when Hash
          preloaders_for_hash(association)
        when Symbol
          preloaders_for_one(association)
        when String
          preloaders_for_one(association.to_sym)
        else
          raise ArgumentError, "#{association.inspect} was not recognized for preload"
      end
    end

    def preloaders_for_hash(association)
      association.flat_map { |assoc, options|
        preloaders_for_one assoc, options
      }
    end

    def preloaders_for_one(association, options = {})
      reflection = klass._reflect_on_association(association)
      if reflection.options[:polymorphic]
        owners.group_by{|owner| owner[reflection.foreign_type]}.each do |type, owners|
          opts = type.present? ? (options[type.split('::').last.downcase.to_sym] || {}) : {}
          opts.merge!(klass: type.presence && type.constantize, convert_to: self.options[:convert_to])
          preloader = preloader_for(reflection).new(reflection, owners, opts)
          preloader.run(self)
        end
      else
        preloader = preloader_for(reflection).new(reflection, owners, options.merge(self.options.slice(:convert_to)))
        preloader.run(self)
      end
    end

    def preloader_for(reflection)
      case reflection.macro
        when :has_many
          reflection.options[:through] ? HasManyThrough : HasMany
        when :has_one
          reflection.options[:through] ? HasOneThrough : HasOne
        when :belongs_to
          BelongsTo
      end
    end

  end
end