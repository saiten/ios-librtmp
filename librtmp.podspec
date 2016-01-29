Pod::Spec.new do |s| 
  s.name = 'librtmp'
  s.summary = 'librtmp for iOS'
  s.version = '2.4'
  s.authors = 'Andrej Stepanchuk', 'Howard Chu'
  s.homepage = 'https://github.com/saiten/ios-librtmp'
  s.license = { :type => 'LGPLv2', :file => 'COPYING' }
  
  
  s.source = { 
    :git => 'https://github.com/saiten/ios-librtmp.git',
  }
  s.source_files = "include/librtmp/*.h"
  s.header_dir = "librtmp"
  
  s.dependency 'OpenSSL-Universal', '~> 1.0.1k'

  s.platform = :ios, '6.0'
  s.public_header_files = "include/librtmp/*.h"
  s.vendored_libraries = "lib/librtmp.a"
  
  s.libraries = "rtmp"
  s.requires_arc = false
  
  s.xcconfig = {
    "HEADER_SEARCH_PATHS" => '"$(PODS_ROOT)/librtmp/include"'
  }
end
