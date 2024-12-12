require_relative "../helper"
require "inspec-podman-resources/resources/podman_image"

describe PodmanImage do

  let(:inspec_mock) { mock("inspec") }
  let(:conf_path) { File.join(Dir.pwd, "test/fixtures/podman-inspect-info") }
  let(:error_message) { File.join(Dir.pwd, "test/fixtures/podman-errors") }
  let(:mock_file) { mock("file") }
  let(:podman_mock) { mock("podman") } # Mock Podman client
  let(:os_mock) { mock("os") }

  before do
    mock_file.stubs(:file?).returns(true) # Stub the file? method to return true
    mock_file.stubs(:content).returns(File.read(conf_path)) # Stub the content method to return the content of the file
    inspec_mock.stubs(:file).with(conf_path).returns(mock_file) # Stub the inspec.file method to return the mock file object

    inspec_mock.stubs(:podman).returns(mock("podman").tap do |podman_mock|
      podman_mock.stubs(:conf_path).returns(conf_path)
    end)

    os_mock.stubs(:unix?).returns(true) # Ensure os.unix? returns true
    inspec_mock.stubs(:os).returns(os_mock)

    inspec_mock.stubs(:command).with("podman version").returns(mock("podman_version").tap do |cmd|
      cmd.stubs(:exit_status).returns(0)
      cmd.stubs(:stdout).returns("4.0.0")
    end)

    inspec_mock.stubs(:command).with("podman image inspect docker.io/library/busybox:latest --format '{\"id\": {{json .ID}}, \"repo_tags\": {{json .RepoTags}}, \"size\": {{json .Size}}, \"digest\": {{json .Digest}}, \"created_at\": {{json .Created}}, \"version\": {{json .Version}}, \"names_history\": {{json .NamesHistory}}, \"repo_digests\": {{json .RepoDigests}}, \"architecture\": {{json .Architecture}}, \"os\": {{json .Os}}, \"virtual_size\": {{json .VirtualSize}}}'").returns(mock("podman_image_results").tap do |cmd|
      cmd.stubs(:exit_status).returns(0)
      cmd.stubs(:stdout).returns(File.read(conf_path))
    end)

    inspec_mock.stubs(:command).with("podman image inspect not-exist:latest --format '{\"id\": {{json .ID}}, \"repo_tags\": {{json .RepoTags}}, \"size\": {{json .Size}}, \"digest\": {{json .Digest}}, \"created_at\": {{json .Created}}, \"version\": {{json .Version}}, \"names_history\": {{json .NamesHistory}}, \"repo_digests\": {{json .RepoDigests}}, \"architecture\": {{json .Architecture}}, \"os\": {{json .Os}}, \"virtual_size\": {{json .VirtualSize}}}'").returns(mock("podman_error").tap do |cmd|
      cmd.stubs(:exit_status).returns(0)
      cmd.stubs(:stdout).returns(File.read(error_message))
    end)

    # Stub the inspec methods to return the inspec_mock
    PodmanImage.any_instance.stubs(:inspec).returns(inspec_mock)
  end

  it "test podman image properties and matchers" do
    resource = PodmanImage.new("docker.io/library/busybox:latest")
    _(resource.exist?).must_equal true
    _(resource.id).must_equal "3c19bafed22355e11a608c4b613d87d06b9cdd37d378e6e0176cbc8e7144d5c6"
    _(resource.repo_tags).must_include "docker.io/library/busybox:latest"
    _(resource.created_at).must_equal "2022-06-08T00:39:28.175020858Z"
    _(resource.version).must_equal "20.10.12"
    _(resource.size).must_equal 1636053
    _(resource.digest).must_equal "sha256:3614ca5eacf0a3a1bcc361c939202a974b4902b9334ff36eb29ffe9011aaad83"
    _(resource.names_history).must_include "docker.io/library/busybox:latest"
    _(resource.repo_digests).must_include "docker.io/library/busybox@sha256:2c5e2045f35086c019e80c86880fd5b7c7a619878b59e3b7592711e1781df51a"
    _(resource.architecture).must_equal "arm64"
    _(resource.os).must_equal "linux"
    _(resource.virtual_size).must_equal 1636053
    _(resource.resource_id).must_equal "docker.io/library/busybox:latest"
    _(resource.to_s).must_equal "podman_image docker.io/library/busybox:latest"
  end

  it "test for a non-existing container image" do
    resource = PodmanImage.new("not-exist:latest")
    _(resource.exist?).must_equal false
    assert_nil resource.repo_tags
    assert_nil resource.size
    assert_nil resource.digest
    assert_nil resource.names_history
    assert_nil resource.os
    assert_nil resource.virtual_size
    assert_nil resource.architecture
    assert_nil resource.repo_digests
  end
  it "raises an exception when Podman is not running" do
    PodmanImage.any_instance.stubs(:podman_running?).returns(false)

    assert_raises(Inspec::Exceptions::ResourceFailed, "Podman is not running. Please make sure it is installed and running.") do
      PodmanImage.new("docker.io/library/busybox:latest")
    end
  end
end
