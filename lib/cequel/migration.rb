module Cequel
  class Migration
    attr_reader :db

    def initialize
      if self.class.cequel_env_conf['port'] == '9042' then
        @db = Cql::Client.connect(server,{ :keyspace => self.class.cequel_env_conf['keyspace'] })
      else
      @db = CassandraCQL::Database.new(server, { :keyspace => self.class.cequel_env_conf['keyspace'] }, thrift_options)
      end
    end

    def execute(cql_string)
      db.execute(cql_string)
    end

    def self.cequel_conf_path
      File.join(::Rails.root, "config", "cequel.yml")
    end

    def self.cequel_conf_file
      File.open(self.cequel_conf_path)
    end

    def self.cequel_conf
      YAML::load(self.cequel_conf_file)
    end

    def self.cequel_env_conf
      self.cequel_conf[::Rails.env]
    end

  private
    def server
      if self.class.cequel_env_conf['hosts']
        return self.class.cequel_env_conf['hosts'].first
      else
        return self.class.cequel_env_conf['host']
      end
    end

    def thrift_options
      if self.class.cequel_env_conf['thrift']
        return self.class.cequel_env_conf['thrift'].inject({}) { |obj,(k,v)| obj[k.to_sym] = v; obj }
      else
        return {}
      end
    end
  end
end
