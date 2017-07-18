build_configurations = [
	{
		:scheme => "Conduit-iOS",
		:run_tests => true,
		:destinations => [
			"OS=9.0,name=iPhone 6",
			"OS=10.0,name=iPhone 7 Plus"
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
			"OS=10.0,name=Apple TV 1080p",
			"OS=9.0,name=Apple TV 1080p"
		]
	},
	{
		:scheme => "Conduit-watchOS",
		:run_tests => true,
		:destinations => [
			"OS=10.0,name=Apple TV 1080p",
			"OS=9.0,name=Apple TV 1080p"
		]
	}
]

desc "Build all targets"
task :build do
	build_configurations.each do |config|
		scheme = config[:scheme]
		destinations = config[:destinations]
		destinations.each do |destination|
			system("set -o pipefail && xcodebuild -scheme '#{scheme}'  -configuration Debug -destination '#{destination}' build | xcpretty") || exit(1)
		end
	end
end

desc "Run all unit tests on all platforms"
task :test do
	`./Tests/ConduitTests/start-test-webserver`
	system("swift test") || exit(1)
	`./Tests/ConduitTests/stop-test-webserver`
	build_configurations.each do |config|
		next if !config[:run_tests]
		scheme = config[:scheme]
		destinations = config[:destinations]
		destinations.each do |destination|
			system("set -o pipefail && xcodebuild -scheme #{scheme} -configuration Debug -destination '#{destination}' test | xcpretty") || exit(1)
		end
	end
end

desc "Clean all builds"
task :clean do
  system("set -o pipefail && xcodebuild -scheme #{$framework}-iOS -configuration Debug clean | xcpretty") || exit(1)
  system("set -o pipefail && xcodebuild -scheme #{$framework}-tvOS -configuration Debug clean | xcpretty") || exit(1)
  system("set -o pipefail && xcodebuild -scheme #{$framework}-macOS -configuration Debug clean | xcpretty") || exit(1)
  system("set -o pipefail && xcodebuild -scheme #{$framework}-watchOS -configuration Debug clean | xcpretty") || exit(1)
end

task :default => "test"
