require 'influxdb'
require 'logger'
require 'daemons'
require 'yaml'
require 'json'
require 'redis-queue'

require 'mon_elec/collector.rb'
require 'mon_elec/sender.rb'

module MonElec

  class << self
    attr_accessor :logger
    attr_accessor :configuration
    attr_accessor :influxdb
    attr_accessor :queue
  end

  def self.pre_run
    configuration_file = File.join(File.dirname(__FILE__),'..','conf','configuration.yml')
    log_file = File.join(File.dirname(__FILE__),'..','log','mon_elec.log')
    self.configuration = YAML.load_file(configuration_file)
    self.logger = Logger.new(configuration[:log_file] || log_file)
    self.influxdb = InfluxDB::Client.new(configuration[:influxdb])
    self.queue = Redis::Queue.new('mon_elec','bp_mon_elec',  :redis => Redis.new)
    logger.level = Logger.const_get(configuration[:log_level] || "INFO")
    logger.info "Started with configuration: #{configuration}"
  end

  def self.run!
    collector_options = {
      app_name: 'MonElecCollector',
      backtrace: true,
      ontop: false,
      log_output: true
    }
    Daemons.run_proc(collector_options[:app_name],collector_options) do
      MonElec.pre_run
      MonElec::Collector.run!
    end

    sender_options = {
      app_name: 'MonElecSender',
      backtrace: true,
      ontop: false,
      log_output: true
    }
    Daemons.run_proc(sender_options[:app_name],sender_options) do
      MonElec.pre_run
      MonElec::Sender.run!
    end

  end

end
