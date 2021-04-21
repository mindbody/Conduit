$version = '1.0.0'

Pod::Spec.new do |spec|
	spec.name = 'Conduit'
	spec.version = $version
	spec.license = 'Apache 2.0'
	spec.homepage = 'https://github.com/mindbody/Conduit'
	spec.author = 'Conduit Contributors'
	spec.summary = 'Robust Swift networking for web APIs'
	spec.source = { :git => 'https://github.com/mindbody/Conduit.git', :tag => $version }
	spec.source_files = 'Sources/**/*.swift'
	spec.ios.frameworks = 'Security', 'SystemConfiguration'
	spec.tvos.frameworks = 'Security', 'SystemConfiguration'
	spec.osx.frameworks = 'Security', 'SystemConfiguration'
	spec.ios.deployment_target = '9.0'
	spec.watchos.deployment_target = '2.0'
	spec.tvos.deployment_target = '9.0'
	spec.osx.deployment_target = '10.11'
end
