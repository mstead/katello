#
# Copyright 2014 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

require 'katello_test_helper'
require 'mocha/setup'

module Katello
class GlueCandlepinProviderTestBase < ActiveSupport::TestCase

  def self.before_suite
    @loaded_fixtures = load_fixtures

    services  = ['Pulp', 'ElasticSearch', 'Foreman']
    models    = ['User', 'KTEnvironment', 'Organization', 'Product']
    disable_glue_layers(services, models)

    User.current = User.find(@loaded_fixtures['users']['admin']['id'])
    VCR.insert_cassette('glue_candlepin_provider', :match_requests_on => [:path, :params, :method, :body_json])

    @@dev      = KTEnvironment.find(@loaded_fixtures['katello_environments']['candlepin_dev']['id'])
    @@org      = Organization.find(@loaded_fixtures['taxonomies']['organization2']['id'])
    @@provider = Provider.find(@loaded_fixtures['katello_providers']['candlepin_redhat']['id'])

    CandlepinOwnerSupport.set_owner(@@org)
  end

  def self.after_suite
    Resources::Candlepin::Owner.destroy(@@org.label)
  ensure
    VCR.eject_cassette
  end

end

class GlueCandlepinProviderTestImport < GlueCandlepinProviderTestBase

  def self.before_suite
    super
  end

  def self.after_suite
    super
  end

  def setup
    super
  end

  def test_manifest_import
    skip "Need testable manifests"

    # Import the newest org1 manifest - should work
    manifest = 'minitest-org1-v2'
    VCR.use_cassette("support/candlepin/provider_#{manifest}", :match_requests_on => [:path, :params, :method]) do
      @@provider.queue_import_manifest(:zip_file_path=>"test/fixtures/manifests/#{manifest}.zip")
    end

    # Import the older org1 manifest - should fail
    manifest = 'minitest-org1-v1'
    VCR.use_cassette("support/candlepin/provider_#{manifest}", :match_requests_on => [:path, :params, :method]) do
      assert_raises(RestClient::Conflict) do
        @@provider.queue_import_manifest(:zip_file_path=>"test/fixtures/manifests/#{manifest}.zip")
      end
    end

    # Import different org2 manifest - should fail
    manifest = 'minitest-org2-v1'
    VCR.use_cassette("support/candlepin/provider_#{manifest}", :match_requests_on => [:path, :params, :method]) do
      @@provider.queue_import_manifest(:zip_file_path=>"test/fixtures/manifests/#{manifest}.zip")
    end

    manifest = 'minitest-org1-v2'
    VCR.use_cassette("support/candlepin/provider_#{manifest}", :match_requests_on => [:path, :params, :method]) do
      @@provider.queue_delete_manifest
    end

  end

end

class GlueCandlepinProviderTestDelete < GlueCandlepinProviderTestBase

  #until we can import a fake manifest into candlepin, this the best we can do
  def test_manifest_delete
    @@provider.stubs(:index_subscriptions).returns(true)
    Resources::Candlepin::Owner.stubs(:pools).returns([])
    Resources::Candlepin::Owner.stubs(:destroy_imports).with(@@provider.organization.label, true).returns(true)
    @@provider.delete_manifest
  end
end
end
