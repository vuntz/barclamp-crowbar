# Copyright 2011-2013, Dell
# Copyright 2013, SUSE LINUX Products GmbH
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
# Author: Dell Crowbar Team
# Author: SUSE LINUX Products GmbH
#

module CrowbarUpgrade
  require "chef"

  def self.run_pre
    deactivate_proposals
    set_nodes_to_upgrading_state
  end

  def self.run
    # handle quantum -> neutron renaming
    # ssh on nodes and stop services
    # ssh on nodes and change repos (or have this done by a recipe in provisioner-base?)
  end

  def self.run_post
    # set nodes to ready
    # reboot nodes
    # reactivate_proposals
  end

  private

  def self.deactivate_proposals
    service_object = ServiceObject.new logger

    ServiceObject.barclamp_catalog["barclamps"].each do |bc_name, details|
      next unless %w(database rabbitmq keystone ceph swift glance cinder quantum neutron nova nova_dashboard ceilometer heat).include? bc_name

      props = ProposalObject.find_proposals bc_name
      service_object.bc_name = bc_name

      props.each do |prop|
        begin
          ret = service_object.destroy_active(prop)
          # TODO: remember for which we get a 200, so we can re-enable these later on
          unless [200, 404].include? ret[0]
            raise "Failed to deactivate proposal #{prop} for #{bc_name}: #{ret[1]}"
          end
        rescue StandardError => e
          raise "Failed to deactivate proposal #{prop} for #{bc_name}: #{e.message}"
        end
      end
    end
  end

  def self.set_nodes_to_upgrading_state
    cb = CrowbarService.new Rails.logger
    NodeObject.all.each do |node|
      ret = cb.transition "default", node.name, "upgrading"
      unless [200, 404].include? ret[0]
        raise "Failed to change state of #{node.name} to upgrading: #{ret[1]}"
      end
    end
  end

end
