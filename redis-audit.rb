#!/usr/bin/ruby
require 'rubygems'
require 'redis'

class KeyStats
  attr_accessor :total_instances, 
                :total_idle_time, 
                :total_serialized_length,
                :total_expirys_set,
                :min_serialized_length,
                :max_serialized_length,
                :min_idle_time,
                :max_idle_time,
                :max_ttl,
                :sample_keys
  
  def initialize
    @total_instances = 0
    @total_idle_time = 0
    @total_serialized_length = 0
    @total_expirys_set = 0
    
    @min_serialized_length = nil
    @max_serialized_length = nil
    @min_idle_time = nil
    @max_idle_time = nil
    @max_ttl = nil
    
    @sample_keys = {}
  end
  
  def add_stats_for_key(key, type, idle_time, serialized_length, ttl)
    @total_instances += 1
    @total_idle_time += idle_time
    @total_expirys_set += 1 if ttl != nil
    @total_serialized_length += serialized_length
    
    @min_idle_time = idle_time if @min_idle_time.nil? || @min_idle_time > idle_time
    @max_idle_time = idle_time if @max_idle_time.nil? || @max_idle_time < idle_time
    @min_serialized_length = serialized_length if @min_serialized_length.nil? || @min_serialized_length > serialized_length
    @max_serialized_length = serialized_length if @max_serialized_length.nil? || @max_serialized_length < serialized_length
    @max_ttl = ttl if ttl != nil && ( @max_ttl == nil || @max_ttl < ttl )
    
    @sample_keys[key] = type if @sample_keys.count < 10
  end
end

class RedisAudit
  @@key_regex = /^(.*):(.*)$/
  
  def initialize(redis, sample_size)
    @redis = redis
    @keys = Hash.new
    @sample_size = sample_size
    @dbsize = 0
  end
  
  def audit_keys
    debug_regex = /serializedlength:(\d*).*lru_seconds_idle:(\d*)/
    @dbsize = @redis.dbsize
    
    @sample_size.times do
      key = @redis.randomkey
      pipeline = @redis.pipelined do
        @redis.debug("object", key)
        @redis.type(key)
        @redis.ttl(key)
      end
      debug_fields = debug_regex.match(pipeline[0])
      serialized_length = debug_fields[1].to_i
      idle_time = debug_fields[2].to_i
      type = pipeline[1]
      ttl = pipeline[2] == -1 ? nil : pipeline[2]
      @keys[group_key(key, type)] ||= KeyStats.new
      @keys[group_key(key, type)].add_stats_for_key(key, type, idle_time, serialized_length, ttl)
    end
  end
  
  def group_key(key, type)
    # This makes the odds of finding a correct match higher, as mostly these are ids
    key = key.delete("0-9")
    
    matching_key = nil
    length_of_best_match = 0
    
    @keys.keys.each do |current_key|
      length_of_match = 0
      
      current_key.length.times do |index|
        break if key[index] != current_key[index]
        length_of_match += 1
      end
      
      if length_of_match >= key.length/4 && length_of_match > length_of_best_match
        matching_key = current_key
        length_of_best_match = length_of_match
      end
    end
    if matching_key != nil && @@key_regex.match(matching_key)[2] == type
      return matching_key
    else
      return "#{key}:#{type}"
    end
  end
  
  def output_stats
    complete_serialized_length = @keys.map {|key, value| value.total_serialized_length }.reduce(:+)
    sorted_keys = @keys.keys.sort{|a,b| @keys[a].total_serialized_length <=> @keys[b].total_serialized_length}
    
    puts "DB has #{@dbsize} keys"
    puts
    puts "Found #{@keys.count} key groups"
    puts
    sorted_keys.each do |key|
      value = @keys[key]
      key_fields = @@key_regex.match(key)
      common_key = key_fields[1]
      common_type = key_fields[2]
      
      puts "=============================================================================="
      puts "Found #{value.total_instances} keys containing #{common_type}s, like:"
      puts "\e[0;33m#{value.sample_keys.keys.join(", ")}\e[0m"
      puts
      puts "These keys use \e[0;1;4m#{make_proportion_percentage(value.total_serialized_length/complete_serialized_length.to_f)}\e[0m of the total sampled memory (#{value.total_serialized_length} bytes)"
      if value.total_expirys_set == 0
        puts "\e[0;1;4mNone\e[0m of these keys expire"
      else
        puts "\e[0;1;4m#{make_proportion_percentage(value.total_expirys_set/value.total_instances.to_f)}\e[0m of these keys expire (#{value.total_expirys_set}), with maximum ttl of #{value.max_ttl}"
      end
      
      puts "Average idle time: \e[0;1;4m#{(value.total_idle_time/value.total_instances.to_f).round}\e[0m seconds - (Max: #{value.max_idle_time} Min:#{value.min_idle_time})"
      puts
    end
  end
  
  def make_proportion_percentage(value)
    return "#{(value * 10000).round/100.0}%"
  end
end

if ARGV.length != 4
    puts "Usage: redis-audit.rb <host> <port> <dbnum> <sample_size>"
    exit 1
end

host = ARGV[0]
port = ARGV[1].to_i
db = ARGV[2].to_i
sample_size = ARGV[3].to_i

redis = Redis.new(:host => host, :port => port, :db => db)
auditor = RedisAudit.new(redis, sample_size)
puts "Auditing #{host}:#{port} db:#{db} sampling #{sample_size} keys"
auditor.audit_keys
auditor.output_stats