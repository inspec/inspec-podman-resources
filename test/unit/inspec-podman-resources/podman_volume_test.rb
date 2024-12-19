require_relative "../helper"
require "inspec-podman-resources/resources/podman_volume"

describe PodmanVolume do

  let(:inspec_mock) { mock("inspec") }
  let(:conf_path) { File.join(Dir.pwd, "test/fixtures/podman-volume-inspect") }
  let(:error_message) { File.join(Dir.pwd, "test/fixtures/podman-errors") }
  let(:mock_file) { mock("file") }
  let(:podman_mock) { mock("podman") } # Mock Podman client

  before do
    mock_file.stubs(:file?).returns(true) # Stub the file? method to return true
    mock_file.stubs(:content).returns(File.read(conf_path)) # Stub the content method to return the content of the file
    inspec_mock.stubs(:file).with(conf_path).returns(mock_file) # Stub the inspec.file method to return the mock file object

    inspec_mock.stubs(:podman).returns(mock("podman").tap do |podman_mock|
      podman_mock.stubs(:conf_path).returns(conf_path)
    end)
    inspec_mock.stubs(:command).with("podman version").returns(mock("podman_version").tap do |cmd|
      cmd.stubs(:exit_status).returns(0)
      cmd.stubs(:stdout).returns("4.0.0")
    end)

    inspec_mock.stubs(:os).returns(mock("os").tap do |os_mock|
      os_mock.stubs(:unix?).returns(true)
    end)
    inspec_mock.stubs(:command).with("podman volume inspect my_volume --format '{\"name\": {{json .Name}}, \"driver\": {{json .Driver}}, \"mountpoint\": {{json .Mountpoint}}, \"created_at\": {{json .CreatedAt}}, \"labels\": {{json .Labels}}, \"scope\": {{json .Scope}}, \"options\": {{json .Options}}, \"mount_count\": {{json .MountCount}}, \"needs_copy_up\": {{json .NeedsCopyUp}}, \"needs_chown\": {{json .NeedsChown}}}'").returns(mock("command").tap do |command_mock|
      command_mock.stubs(:exit_status).returns(0)
      command_mock.stubs(:stdout).returns(File.read(conf_path))
    end)
    inspec_mock.stubs(:command).with("podman volume inspect non_existing_volume --format '{\"name\": {{json .Name}}, \"driver\": {{json .Driver}}, \"mountpoint\": {{json .Mountpoint}}, \"created_at\": {{json .CreatedAt}}, \"labels\": {{json .Labels}}, \"scope\": {{json .Scope}}, \"options\": {{json .Options}}, \"mount_count\": {{json .MountCount}}, \"needs_copy_up\": {{json .NeedsCopyUp}}, \"needs_chown\": {{json .NeedsChown}}}'").returns(mock("command").tap do |command_mock|
      command_mock.stubs(:exit_status).returns(0)
      command_mock.stubs(:stdout).returns(File.read(error_message))
    end)
    PodmanVolume.any_instance.stubs(:inspec).returns(inspec_mock) # Stub the inspec methods to return the inspec_mock
  end

  it "checks podman volume parameter and works correctly" do
    resource = PodmanVolume.new("my_volume")
    _(resource.exist?).must_equal true
    _(resource.name).must_equal "my_volume"
    _(resource.driver).must_equal "local"
    _(resource.mountpoint).must_equal "/var/home/core/.local/share/containers/storage/volumes/my_volume/_data"
    _(resource.created_at).must_equal "2022-07-14T13:21:19.965421792+05:30"
    _(resource.labels).must_equal({})
    _(resource.scope).must_equal "local"
    _(resource.options).must_equal({})
    _(resource.mount_count).must_equal 0
    _(resource.needs_copy_up).must_equal true
    _(resource.needs_chown).must_equal true
    _(resource.resource_id).must_equal "my_volume"
    _(resource.to_s).must_equal "podman_volume my_volume"
  end

  it "checks for a non-existing podman volume" do
    resource = PodmanVolume.new("non_existing_volume")
    _(resource.exist?).must_equal false
    assert_nil resource.name
    assert_nil resource.driver
    assert_nil resource.mountpoint
    assert_nil resource.created_at
    assert_nil resource.labels
    assert_nil resource.scope
    assert_nil resource.options
    assert_nil resource.mount_count
    assert_nil resource.needs_copy_up
    assert_nil resource.needs_chown
    _(resource.resource_id).must_equal "non_existing_volume"
    _(resource.to_s).must_equal "podman_volume non_existing_volume"
  end
end
