# Copyright 2014, SUSE
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'fileutils'

def suse_file
  "/etc/sysconfig/SuSEfirewall2"
end

def suse_init
  @suse_keys = {
    "FW_SERVICES_EXT_RPC" => [],
    "FW_SERVICES_EXT_TCP" => [],
    "FW_SERVICES_EXT_UDP" => [],
    "FW_CONFIGURATIONS_EXT" => []
  }
  if File.exist? suse_file
    contents = File.new(suse_file).readlines
    contents.each do |line|
      @suse_keys.keys.each do |key|
        if line.start_with? "#{key}="
          value = line[/^[^=]*="(.*)"/, 1] || ""
          @suse_keys[key] = value.split(" ")
          break
        end
      end
    end
  end
end

def suse_save
  written = {}
  @suse_keys.keys.each do |key|
    written[key] = false
  end

  if File.exist? suse_file
    contents = File.new(suse_file).readlines
  end

  File.open(suse_file, "w") do |newfile|
    contents.each do |line|
      write_line = true
      @suse_keys.keys.each do |key|
        if line.start_with? "#{key}="
          newfile.puts "#{key}=\"#{@suse_keys[key].join(" ")}\""
          write_line = false
          written[key] = true
          break
        end
      end
      newfile.puts(line) if write_line
    end

    @suse_keys.keys.each do |key|
      unless written[key]
        newfile.puts "#{key}=\"#{@suse_keys[key].join(" ")}\""
      end
    end

    newfile.flush
  end
end

def suse_find_key(protocol, service)
  if service == "nfs"
    "FW_SERVICES_EXT_RPC"
  elsif protocol == "tcp"
    "FW_SERVICES_EXT_TCP"
  elsif protocol == "udp"
    "FW_SERVICES_EXT_UDP"
  else
    "FW_CONFIGURATIONS_EXT"
  end
end

def suse_open(protocol, port, service)
  key = suse_find_key(protocol, service)
  if service.nil?
    @suse_keys[key] << port
  else
    @suse_keys[key] << service
  end
end

def suse_close(protocol, port, service)
  key = suse_find_key(protocol, service)
  if service.nil?
    @suse_keys[key].delete(port)
  else
    @suse_keys[key].delete(service)
  end
end

def validate_attr(protocol, port, service)
  if service.nil?
    raise "Missing protocol!" if protocol.nil?
    raise "Missing port!" if port.nil?

    if protocol.is_a? Array
      protocol.each do |proto|
        unless %w{tcp udp}.include? proto
          raise "Invalid value in protocols: #{proto} (valid values: tcp, udp)"
        end
      end
    elsif protocol.is_a? String
      unless %w{tcp udp}.include? protocol
        raise "Invalid protocol value: #{protocol} (valid values: tcp, udp)"
      end
    else
      raise "Unhandled class for protocol: #{protocol.class}"
    end
  else
    raise "Cannot define both protocol and service" unless protocol.nil?
    raise "Cannot define both port and service" unless port.nil?
  end
end

action :open do
  updated = false
  protocol = @new_resource.protocol
  port = @new_resource.port
  service = @new_resource.service
  @updated = false

  validate_attr(protocol, port, service)

  if platform?("suse")
    suse_init 

    if protocol.class == Array
      protocol.each do |proto|
        suse_open(proto, port, service)
      end
    else
      suse_open(protocol, port, service)
    end

    suse_save
  end

  @new_resource.updated_by_last_action(true) if @updated
end

action :close do
  updated = false
  protocol = @new_resource.protocol
  port = @new_resource.port
  service = @new_resource.service
  @updated = false

  if platform?("suse")
    suse_init 

    if protocol.class == Array
      protocol.each do |proto|
        suse_close(proto, port, service)
      end
    else
      suse_close(protocol, port, service)
    end

    suse_save
  end

  @new_resource.updated_by_last_action(true) if @updated
end
