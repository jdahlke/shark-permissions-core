# frozen_string_literal: true

RSpec.describe Shark::Permissions::Rule do
  let(:resource) { 'foo' }
  let(:args) do
    {
      resource: resource,
      privileges: { bar: true },
      title: "#{resource} title",
    }
  end
  let(:rule) { described_class.new(args) }

  describe '.new' do
    shared_examples 'a permission rule' do
      it 'should have correct values' do
        hash = args.symbolize_keys
        expect(subject.resource).to eq(hash[:resource])
        expect(subject.privileges).to eq(hash[:privileges].stringify_keys)
        expect(subject.title).to eq(hash[:title])
      end
    end


    subject { Shark::Permissions::Rule.new(args) }

    context 'with Hash of symbols' do
      let(:args) { super().symbolize_keys }
      it_should_behave_like 'a permission rule'
    end

    context 'with Hash of strings' do
      let(:args) { super().stringify_keys }
      it_should_behave_like 'a permission rule'
    end

    context 'with privilege keys as symbols' do
      let(:args) do
        args = super()
        args[:privileges] = { baz: false }
        args
      end

      it 'should return same privileges with string keys' do
        expect(subject.privileges).to eq ({ 'baz' => false })
      end
    end

    context 'with privilege values as strings' do
      let(:args) do
        args = super()
        args[:privileges] = { bar: 'true', baz: 'false', ban: nil }
        args
      end

      it 'should return same privileges with string keys' do
        expect(subject.privileges).to eq({ 'bar' => true, 'baz' => false, 'ban' => false })
      end
    end
  end

  describe '#parent' do
    context 'with resource "foo"' do
      it 'returns nil' do
        expect(rule.parent).to be_nil
      end
    end

    context 'with resource "foo::bar"' do
      let(:resource) { 'foo::bar' }

      it 'returns "foo"' do
        expect(rule.parent).to eq('foo')
      end
    end
  end

  describe '#==' do
    let(:args1) { { resource: 'foo', privileges: { read: true } } }

    subject do
      rule1 = described_class.new(args1)
      rule2 = described_class.new(args2)
      rule1 == rule2
    end

    context 'with different name comparing same values' do
      let(:args2) { { resource: 'bar', privileges: { read: true } } }

      it { is_expected.to be(false) }
    end

    context 'with different privilege' do
      let(:args2) { { resource: 'foo', privileges: { read: true, write: false } } }

      it { is_expected.to be(false) }
    end

    context 'when comparing same values' do
      let(:args2) { args1 }

      it { is_expected.to be(true) }
    end
  end

  describe '#changes' do
    subject { rule.changes }

    it 'returns Permissions::Changes' do
      is_expected.to be_kind_of(Shark::Permissions::Changes)
    end
  end

  describe '#update' do
    subject { rule.update(changed_rule) }

    context 'with different resource' do
      let(:changed_rule) do
        changes = { resource: 'bar' }
        described_class.new(args.merge(changes))
      end

      it 'raises ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'with a same resource_name' do
      let(:changed_rule) do
        changes = { privileges: { bar: false, baz: true }}
        described_class.new(args.merge(changes))
      end

      let(:expected_privileges) do
        {
          old: {'bar' => true, 'baz' => false },
          new: {'bar' => false, 'baz' => true }
        }
      end

      it 'updates privileges' do
        expect(subject.privileges).to eq({ 'bar' => false, 'baz' => true })
      end

      it 'tracks privilege changes' do
        expect(rule.changes).to_not be_present

        expect(subject.changes.privileges).to eq(expected_privileges)
      end
    end
  end
end
