$framework = "MBOAuthKit"

desc "Build all targets"
task :build do
  system("set -o pipefail && xcodebuild -scheme #{$framework}-iOS -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 6,OS=latest' build | xcpretty") || exit(1)
  system("set -o pipefail && xcodebuild -scheme #{$framework}-tvOS -configuration Debug -destination 'platform=tvOS Simulator,name=Apple TV 1080p,OS=latest' build | xcpretty") || exit(1)
  system("set -o pipefail && xcodebuild -scheme #{$framework}-macOS -configuration Debug -destination 'platform=OS X,arch=x86_64' build | xcpretty") || exit(1)
  system("set -o pipefail && xcodebuild -scheme #{$framework}-watchOS -configuration Debug -destination 'platform=watchOS Simulator,name=Apple Watch - 42mm,OS=latest' build | xcpretty") || exit(1)
end

desc "Run all unit tests on iPhone 6, latest iOS"
task :test do
  system("set -o pipefail && xcodebuild -scheme #{$framework}-iOS -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 6,OS=latest' test | xcpretty") || exit(1)
  system("set -o pipefail && xcodebuild -scheme #{$framework}-tvOS -configuration Debug -destination 'platform=tvOS Simulator,name=Apple TV 1080p,OS=latest' test | xcpretty") || exit(1)
  system("set -o pipefail && xcodebuild -scheme #{$framework}-macOS -configuration Debug -destination 'platform=OS X,arch=x86_64' test | xcpretty") || exit(1)
  #system("xcodebuild -scheme #{$framework}-watchOS -configuration Debug -destination 'platform=watchOS Simulator,name=Apple Watch - 42mm,OS=latest' test | xcpretty") || exit(1)
end

desc "Clean all builds"
task :clean do
  system("set -o pipefail && xcodebuild -scheme #{$framework}-iOS -configuration Debug clean | xcpretty") || exit(1)
  system("set -o pipefail && xcodebuild -scheme #{$framework}-tvOS -configuration Debug clean | xcpretty") || exit(1)
  system("set -o pipefail && xcodebuild -scheme #{$framework}-macOS -configuration Debug clean | xcpretty") || exit(1)
  system("set -o pipefail && xcodebuild -scheme #{$framework}-watchOS -configuration Debug clean | xcpretty") || exit(1)
end

task :default => "test"
