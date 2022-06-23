# frozen_string_literal: true

module Gitlab
  module Ci
    class RunnerUpgradeCheck
      include Singleton

      STATUSES = {
        invalid: 'Runner version is not valid.',
        not_available: 'Upgrade is not available for the runner.',
        available: 'Upgrade is available for the runner.',
        recommended: 'Upgrade is available and recommended for the runner.'
      }.freeze

      def initialize
        reset!
      end

      def check_runner_upgrade_status(runner_version)
        runner_version = ::Gitlab::VersionInfo.parse(runner_version) unless runner_version.is_a?(::Gitlab::VersionInfo)

        return :invalid unless runner_version.valid?

        releases = RunnerReleases.instance.releases
        gitlab_minor_version = @gitlab_version.without_patch

        available_releases = releases
          .reject { |release| release.major > @gitlab_version.major }
          .reject do |release|
            # Do not reject a patch update, even if the runner is ahead of the instance version
            next false if release.same_minor_version?(runner_version)

            release.without_patch > gitlab_minor_version
          end

        return :recommended if available_releases.any? { |available_rel| patch_update?(available_rel, runner_version) }
        return :recommended if outside_backport_window?(runner_version, releases)
        return :available if available_releases.any? { |available_rel| available_rel > runner_version }

        :not_available
      end

      def reset!
        @gitlab_version = ::Gitlab::VersionInfo.parse(::Gitlab::VERSION)
      end

      public_class_method :instance

      private

      def patch_update?(available_release, runner_version)
        # https://docs.gitlab.com/ee/policy/maintenance.html#patch-releases
        available_release.major == runner_version.major &&
          available_release.minor == runner_version.minor &&
          available_release.patch > runner_version.patch
      end

      def outside_backport_window?(runner_version, releases)
        return false if runner_version >= releases.last # return early if runner version is too new

        latest_minor_releases = releases.map(&:without_patch).uniq
        latest_version_position = latest_minor_releases.count - 1
        runner_version_position = latest_minor_releases.index(runner_version.without_patch)

        return true if runner_version_position.nil? # consider outside if version is too old

        # https://docs.gitlab.com/ee/policy/maintenance.html#backporting-to-older-releases
        latest_version_position - runner_version_position > 2
      end
    end
  end
end
