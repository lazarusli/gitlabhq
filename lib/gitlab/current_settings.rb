# frozen_string_literal: true

module Gitlab
  module CurrentSettings
    class << self
      def signup_disabled?
        !signup_enabled?
      end

      def signup_limited?
        domain_allowlist.present? || email_restrictions_enabled? || require_admin_approval_after_user_signup? || user_default_external?
      end

      def current_application_settings
        Gitlab::SafeRequestStore.fetch(:current_application_settings) { Gitlab::ApplicationSettingFetcher.current_application_settings }
      end

      def current_application_settings?
        Gitlab::SafeRequestStore.exist?(:current_application_settings) || Gitlab::ApplicationSettingFetcher.current_application_settings?
      end

      def expire_current_application_settings
        Gitlab::ApplicationSettingFetcher.expire_current_application_settings
        Gitlab::SafeRequestStore.delete(:current_application_settings)
      end

      def method_missing(name, *args, **kwargs, &block)
        current_application_settings.send(name, *args, **kwargs, &block) # rubocop:disable GitlabSecurity/PublicSend
      end

      def respond_to_missing?(name, include_private = false)
        current_application_settings.respond_to?(name, include_private) || super
      end
    end
  end
end
