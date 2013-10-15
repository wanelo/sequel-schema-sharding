require 'yaml'

module Sequel
  module SchemaSharding
    class Configuration
      attr_reader :env, :yaml_path

      def initialize(env, yaml_path)
        @env = env
        @yaml_path = yaml_path
      end

      def physical_shard_configs
        @physical_shard_configs ||= config['physical_shards'].inject({}) do |hash, value|
          shard_config = config['common'].merge(value[1])

          if shard_config['replicas']
            shard_config['replicas'] = shard_config['replicas'].map do |name, replica|
              config['common'].merge(replica)
            end
          end

          hash[value[0]] = shard_config
          hash
        end
      end

      def logical_shard_configs(table_name)
        table_name = table_name.to_s
        @logical_shard_table_configs ||= {}
        @logical_shard_table_configs[table_name] ||= begin
          config, number_of_shards = parse_logical_shard_config_for(table_name),
                                     number_of_shards(table_name)
          raise "Shard number mismatch: expected #{number_of_shards} got #{config.size} for table #{table_name}" if config.size != number_of_shards
          config
        end

      end

      def table_names
        config['tables'].keys
      end

      def schema_name(table_name)
        config['tables'][table_name.to_s]['schema_name']
      end

      def number_of_shards(table_name)
        config['tables'][table_name.to_s]['number_of_shards']
      end

      private

      def parse_logical_shard_config_for(table_name)
        table_configs = config['tables'][table_name]
        raise "Unknown table #{table_name} in configuration" if table_configs.nil?
        table_configs['logical_shards'].inject({}) do |hash, value|
          eval(value[1]).each do |i|
            hash[i] = value[0]
          end
          hash
        end
      end

      def config
        yaml[env.to_s]
      end

      def yaml
        @raw_yaml ||= YAML.load_file(yaml_path)
      end
    end
  end
end
