# THIS PERFORMS ADDITIONAL CONFIGURATION IF THE USER SELECTS THE OBJECTIVE-C OPTION
#
# We are responsible to:
#  - Prepare items in the templates/objective-c directory
#  - Move items from templates/objective-c to the staging directory
#

module Pod
  class ObjectiveCConfigurator
    attr_reader :configurator

    def self.perform(options)
      new(options).perform
    end

    def initialize(options)
      @configurator = options.fetch(:configurator)
    end

    def perform
      keep_demo = configurator.ask_with_answers("Would you like to include a demo application with your library", ["Yes", "No"]).to_sym

      framework = configurator.ask_with_answers("Which testing frameworks will you use", ["Quick", "None"]).to_sym
      case framework
      when :quick
        configurator.add_pod_to_podfile "Quick', '~> 0.10"
        configurator.add_pod_to_podfile "Nimble', '~> 5.1"
        `mv "templates/test_examples/quick.swift" "templates/swift/Example/Tests/Tests.swift"`
      when :none
        `mv "templates/test_examples/xctest.swift" "templates/swift/Example/Tests/Tests.swift"`
      end

      snapshots = configurator.ask_with_answers("Would you like to do view based testing", ["Yes", "No"]).to_sym
      case snapshots
      when :yes
        configurator.add_pod_to_podfile "FBSnapshotTestCase"

        if keep_demo == :no
          puts " - Putting the demo application back in, you cannot do view tests without a host application."
          keep_demo = :yes
        end

        if framework == :quick
          configurator.add_pod_to_podfile "Nimble-Snapshots"
        end
      end

      Pod::ProjectManipulator.new({
        :configurator => @configurator,
        :xcodeproj_path => "templates/objective-c/Example/iOS Example.xcodeproj",
        :platform => :ios,
        :remove_demo_project => (keep_demo == :no),
        :prefix => ""
      }).run

      `mv ./templates/objective-c/* ./staging`
    end
  end
end
