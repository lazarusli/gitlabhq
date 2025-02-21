# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class Stage < ApplicationRecord
      MAX_STAGES_PER_VALUE_STREAM = 15

      self.table_name = :analytics_cycle_analytics_group_stages

      include Analytics::CycleAnalytics::Stageable
      include Analytics::CycleAnalytics::Parentable

      validates :name, uniqueness: { scope: [:group_id, :group_value_stream_id] }
      validate :max_stages_count, on: :create

      belongs_to :value_stream, class_name: 'Analytics::CycleAnalytics::ValueStream',
        foreign_key: :group_value_stream_id, inverse_of: :stages

      alias_attribute :parent, :namespace
      alias_attribute :parent_id, :group_id
      alias_attribute :value_stream_id, :group_value_stream_id

      def self.distinct_stages_within_hierarchy(namespace)
        # Looking up the whole hierarchy including all kinds (type) of Namespace records.
        # We're doing a custom traversal_ids query because:
        # - The traversal_ids based `self_and_descendants` doesn't include the ProjectNamespace records.
        # - The default recursive lookup also excludes the ProjectNamespace records.
        #
        # Related issue: https://gitlab.com/gitlab-org/gitlab/-/issues/386124
        all_namespace_ids =
          Namespace
          .select(Arel.sql('namespaces.traversal_ids[array_length(namespaces.traversal_ids, 1)]').as('id'))
          .where("traversal_ids @> ('{?}')", namespace.id)

        with_preloaded_labels
          .where(parent_id: all_namespace_ids)
          .select("DISTINCT ON(stage_event_hash_id) #{quoted_table_name}.*")
      end

      private

      def max_stages_count
        return unless value_stream
        return unless value_stream.stages.count >= MAX_STAGES_PER_VALUE_STREAM

        errors.add(:value_stream, _('Maximum number of stages per value stream exceeded'))
      end
    end
  end
end
