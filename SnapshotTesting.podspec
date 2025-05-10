Pod::Spec.new do |s|
    s.name             = 'SnapshotTesting'
    s.version          = '1.0.0'
    s.summary          = 'A short description of XCSnapshot.'
    s.description      = <<-DESC
  Biblioteca para testes de UI usando snapshot.
                         DESC
  
    s.homepage         = 'https://github.com/o-nnerb/swift-snapshot-testing'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Brenno' => '37243584+o-nnerb@users.noreply.github.com' }
    s.source         = { :git => 'ssh://git@github.com/o-nnerb/swift-snapshot-testing', :tag => s.version.to_s }

    s.ios.deployment_target = '14.0'
    s.swift_version = '6.0'

    s.source_files = 'Sources/SnapshotTesting/**/*.swift'

    s.resource_bundles = {
        'XCSnapshot' => [
            'Sources/SnapshotTesting/**/*.{xib,storyboard}',
            'Sources/SnapshotTesting/*/*.{xcassets,strings,strings,json}',
            'Sources/SnapshotTesting/*/*.{json,pdf,png}'
        ]
    }

    s.dependency = "XCTesting"
  end
  
