require_relative "../helper"
require "inspec-podman-resources/resources/podman_container"

describe PodmanContainer do
  let(:inspec_mock) { mock("inspec") }
  let(:conf_path) { File.join(Dir.pwd, "test/fixtures/podman-ps-a") }
  let(:mock_file) { mock("file") }
  let(:podman_mock) { mock("podman") } # Mock Podman client
  let(:os_mock) { mock("os") }

  before do
    mock_file.stubs(:file?).returns(true) # Stub the file? method to return true
    mock_file.stubs(:content).returns(File.read(conf_path)) # Stub the content method to return the content of the file
    inspec_mock.stubs(:file).with(conf_path).returns(mock_file) # Stub the inspec.file method to return the mock file object
    os_mock.stubs(:unix?).returns(true) # Ensure os.unix? returns true
    inspec_mock.stubs(:os).returns(os_mock)
    inspec_mock.stubs(:podman).returns(podman_mock)
    inspec_mock.stubs(:command).with("podman ps -a --no-trunc --size --format '{\"ID\": {{json .ID}}, \"Image\": {{json .Image}}, \"ImageID\": {{json .ImageID}}, \"Command\": {{json .Command}}, \"CreatedAt\": {{json .CreatedAt}}, \"RunningFor\": {{json .RunningFor}}, \"Status\": {{json .Status}}, \"Pod\": {{json .Pod}}, \"Ports\": {{json .Ports}}, \"Size\": {{json .Size}}, \"Names\": {{json .Names}}, \"Networks\": {{json .Networks}}, \"Labels\": {{json .Labels}}, \"Mounts\": {{json .Mounts}}}'").returns(mock("podmand_ps_a").tap do |cmd|
      cmd.stubs(:exit_status).returns(0)
      cmd.stubs(:stdout).returns(File.read("test/fixtures/podman-ps-a"))
    end)
    object_info_mock = mock("object_info")
    object_info_mock.stubs(:entries).returns([1]) # Simulate a single entry
    object_info_mock.stubs(:status).returns(["Up 13 hours ago"])
    object_info_mock.stubs(:labels).returns([{ "maintainer" => "NGINX Docker Maintainers <docker-maint@nginx.com>" }])
    object_info_mock.stubs(:commands).returns(["/bin/bash"])
    object_info_mock.stubs(:images).returns(["docker.io/library/nginx:latest"])
    object_info_mock.stubs(:ids).returns(["591270d8d80d26671fd6ed622f367fbe19004d16e3b519c292313feb5f22e7f7"])
    object_info_mock.stubs(:ports).returns([""])
    object_info_mock.stubs(:exists?).returns(true)

    PodmanContainer.any_instance.stubs(:object_info).returns(object_info_mock)

    PodmanContainer.any_instance.stubs(:inspec).returns(inspec_mock) # Stub the inspec methods to return the inspec_mock

  end

  it "checks container parsing" do
    resource = PodmanContainer.new({ "name": "sweet_mendeleev", "command": "/bin/bash" })
    _(resource.exist?).must_equal true
    _(resource.command).must_equal "/bin/bash"
    _(resource.status).must_equal "Up 13 hours ago"
    _(resource.running?).must_equal true
    _(resource.labels).must_include("maintainer" => "NGINX Docker Maintainers <docker-maint@nginx.com>")
    _(resource.image).must_equal "docker.io/library/nginx:latest"
    _(resource.ports).must_equal ""
  end

  it "prints as a podman resource" do
    resource = PodmanContainer.new("sweet_mendeleev")
    _(resource.to_s).must_equal "Podman Container sweet_mendeleev"
  end

  it "prints the resource id of the current resource" do
    resource = PodmanContainer.new("sweet_mendeleev")
    _(resource.resource_id).must_equal "591270d8d80d26671fd6ed622f367fbe19004d16e3b519c292313feb5f22e7f7"
  end
end
