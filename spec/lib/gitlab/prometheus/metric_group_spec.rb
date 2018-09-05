# frozen_string_literal: true

require 'rails_helper'

describe Gitlab::Prometheus::MetricGroup do
  describe '.common_metrics' do
    let!(:project_metric) { create(:prometheus_metric) }
    let!(:common_metric_group_a) { create(:prometheus_metric, :common, group: :aws_elb) }
    let!(:common_metric_group_b_q1) { create(:prometheus_metric, :common, group: :kubernetes) }
    let!(:common_metric_group_b_q2) { create(:prometheus_metric, :common, group: :kubernetes) }

    subject { described_class.common_metrics }

    it 'returns exactly two groups' do
      expect(subject.map(&:name)).to contain_exactly('Response metrics (AWS ELB)', 'System metrics (Kubernetes)')
    end

    it 'returns exactly three metric queries' do
      expect(subject.map(&:metrics).flatten.map(&:id)).to contain_exactly(
        common_metric_group_a.id, common_metric_group_b_q1.id,
        common_metric_group_b_q2.id)
    end
  end

  describe '.for_project' do
    let!(:other_project) { create(:project) }
    let!(:project_metric) { create(:prometheus_metric) }
    let!(:common_metric) { create(:prometheus_metric, :common, group: :aws_elb) }

    subject { described_class.for_project(other_project) }

    it 'returns exactly one common metric' do
      expect(subject.map(&:metrics).flatten.map(&:id)).to contain_exactly(common_metric.id)
    end
  end
end
