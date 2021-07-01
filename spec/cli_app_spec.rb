RSpec.describe CliApp do
  it "has a version number" do
    expect(CliApp::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
