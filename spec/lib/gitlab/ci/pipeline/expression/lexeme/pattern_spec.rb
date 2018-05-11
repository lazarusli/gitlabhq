require 'fast_spec_helper'
require_dependency 're2'

describe Gitlab::Ci::Pipeline::Expression::Lexeme::Pattern do
  describe '.build' do
    it 'creates a new instance of the token' do
      expect(described_class.build('/.*/'))
        .to be_a(described_class)
    end
  end

  describe '.type' do
    it 'is a value lexeme' do
      expect(described_class.type).to eq :value
    end
  end

  describe '.scan' do
    it 'correctly identifies a pattern token' do
      scanner = StringScanner.new('/pattern/')

      token = described_class.scan(scanner)

      expect(token).not_to be_nil
      expect(token.build.evaluate)
        .to eq Gitlab::UntrustedRegexp.new('pattern')
    end

    it 'is a greedy scanner for regexp boundaries' do
      scanner = StringScanner.new('/some .* / pattern/')

      token = described_class.scan(scanner)

      expect(token).not_to be_nil
      expect(token.build.evaluate)
        .to eq Gitlab::UntrustedRegexp.new('some .* / pattern')
    end

    it 'does not allow to use an empty pattern' do
      scanner = StringScanner.new(%(//))

      token = described_class.scan(scanner)

      expect(token).to be_nil
    end
  end

  describe '#evaluate' do
    it 'returns a regular expression' do
      string = described_class.new('abc')

      expect(string.evaluate).to eq Gitlab::UntrustedRegexp.new('abc')
    end
  end
end
