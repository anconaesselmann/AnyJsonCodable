Pod::Spec.new do |s|
  s.name             = 'AnyJsonCodable'
  s.version          = '0.1.0'
  s.summary          = 'Encode and decode unstructured JSON'
  s.swift_version = '5.0'
  s.description      = <<-DESC
Encode and decode unstructured JSON.
                       DESC
  s.homepage         = 'https://github.com/anconaesselmann/AnyJsonCodable'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'anconaesselmann' => 'axel@anconaesselmann.com' }
  s.source           = { :git => 'https://github.com/anconaesselmann/AnyJsonCodable.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'
  s.source_files = 'AnyJsonCodable/Classes/**/*'
end
