# frozen_string_literal: true

require 'spec_helper'
require 'gitlab_chronic_duration'

RSpec.describe Gitlab::Ci::Config::Entry::Rules::Rule, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory.new(described_class)
      .metadata(metadata)
      .value(config)
  end

  let(:metadata) do
    {
      allowed_when: %w[on_success on_failure always never manual delayed],
      allowed_keys: %i[if changes exists when start_in allow_failure variables needs]
    }
  end

  let(:entry) { factory.create! }

  before do
    entry.compose!
  end

  describe '.new' do
    subject { entry }

    context 'with a when: value but no clauses' do
      let(:config) { { when: 'manual' } }

      it { is_expected.to be_valid }
    end

    context 'with an allow_failure: value but no clauses' do
      let(:config) { { allow_failure: true } }

      it { is_expected.to be_valid }
    end

    context 'when specifying an if: clause' do
      let(:config) { { if: '$THIS || $THAT', when: 'manual', allow_failure: true } }

      it { is_expected.to be_valid }

      describe '#when' do
        subject { entry.when }

        it { is_expected.to eq('manual') }
      end

      describe '#allow_failure' do
        subject { entry.allow_failure }

        it { is_expected.to eq(true) }
      end
    end

    context 'using a list of multiple expressions' do
      let(:config) { { if: ['$MY_VAR == "this"', '$YOUR_VAR == "that"'] } }

      it { is_expected.not_to be_valid }

      it 'reports an error about invalid format' do
        expect(subject.errors).to include(/invalid expression syntax/)
      end
    end

    context 'when specifying an invalid if: clause expression' do
      let(:config) { { if: ['$MY_VAR =='] } }

      it { is_expected.not_to be_valid }

      it 'reports an error about invalid statement' do
        expect(subject.errors).to include(/invalid expression syntax/)
      end
    end

    context 'when specifying an if: clause expression with an invalid token' do
      let(:config) { { if: ['$MY_VAR == 123'] } }

      it { is_expected.not_to be_valid }

      it 'reports an error about invalid statement' do
        expect(subject.errors).to include(/invalid expression syntax/)
      end
    end

    context 'when using invalid regex in an if: clause' do
      let(:config) { { if: ['$MY_VAR =~ /some ( thing/'] } }

      it 'reports an error about invalid expression' do
        expect(subject.errors).to include(/invalid expression syntax/)
      end
    end

    context 'when using an if: clause with lookahead regex character "?"' do
      let(:config) { { if: '$CI_COMMIT_REF =~ /^(?!master).+/' } }

      it { is_expected.not_to be_valid }

      it 'reports an error about invalid expression syntax' do
        expect(subject.errors).to include(/invalid expression syntax/)
      end
    end

    context 'when using a changes: clause' do
      let(:config) { { changes: %w[app/ lib/ spec/ other/* paths/**/*.rb] } }

      it { is_expected.to be_valid }
    end

    context 'when using a string as an invalid changes: clause' do
      let(:config) { { changes: 'a regular string' } }

      it { is_expected.not_to be_valid }

      it 'reports an error about invalid policy' do
        expect(subject.errors).to include(/should be an array or a hash/)
      end
    end

    context 'when using a list as an invalid changes: clause' do
      let(:config) { { changes: [1, 2] } }

      it { is_expected.not_to be_valid }

      it 'returns errors' do
        expect(subject.errors).to include(/changes config should be an array of strings/)
      end
    end

    context 'when using a long list as an invalid changes: clause' do
      let(:config) { { changes: ['app/'] * 51 } }

      it { is_expected.not_to be_valid }

      it 'returns errors' do
        expect(subject.errors).to include(/changes config has too many entries \(maximum 50\)/)
      end
    end

    context 'when using a exists: clause' do
      let(:config) { { exists: %w[app/ lib/ spec/ other/* paths/**/*.rb] } }

      it { is_expected.to be_valid }
    end

    context 'when using a string as an invalid exists: clause' do
      let(:config) { { exists: 'a regular string' } }

      it { is_expected.not_to be_valid }

      it 'reports an error about invalid policy' do
        expect(subject.errors).to include(/should be an array of strings/)
      end
    end

    context 'when using a list as an invalid exists: clause' do
      let(:config) { { exists: [1, 2] } }

      it { is_expected.not_to be_valid }

      it 'returns errors' do
        expect(subject.errors).to include(/exists should be an array of strings/)
      end
    end

    context 'when using a long list as an invalid exists: clause' do
      let(:config) { { exists: ['app/'] * 51 } }

      it { is_expected.not_to be_valid }

      it 'returns errors' do
        expect(subject.errors).to include(/exists is too long \(maximum is 50 characters\)/)
      end
    end

    context 'specifying a delayed job' do
      let(:config) { { if: '$THIS || $THAT', when: 'delayed', start_in: '2 days' } }

      it { is_expected.to be_valid }

      it 'sets attributes for the job delay' do
        expect(entry.when).to eq('delayed')
        expect(entry.start_in).to eq('2 days')
      end

      context 'without a when: key' do
        let(:config) { { if: '$THIS || $THAT', start_in: '15 minutes' } }

        it { is_expected.not_to be_valid }

        it 'returns an error about the disallowed key' do
          expect(entry.errors).to include(/disallowed keys: start_in/)
        end
      end

      context 'without a start_in: key' do
        let(:config) { { if: '$THIS || $THAT', when: 'delayed' } }

        it { is_expected.not_to be_valid }

        it 'returns an error about start_in being blank' do
          expect(entry.errors).to include(/start in can't be blank/)
        end
      end

      context 'when start_in value is longer than a week' do
        let(:config) { { if: '$THIS || $THAT', when: 'delayed', start_in: '2 weeks' } }

        it { is_expected.not_to be_valid }

        it 'returns an error about start_in exceeding the limit' do
          expect(entry.errors).to include(/start in should not exceed the limit/)
        end
      end
    end

    context 'when specifying unknown policy' do
      let(:config) { { invalid: :something } }

      it { is_expected.not_to be_valid }

      it 'returns error about invalid key' do
        expect(entry.errors).to include(/unknown keys: invalid/)
      end
    end

    context 'when clause is empty' do
      let(:config) { {} }

      it { is_expected.not_to be_valid }

      it 'is not a valid configuration' do
        expect(entry.errors).to include(/can't be blank/)
      end
    end

    context 'when policy strategy does not match' do
      let(:config) { 'string strategy' }

      it { is_expected.not_to be_valid }

      it 'returns information about errors' do
        expect(entry.errors)
          .to include(/should be a hash/)
      end
    end

    context 'when: validation' do
      context 'with an invalid boolean when:' do
        let(:config) do
          { if: '$THIS == "that"', when: false }
        end

        it { is_expected.to be_a(described_class) }
        it { is_expected.not_to be_valid }

        it 'returns an error about invalid when:' do
          expect(subject.errors).to include(/when unknown value: false/)
        end

        context 'when composed' do
          before do
            subject.compose!
          end

          it { is_expected.not_to be_valid }

          it 'returns an error about invalid when:' do
            expect(subject.errors).to include(/when unknown value: false/)
          end
        end
      end

      context 'with an invalid string when:' do
        let(:config) do
          { if: '$THIS == "that"', when: 'explode' }
        end

        it { is_expected.to be_a(described_class) }
        it { is_expected.not_to be_valid }

        it 'returns an error about invalid when:' do
          expect(subject.errors).to include(/when unknown value: explode/)
        end

        context 'when composed' do
          before do
            subject.compose!
          end

          it { is_expected.not_to be_valid }

          it 'returns an error about invalid when:' do
            expect(subject.errors).to include(/when unknown value: explode/)
          end
        end
      end

      context 'with an invalid when' do
        let(:metadata) { { allowed_when: %w[always never], allowed_keys: %i[if when] } }

        let(:config) do
          { if: '$THIS == "that"', when: 'on_success' }
        end

        it { is_expected.to be_a(described_class) }
        it { is_expected.not_to be_valid }

        it 'returns an error about invalid when:' do
          expect(subject.errors).to include(/when unknown value: on_success/)
        end

        context 'when composed' do
          before do
            subject.compose!
          end

          it { is_expected.not_to be_valid }

          it 'returns an error about invalid when:' do
            expect(subject.errors).to include(/when unknown value: on_success/)
          end
        end
      end

      context 'with an invalid variables' do
        let(:config) do
          { if: '$THIS == "that"', variables: 'hello' }
        end

        before do
          subject.compose!
        end

        it { is_expected.not_to be_valid }

        it 'returns an error about invalid variables:' do
          expect(subject.errors).to include(/variables config should be a hash/)
        end
      end
    end

    context 'allow_failure: validation' do
      context 'with an invalid string allow_failure:' do
        let(:config) do
          { if: '$THIS == "that"', allow_failure: 'always' }
        end

        it { is_expected.to be_a(described_class) }
        it { is_expected.not_to be_valid }

        it 'returns an error about invalid allow_failure:' do
          expect(subject.errors).to include(/rule allow failure should be a boolean value/)
        end

        context 'when composed' do
          before do
            subject.compose!
          end

          it { is_expected.not_to be_valid }

          it 'returns an error about invalid allow_failure:' do
            expect(subject.errors).to include(/rule allow failure should be a boolean value/)
          end
        end
      end
    end
  end

  describe '#value' do
    subject { entry.value }

    context 'when specifying an if: clause' do
      let(:config) { { if: '$THIS || $THAT', when: 'manual', allow_failure: true } }

      it 'stores the expression as "if"' do
        expect(subject).to eq(if: '$THIS || $THAT', when: 'manual', allow_failure: true)
      end
    end

    context 'when using a changes: clause' do
      let(:config) { { changes: %w[app/ lib/ spec/ other/* paths/**/*.rb] } }

      it { is_expected.to eq(changes: { paths: %w[app/ lib/ spec/ other/* paths/**/*.rb] }) }

      context 'when using changes with paths' do
        let(:config) { { changes: { paths: %w[app/ lib/ spec/ other/* paths/**/*.rb] } } }

        it { is_expected.to eq(config) }
      end

      context 'when using changes with paths and compare_to' do
        let(:config) { { changes: { paths: %w[app/ lib/ spec/ other/* paths/**/*.rb], compare_to: 'branch1' } } }

        it { is_expected.to eq(config) }
      end
    end

    context 'when default value has been provided' do
      let(:config) { { changes: %w[app/**/*.rb] } }

      before do
        entry.default = { changes: %w[**/*] }
      end

      it 'does not set a default value' do
        expect(entry.default).to eq(nil)
      end

      it 'does not add to provided configuration' do
        expect(entry.value).to eq(changes: { paths: %w[app/**/*.rb] })
      end
    end

    context 'when using a exists: clause' do
      let(:config) { { exists: %w[app/ lib/ spec/ other/* paths/**/*.rb] } }

      it { is_expected.to eq(config) }
    end
  end

  describe '.default' do
    let(:config) {}

    it 'does not have default value' do
      expect(described_class.default).to be_nil
    end
  end
end
