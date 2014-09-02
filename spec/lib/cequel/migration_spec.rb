require 'spec_helper'

describe Cequel::Migration do

  let(:migration_class) { class FooMigration < Cequel::Migration; end; FooMigration }
  let(:migration) { migration_class.new }

  describe "#new" do
    it "create a cassandra-cql database connection for the host & keyspace specified in the environment's config" do
      migration_class.stub(:cequel_env_conf).and_return({ 'host' => 'somehost', 'keyspace' => 'somekeyspace' })
      CassandraCQL::Database.should_receive(:new).with('somehost', { :keyspace => 'somekeyspace' }, {})
      migration
    end
    it "create a cql-rb database connection for the host & keyspace specified in the environment's config if the port is 9042" do
      migration_class.stub(:cequel_env_conf).and_return({ 'host' => 'somehost', 'keyspace' => 'somekeyspace', 'port' => '9042' })
      Cql::Client.should_receive(:connect).with('somehost', { :keyspace => 'somekeyspace' })
      migration
    end
  end
  
  describe "#execute" do
    it "delegates to the cassandra-cql connection execute" do
      migration_class.stub(:cequel_env_conf).and_return({ 'keyspace' => 'test keyspace', 'host' => '123.123.123.123' })
      db = mock('db').as_null_object
      CassandraCQL::Database.stub(:new).and_return(db)
      db.should_receive(:execute).with("some cql string")
      migration.execute("some cql string")
    end

    it "delegates to the cassandra-cql connection execute" do
      migration_class.stub(:cequel_env_conf).and_return({ 'keyspace' => 'test keyspace', 'host' => '123.123.123.123','port' => '9042' })
      db = mock('db').as_null_object
      Cql::Client.stub(:connect).and_return(db)
      db.should_receive(:execute).with("some cql string")
      migration.execute("some cql string")
    end
  end

  describe ".cequel_conf_path" do
    it "returns the path to the cequel conf file" do
      ::Rails.stub(:root).and_return('/foo/bar')
      migration_class.cequel_conf_path.should eq('/foo/bar/config/cequel.yml')
    end
  end

  describe ".cequel_conf_file" do
    it "returns the file object of the file at the cequel_conf_path" do
      conf_path = stub
      conf_file = stub
      migration_class.stub(:cequel_conf_path).and_return(conf_path)
      File.should_receive(:open).with(conf_path).and_return(conf_file)
      migration_class.cequel_conf_file.should eq(conf_file)
    end
  end

  describe ".cequel_conf" do
    it "returns the hash result of YAML loading the cequel.yml conf file" do
      conf_file = stub
      conf_hash = stub
      migration_class.stub(:cequel_conf_file).and_return(conf_file)
      ::YAML.should_receive(:load).with(conf_file).and_return(conf_hash)
      migration_class.cequel_conf.should eq(conf_hash)
    end
  end

  describe ".cequel_env_conf" do
    it "gets the cequel conf" do
      migration_class.should_receive(:cequel_conf).and_return({})
      migration_class.cequel_env_conf
    end

    it "grabs the Rails.env section of the config" do
      conf = mock
      ::Rails.stub(:env).and_return('blue')
      conf.should_receive(:[]).with('blue')
      migration_class.stub(:cequel_conf).and_return(conf)
      migration_class.cequel_env_conf
    end

    context "when the environment is found in the config" do
      before do
        ::Rails.stub(:root).and_return(File.expand_path('../../../fixtures', __FILE__))
        ::Rails.stub(:env).and_return('development')
      end

      it "returns that environments portion of the config as a hash" do
        migration_class.cequel_env_conf.should eq({
          "host"=>"capture.services.dev:9160",
          "keyspace"=>"capture_api_dev",
          "strategy_class"=>"SimpleStrategy",
          "strategy_options"=>{
            "replication_factor"=>1
          },
          "thrift"=>{
            "connect_timeout"=>5,
            "timeout"=>10
          }
        })
      end
    end

    context "when the environment is NOT found in the config" do
      before do
        ::Rails.stub(:root).and_return(File.expand_path('../../../fixtures', __FILE__))
        ::Rails.stub(:env).and_return('nonexistentenvironment')
      end

      it "returns nil" do
        migration_class.cequel_env_conf.should be_nil
      end
    end
  end

  describe "#thrift_options" do
    context "when the environment is found in the config" do
      before do
        ::Rails.stub(:root).and_return(File.expand_path('../../../fixtures', __FILE__))
        ::Rails.stub(:env).and_return('development')
      end

      context "when thrift options are found in the config" do
        it "returns the thrift options as a hash" do
          CassandraCQL::Database.stub(:new).and_return(stub.as_null_object)
          migration.send(:thrift_options).should eq({:connect_timeout=>5, :timeout=>10})
        end
      end

      context "when thrift options are NOT found in the config" do
        before do
          ::Rails.stub(:env).and_return('test')
        end

        it "returns an empty hash" do
          CassandraCQL::Database.stub(:new).and_return(stub.as_null_object)
          migration.send(:thrift_options).should eq({})
        end
      end
    end
  end
end
