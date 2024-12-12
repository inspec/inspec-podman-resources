require_relative "../helper"
require "inspec-podman-resources/resources/podman_network"

describe PodmanNetwork do
  let(:inspec_mock) { mock("inspec") }
  let(:conf_path) { File.join(Dir.pwd, "test/fixtures/podman-network") }
  let(:error_message) { File.join(Dir.pwd, "test/fixtures/podman-errors") }
  let(:os_mock) { mock("os") }
  let(:mock_file) { mock("file") }
  let(:podman_mock) { mock("podman") }

  before do
    mock_file.stubs(:file?).returns(true)
    mock_file.stubs(:content).returns(File.read(conf_path))
    inspec_mock.stubs(:file).with(conf_path).returns(mock_file)

    inspec_mock.stubs(:podman).returns(mock("podman").tap do |podman_mock|
      podman_mock.stubs(:conf_path).returns(conf_path)
    end)
    os_mock.stubs(:unix?).returns(true) # Ensure os.unix? returns true
    inspec_mock.stubs(:os).returns(os_mock)

    inspec_mock.stubs(:command).with("podman version").returns(mock("podman_version").tap do |cmd|
      cmd.stubs(:exit_status).returns(0)
      cmd.stubs(:stdout).returns("4.0.0")
    end)

    inspec_mock.stubs(:command).with("podman network inspect minikube --format '{\"id\": {{json .ID}}, \"name\": {{json .Name}}, \"driver\": {{json .Driver}}, \"labels\": {{json .Labels}}, \"options\": {{json .Options}}, \"ipam_options\": {{json .IPAMOptions}}, \"internal\": {{json .Internal}}, \"created\": {{json .Created}}, \"ipv6_enabled\": {{json .IPv6Enabled}}, \"dns_enabled\": {{json .DNSEnabled}}, \"network_interface\": {{json .NetworkInterface}}, \"subnets\": {{json .Subnets}}}'").returns(mock("podman_network_success").tap do |cmd|
      cmd.stubs(:exit_status).returns(0)
      cmd.stubs(:stdout).returns(File.read(conf_path))
    end)
    inspec_mock.stubs(:command).with("podman network inspect not_exist --format '{\"id\": {{json .ID}}, \"name\": {{json .Name}}, \"driver\": {{json .Driver}}, \"labels\": {{json .Labels}}, \"options\": {{json .Options}}, \"ipam_options\": {{json .IPAMOptions}}, \"internal\": {{json .Internal}}, \"created\": {{json .Created}}, \"ipv6_enabled\": {{json .IPv6Enabled}}, \"dns_enabled\": {{json .DNSEnabled}}, \"network_interface\": {{json .NetworkInterface}}, \"subnets\": {{json .Subnets}}}'").returns(mock("podman_network_error").tap do |cmd|
      cmd.stubs(:exit_status).returns(0)
      cmd.stubs(:stdout).returns(File.read(error_message))
    end)

    PodmanNetwork.any_instance.stubs(:inspec).returns(inspec_mock)
  end

  it "test podman network properties and matchers" do
    resource = PodmanNetwork.new("minikube")
    _(resource.exist?).must_equal true
    _(resource.id).must_equal "3a7c94d937d5f3a0f1a9b1610589945aedfbe56207fd5d32fc8154aa1a8b007f"
    _(resource.name).must_equal "minikube"
    _(resource.network_interface).must_equal "podman1"
    _(resource.driver).must_equal "bridge"
    _(resource.labels).must_equal "created_by.minikube.sigs.k8s.io" => "true", "name.minikube.sigs.k8s.io" => "minikube"
    assert_nil resource.options
    _(resource.ipv6_enabled).must_equal false
    _(resource.ipam_options).must_equal "driver" => "host-local"
    _(resource.dns_enabled).must_equal true
    _(resource.subnets).must_equal [{ "subnet" => "192.168.49.0/24", "gateway" => "192.168.49.1" }]
    _(resource.internal).must_equal false
    _(resource.created).must_equal "2022-07-10T19:37:11.656610731+05:30"
    _(resource.to_s).must_equal "podman_network 3a7c94d937d5f3a0f1a9b1610589945aedfbe56207fd5d32fc8154aa1a8b007f"
    _(resource.resource_id).must_equal "3a7c94d937d5f3a0f1a9b1610589945aedfbe56207fd5d32fc8154aa1a8b007f"
  end

  it "test podman network properties and matchers for non-existent network" do
    resource = PodmanNetwork.new("not_exist")
    _(resource.exist?).must_equal false
    assert_nil resource.name
    assert_nil resource.driver
    assert_nil resource.ipv6_enabled
    assert_nil resource.dns_enabled
    assert_nil resource.options
    assert_nil resource.ipam_options
    assert_nil resource.subnets
    assert_nil resource.created
    assert_nil resource.internal
    assert_nil resource.network_interface
    assert_nil resource.labels
  end

end
