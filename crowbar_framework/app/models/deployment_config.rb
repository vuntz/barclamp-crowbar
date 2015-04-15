#
# Copyright 2015, SUSE LINUX Products GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class DeploymentConfig
  def initialize(name, category)
    raise "Invalid config name" unless %(core ceph openstack).include? name

    begin
      @store = Chef::DataBag.load "crowbar/#{name}"
    rescue Net::HTTPServerException => e
      if e.message == '404 "Not Found"'
        @store = Chef::DataBagItem.new
        @store.data_bag "crowbar"
        @store["id"] = name
      else
        raise e
      end
    rescue Errno::ECONNREFUSED => e
      raise Crowbar::Error::ChefOffline.new
    end

    @category = category
  end

  def [](attrib)
    @store.fetch(@category, {})[attrib]
  end

  def []=(attrib, value)
    @store[@category] = {} unless @store.has_key? @category
    @store[@category][attrib] = value
  end

  def save
    @store.save
  end
end
