Pod::Spec.new do |s|
  s.name         = "SentryCrashPatch"
  s.version      = "0.0.1"
  s.summary      = "补丁用于修复Sentry中的C++异常监控问题"
  s.description  = <<-DESC
                  这个Pod提供一个修复，解决macOS最新SDK中的某些C++功能与Sentry的兼容性问题
                   DESC
  s.homepage     = "https://example.com"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Author" => "author@example.com" }
  s.source       = { :path => '.' }
  s.source_files = "*.{h,c,cpp}"
  s.public_header_files = "*.h"
  s.requires_arc = true
end 