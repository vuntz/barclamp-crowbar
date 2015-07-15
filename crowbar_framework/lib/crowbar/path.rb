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

module Crowbar
  class Path

    def self.libdir
      @@libdir ||= begin
        if Rails.env.production?
          paths = ["/usr/lib/crowbar", "/opt/dell/bin", Rails.root.join("..", "bin")]
        else
          paths = [Rails.root.join("..", "bin"), "/usr/lib/crowbar", "/opt/dell/bin"]
        end

        libdir = paths.find { |dir| File.directory?(dir) }
        Pathname.new(libdir) unless libdir.nil?
      end
    end

    def self.chef_datadir
      @@chef_datadir ||= begin
        if Rails.env.production?
          paths = ["/usr/share/crowbar/chef", "/opt/dell/chef", Rails.root.join("..", "chef")]
        else
          paths = [Rails.root.join("..", "chef"), "/usr/share/crowbar/chef", "/opt/dell/chef"]
        end

        chef_datadir = paths.find { |dir| File.directory?(dir) }
        Pathname.new(chef_datadir) unless chef_datadir.nil?
      end
    end

  end
end
