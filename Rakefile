build_configurations = [
	{
		:scheme => "Conduit-iOS",
		:run_tests => true,
		:destinations => [
			"OS=latest,name=iPhone X"
		]
	},
	{
		:scheme => "Conduit-macOS",
		:run_tests => true,
		:destinations => [
			"platform=OS X,arch=x86_64"
		]
	},
	{
		:scheme => "Conduit-tvOS",
		:run_tests => true,
		:destinations => [
			"OS=latest,name=Apple TV 4K"
		]
	},
	{
		:scheme => "Conduit-watchOS",
		:run_tests => false,
		:destinations => [
			"OS=latest,name=Apple Watch Series 5 - 40mm"
		]
	},
	{
		:scheme => "ConduitExampleIOS",
		:run_tests => false,
		:destinations => [
			"OS=latest,name=iPhone X"
		]
	}
]

desc "Build all targets"
task :build do
  build_configurations.each do |config|
    scheme = config[:scheme]
    destinations = config[:destinations].map { |destination| "-destination '#{destination}'" }.join(" ")
    execute "xcodebuild -workspace Conduit.xcworkspace -scheme #{scheme} #{destinations} -configuration Debug -quiet build analyze"
  end
end

desc "Run all unit tests on all platforms"
task :test do
  `./Tests/ConduitTests/start-test-webserver`
  execute "swift test --parallel"
  build_configurations.each do |config|
    scheme = config[:scheme]
    destinations = config[:destinations].map { |destination| "-destination '#{destination}'" }.join(" ")

    if config[:run_tests] then
      execute "set -o pipefail && xcodebuild -workspace Conduit.xcworkspace -scheme #{scheme} #{destinations} -configuration Debug -quiet build-for-testing analyze"
      execute "set -o pipefail && xcodebuild -workspace Conduit.xcworkspace -scheme #{scheme} #{destinations} -configuration Debug -quiet -disable-concurrent-destination-testing test-without-building"
    else
      execute "set -o pipefail && xcodebuild -workspace Conduit.xcworkspace -scheme #{scheme} #{destinations} -configuration Debug -quiet build analyze"
    end
  end
  `./Tests/ConduitTests/stop-test-webserver`
end

desc "Clean all builds"
task :clean do
  `swift package reset`
  build_configurations.each do |config|
    scheme = config[:scheme]
    execute "set -o pipefail && xcodebuild -workspace Conduit.xcworkspace -scheme #{scheme} -configuration Debug -quiet clean"
  end
end

def execute(command)
  puts "\n\e[36m======== EXECUTE: #{command} ========\e[39m\n"
  system("set -o pipefail && #{command}") || exit(-1)
end

