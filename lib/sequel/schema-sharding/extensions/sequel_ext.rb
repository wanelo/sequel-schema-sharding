module Sequel
  class Database
    class << self
      alias_method :sequel_adapter_class, :adapter_class

      def adapter_class(scheme)
        klass = sequel_adapter_class(scheme)

        begin
          require "sequel/schema-sharding/extensions/#{scheme}/dataset"
        rescue LoadError => e
        end

        klass
      end
    end
  end
end

Sequel::Model.plugin :validation_helpers
