
# Import MINDBODY Rakefile tools
github_token = ENV["GITHUB_ACCESS_TOKEN"]
eval `curl -s https://#{github_token}:x-oauth-basic@raw.githubusercontent.com/mindbody/ruby-tools/master/frameworks/rakefile.rb`

# Configuration
$framework = "Conduit"

# Overrides

def test_all_schemes
  `./Tests/ConduitTests/start-test-webserver`
  test_spm if swift_package_manager
  build_matrix.each do |config|
    test_platform config
  end
  `./Tests/ConduitTests/stop-test-webserver`
end

