# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddWorkItemsRolledupDatesWidget, :migration, feature_category: :team_planning do
  it_behaves_like 'migration that adds widget to work items definitions',
    widget_name: 'Rolledup dates'
end
