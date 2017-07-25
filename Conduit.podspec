Pod::Spec.new do |spec|
	spec.name = 'Conduit'
	spec.version = '0.0.1'
	# spec.license = { :type -> 'MIT' }
	spec.homepage = 'https://github.com/mindbody/Conduit'
	spec.author = 'Conduit Contributors'
	spec.summary = 'Robust Swift networking for web APIs'
	spec.source = { :git => 'https://github.com/mindbody/Conduit.git', :tag => '0.0.1' }
	spec.source_files = 'Sources/**/*.swift'
	spec.ios.framework = 'SystemConfiguration'
	spec.tvos.framework = 'SystemConfiguration'
	spec.osx.framework = 'SystemConfiguration'
	spec.ios.deployment_target = '8.0'
	spec.watchos.deployment_target = '2.0'
	spec.tvos.deployment_target = '9.0'
	spec.osx.deployment_target = '10.10'
end