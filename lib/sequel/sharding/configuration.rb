require 'yaml'

module Sequel
  module Sharding
    class Configuration
      attr_reader :env, :yaml_path

      def initialize(env, yaml_path)
        @env = env
        @yaml_path = yaml_path
      end

      def physical_shard_configs
        @physical_shard_configs ||= config['physical_shards'].inject({}) do |hash, value|
          hash[value[0]] = config['common'].merge(value[1])
          hash
        end
      end

      def logical_shard_configs(table_name)
        @logical_shard_table_configs ||= {}
        @logical_shard_table_configs[table_name] ||= begin
          table_configs = config['tables'][table_name]
          raise "Unknown table #{table_name} in configuration" if table_configs.nil?
          table_configs['logical_shards'].inject({}) do |hash, value|
            eval(value[0]).each do |i|
              hash[i] = value[1]
            end
            hash
          end
        end
      end

      def table_names
        config['tables'].keys
      end

      def schema_name(table_name)
        config['tables'][table_name]['schema_name']
      end

      private

      def config
        yaml[env.to_s]
      end

      def yaml
        @raw_yaml ||= YAML.load_file(yaml_path)
      end
    end
  end
end
