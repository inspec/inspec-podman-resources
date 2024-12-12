require_relative "../helper"
require "inspec-podman-resources/resources/podman_pod"

describe PodmanPod do
  let(:inspec_mock) { mock("inspec") }
  let(:conf_path) { File.join(Dir.pwd, "test/fixtures/podman-pod-inspect") }
  let(:error_message) { File.join(Dir.pwd, "test/fixtures/podman-errors") }
  let(:mock_file) { mock("file") }
  let(:podman_mock) { mock("podman") } # Mock Podman client
  let(:os_mock) { mock("os") }
  let(:command_mock) { mock("command") }

  before do
    mock_file.stubs(:file?).returns(true) # Stub the file? method to return true
    mock_file.stubs(:content).returns(File.read(conf_path)) # Stub the content method to return the content of the file
    inspec_mock.stubs(:file).with(conf_path).returns(mock_file) # Stub the inspec.file method to return the mock file object

    inspec_mock.stubs(:podman).returns(mock("podman").tap do |podman_mock|
      podman_mock.stubs(:conf_path).returns(conf_path)
    end)

    os_mock.stubs(:unix?).returns(true) # Ensure os.unix? returns true
    inspec_mock.stubs(:os).returns(os_mock)

    inspec_mock.stubs(:command).with("podman pod inspect nginx-frontend --format '{\"id\": {{json .ID}}, \"name\": {{json .Name}}, \"created_at\": {{json .Created}}, \"create_command\": {{json .CreateCommand}}, \"state\": {{json .State}}, \"hostname\": {{json .Hostname}}, \"create_cgroup\": {{json .CreateCgroup}}, \"cgroup_parent\": {{json .CgroupParent}}, \"cgroup_path\": {{json .CgroupPath}}, \"create_infra\": {{json .CreateInfra}}, \"infra_container_id\": {{json .InfraContainerID}}, \"infra_config\": {{json .InfraConfig}}, \"shared_namespaces\": {{json .SharedNamespaces}}, \"num_containers\": {{json .NumContainers}}, \"containers\": {{json .Containers}}}'").returns(mock("podman_success_results").tap do |cmd|
      cmd.stubs(:exit_status).returns(0)
      cmd.stubs(:stdout).returns(File.read(conf_path))
    end)
    inspec_mock.stubs(:command).with("podman version").returns(mock("podman_version").tap do |cmd|
      cmd.stubs(:exit_status).returns(0)
      cmd.stubs(:stdout).returns("4.0.0")
    end)
    inspec_mock.stubs(:command).with("podman pod inspect non_existing_pod --format '{\"id\": {{json .ID}}, \"name\": {{json .Name}}, \"created_at\": {{json .Created}}, \"create_command\": {{json .CreateCommand}}, \"state\": {{json .State}}, \"hostname\": {{json .Hostname}}, \"create_cgroup\": {{json .CreateCgroup}}, \"cgroup_parent\": {{json .CgroupParent}}, \"cgroup_path\": {{json .CgroupPath}}, \"create_infra\": {{json .CreateInfra}}, \"infra_container_id\": {{json .InfraContainerID}}, \"infra_config\": {{json .InfraConfig}}, \"shared_namespaces\": {{json .SharedNamespaces}}, \"num_containers\": {{json .NumContainers}}, \"containers\": {{json .Containers}}}'").returns(mock("podman_pod_inspect_failure").tap do |cmd|
      cmd.stubs(:exit_status).returns(0)
      cmd.stubs(:stdout).returns(File.read(error_message))
    end)

    PodmanPod.any_instance.stubs(:inspec).returns(inspec_mock) # Stub the inspec methods to return the inspec_mock
  end

  it "checks podman pod parameter and works correctly" do
    resource = PodmanPod.new("nginx-frontend")
    _(resource.exist?).must_equal true
    _(resource.id).must_equal "fcfe4d471cfface0d1b39bce23af7d31ab8736cd68c0360ade0b4afe364f79d4"
    _(resource.name).must_equal "nginx-frontend"
    _(resource.created_at).must_equal "2022-07-14T15:47:47.978078124+05:30"
    _(resource.create_command).must_include "new:nginx-frontend"
    _(resource.create_command).must_include "podman"
    _(resource.state).must_equal "Running"
    _(resource.hostname).must_equal ""
    _(resource.create_cgroup).must_equal true
    _(resource.cgroup_parent).must_equal "user.slice"
    _(resource.cgroup_path).must_equal "user.slice/user-libpod_pod_fcfe4d471cfface0d1b39bce23af7d31ab8736cd68c0360ade0b4afe364f79d4.slice"
    _(resource.create_infra).must_equal true
    _(resource.infra_container_id).must_equal "727538044b32a165934729dc2d47d9d5e981b6496aebfad7de470f7e76ea4251"
    _(resource.infra_config).must_include "DNSOption"
    _(resource.shared_namespaces).must_include "net"
    _(resource.shared_namespaces).must_include "ipc"
    _(resource.num_containers).must_equal 2
    _(resource.containers).must_be_kind_of Array
    _(resource.resource_id).must_equal "nginx-frontend"
    _(resource.to_s).must_equal "Podman Pod nginx-frontend"
  end

  it "checks for a non-existing podman pod" do
    resource = PodmanPod.new("non_existing_pod")
    _(resource.exist?).must_equal false
    assert_nil resource.name
    assert_nil resource.created_at
    assert_nil resource.create_command
    assert_nil resource.state
    assert_nil resource.hostname
    assert_nil resource.create_cgroup
    assert_nil resource.cgroup_parent
    assert_nil resource.cgroup_path
    assert_nil resource.create_infra
    assert_nil resource.infra_container_id
    assert_nil resource.infra_config
    assert_nil resource.shared_namespaces
    assert_nil resource.num_containers
    assert_nil resource.containers
    _(resource.resource_id).must_equal "non_existing_pod"
    _(resource.to_s).must_equal "Podman Pod non_existing_pod"
  end
end
