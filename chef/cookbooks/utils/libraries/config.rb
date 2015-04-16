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

module CrowbarConfig
  def self.fetch(name, category)
    db = self.load(name)
    db.fetch(category, {})
  end

  protected

  def self.load_no_cache(name)
    begin
      Chef::DataBagItem.load('crowbar', name).raw_data
    rescue Net::HTTPServerException => e
      if e.response.code == 404
        {}
      else
        raise e
      end
    end
  end

  def self.load(name)
    unless @dbs && @dbs.include?(name)
      @dbs ||= Hash.new
      @dbs[name] = self.load_no_cache(name)
    end
    @dbs[name]
  end
end
