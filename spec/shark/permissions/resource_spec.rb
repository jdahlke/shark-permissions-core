# frozen_string_literal: true

RSpec.describe Shark::Permissions::Resource do
  normal_name = 'cms::projects::berlin'
  wildcard_name = 'datenraum::space::*'

  describe '#ancestors_and_self' do
    subject { resource.ancestors_and_self }

    context "with #{normal_name}" do
      let(:resource) { described_class.new(normal_name) }
      let(:expected_ancestors) { %w[cms cms::projects cms::projects::berlin] }

      it { is_expected.to eq(expected_ancestors) }
    end

    context "with #{wildcard_name}" do
      let(:resource) { described_class.new(wildcard_name) }
      let(:expected_ancestors) { %w[datenraum datenraum::space datenraum::space::*] }

      it { is_expected.to eq(expected_ancestors) }
    end
  end

  describe '#subresource_of?' do
    context "with #{normal_name}" do
      let(:resource) { described_class.new(normal_name) }

      {
        'cms' => true,
        'cms::projects' => true,
        'cms::foo' => false,
        'cms::projects::ber' => false,
        'cms::projects::berlin' => true,
        'datenraum' => false
      }.each do |name, value|
        it "subresource of #{name} returns #{value}" do
          expect(resource.subresource_of?(name)).to eq(value)
        end
      end
    end

    context "with #{wildcard_name}" do
      let(:resource) { described_class.new(wildcard_name) }

      {
        'datenraum' => true,
        'datenraum::space' => true,
        'datenraum::space::ae_forum' => false,
        'datenraum::space::*' => true,
        'cms' => false
      }.each do |name, value|
        it "subresource of #{name} returns #{value}" do
          expect(resource.subresource_of?(name)).to eq(value)
        end
      end
    end
  end

  describe '#super_resource_of?' do
    context "with #{normal_name}" do
      let(:resource) { described_class.new(normal_name) }

      {
        'cms::projects' => false,
        'cms::projects::berlin' => true,
        'cms::projects::berlinale' => false,
        'cms::projects::berlin::wedding' => true,
        'cms::projects::*' => false
      }.each do |name, value|
        it "super-resource of #{name} returns #{value}" do
          expect(resource.super_resource_of?(name)).to eq(value)
        end
      end
    end

    context "with #{wildcard_name}" do
      let(:resource) { described_class.new(wildcard_name) }

      {
        'datenraum::space::*' => true,
        'datenraum::space::ae_forum' => true,
        'datenraum::space' => false
      }.each do |name, value|
        it "super-resource of #{name} returns #{value}" do
          expect(resource.super_resource_of?(name)).to eq(value)
        end
      end
    end
  end
end
