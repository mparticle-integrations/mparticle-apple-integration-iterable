Pod::Spec.new do |s|
    s.name             = "mParticle-Iterable"
    s.version          = "8.3.0"
    s.summary          = "Iterable integration for mParticle"

    s.description      = "This is the Iterable integration for mParticle."

    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-iterable.git", :tag => "v" + s.version.to_s }
    s.social_media_url = "https://twitter.com/mparticle"

    s.ios.deployment_target = "11.0"
    s.ios.source_files      = 'mParticle-Iterable/*.{h,m,mm}'
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.0'
    s.ios.dependency 'Iterable-iOS-SDK', '~> 6.2'
end
