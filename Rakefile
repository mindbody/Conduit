build_configurations = [
	{
		:scheme => "Conduit-iOS",
		:run_tests => true,
		:destinations => [
			"OS=9.3,name=iPhone 5S",
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
			"OS=9.2,name=Apple TV 1080p",
			"OS=latest,name=Apple TV 4K"
		]
	},
	{
		:scheme => "Conduit-watchOS",
		:run_tests => false,
		:destinations => [
			"OS=latest,name=Apple Watch - 42mm"
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

def bash_exec(command)
	command_strict = "set -o pipefail && #{command}"
	puts "> #{command_strict}"
	system(command_strict) || exit(1)
end

desc "Build all targets"
task :build do
	build_configurations.each do |config|
		scheme = config[:scheme]
		destinations = config[:destinations]
		destinations.each do |destination|
			bash_exec("xcodebuild -workspace Conduit.xcworkspace -scheme '#{scheme}' -destination '#{destination}' -configuration Debug build | xcpretty")
		end
	end
end

desc "Run all unit tests on all platforms"
task :test do
	`./Tests/ConduitTests/start-test-webserver`
	bash_exec("swift test")
	build_configurations.each do |config|
		scheme = config[:scheme]
		destinations = config[:destinations]
		first_destination = destinations[0]
		if !config[:run_tests]
			bash_exec("set -o pipefail && xcodebuild -workspace Conduit.xcworkspace -scheme '#{scheme}' -destination '#{first_destination}' -configuration Debug build | xcpretty")
			next
		end
		# Binaries don't need to be recompiled for per version of each OS
		bash_exec("set -o pipefail && xcodebuild -workspace Conduit.xcworkspace -scheme '#{scheme}' -destination '#{first_destination}' -configuration Debug build-for-testing | xcpretty")
		destinations.each do |destination|
			bash_exec("set -o pipefail && xcodebuild -workspace Conduit.xcworkspace -scheme #{scheme} -configuration Debug -destination '#{destination}' test-without-building | xcpretty")
		end
	end
	`./Tests/ConduitTests/stop-test-webserver`
end

desc "Clean all builds"
task :clean do
	`swift package reset`
	build_configurations.each do |config|
		scheme =  config[:scheme]
		bash_exec("set -o pipefail && xcodebuild -workspace Conduit.xcworkspace -scheme #{scheme} -configuration Debug clean | xcpretty")
	end
end
