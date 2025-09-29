Pod::Spec.new do |s|
    s.name             = "mParticle-Iterable"
    s.version          = "8.7.1"
    s.summary          = "Iterable integration for mParticle"

    s.description      = "This is the Iterable integration for mParticle."

    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-iterable.git", :tag => "v" + s.version.to_s }
    s.social_media_url = "https://twitter.com/mparticle"

    s.ios.deployment_target = "11.0"
    s.ios.resource_bundles  = { 'mParticle-Iterable-Privacy' => ['mParticle-Iterable/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'Iterable-iOS-SDK', '~> 6.5'
    
    s.default_subspecs = "mParticleIterable"
    
        # ---- mParticleIterable ----
    s.subspec 'mParticleIterable' do |ss|
        ss.source_files = [
          'mParticle-iterable/**/*.{h,m,mm,swift}'
        ]

        ss.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.37'
    end

    # ---- NoLocation ----
    s.subspec 'mParticleIterableNoLocation' do |ss|
        ss.pod_target_xcconfig = {
            'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) MP_NO_LOCATION=1',
            'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) MP_NO_LOCATION'
        }

        ss.source_files = [
          'mParticle-iterable/**/*.{h,m,mm,swift}'
        ]

        ss.dependency 'mParticle-Apple-SDK/mParticleNoLocation', '~> 8.37'
    end
end
