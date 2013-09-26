require 'logger'

module Sequel
  module SchemaSharding
    class LoggerProxy < ::Logger
      def initialize
      end

      def add(severity, message = nil, progname = nil, &block)
        Sequel::SchemaSharding.logger.add(severity, message, progname, &block)
      end
    end
  end
end
