# frozen_string_literal: true

RSpec.describe Shark::Permissions::List do
  describe '.new' do
    subject { described_class.new(rules) }

    context 'with Hash of Permissions::Rules' do
      let(:rules) do
        {
          'foo' => Shark::Permissions::Rule.new(resource: 'foo', privileges: { 'bar' => true }, title: 'foo title')
        }
      end

      it 'returns Shark::Permissions::List' do
        is_expected.to be_kind_of(described_class)
      end
    end

    context 'with Hash of Hashes' do
      let(:rules) do
        {
          'foo' => { resource: 'foo', privileges: { foo: true } },
          'foo::bar' => { resource: 'foo::bar', privileges: { bar: true } }
        }
      end

      it 'returns Shark::Permissions::List' do
        is_expected.to be_kind_of(described_class)
      end
    end

    context 'with empty Hash' do
      let(:rules) { {} }

      it 'returns Shark::Permissions::List' do
        is_expected.to be_kind_of(described_class)
      end
    end

    context 'with anything else' do
      let(:rules) { 'anything' }

      it 'raises error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#merge' do
    let(:original) { Fixtures.permissions_list }
    let(:other) do
      Shark::Permissions::List.new({
        'animal' => {
          resource: 'animal',
          privileges: { 'run' => true }
        },
        'animal::bird::blackbird' => {
          resource: 'animal::bird::blackbird',
          privileges:  { 'sing' => false }
        }
      })
    end
    let(:expected_list) do
      Shark::Permissions::List.new({
        'animal': {
          resource: 'animal',
          privileges: {
            'move': true,
            'run': true
          },
          title: 'Animal'
        },
        'animal::bird': {
          resource: 'animal::bird',
          privileges: {
            'fly': true
          },
          title: 'Bird'
        },
        'animal::bird::blackbird': {
          resource: 'animal::bird::blackbird',
          privileges: {
            'sing': false
          },
          title: 'Blackbird'
        },
        'animal::cat': {
          resource: 'animal::cat',
          privileges: {
            'meow': true
          },
          title: 'Cat'
        },
        'tree': {
          resource: 'tree',
          privileges: {
            'move': false
          },
          title: 'Tree'
        }
      })
    end

    subject { original.merge(other) }

    it { is_expected.to be_kind_of(Shark::Permissions::List) }

    it 'does not change the original' do
      subject
      expect(original).to eq(Fixtures.permissions_list)
    end

    it 'returns merged rules' do
      expect(subject).to eq(expected_list)
    end

    let(:expected_changes) do
      {
         'animal' => {
           privileges: {
             old: { 'run' => false },
             new: {'run'=> true}
           }
         },
         'animal::bird' => {
           privileges: {}
         },
         'animal::bird::blackbird' => {
           privileges: {
             old: { 'sing' => true },
             new: { 'sing' => false}
           }
         },
         'animal::cat' => {
           privileges: {}
         },
         'tree' => {
           privileges: {}
         }
      }
    end

    it 'tracks changes' do
      subject.each do |name, rule|
        expect(rule.changes.privileges).to eq(expected_changes[name][:privileges])
      end
    end
  end

  describe '#privileges' do
    let(:list) { Fixtures.permissions_list }

    context 'for existing resources' do
      it 'returns inherited privileges for resource' do
        expect(list.privileges(:animal, :bird)).to eq({ 'move' => true, 'fly' => true })
      end
    end

    context 'for not existing resources' do
      it 'returns inherited privileges for super resource' do
        expect(list.privileges(:animal, :fish)).to eq({ 'move' => true })
      end
    end
  end

  describe '#authorized?' do
    let(:list) { Fixtures.permissions_list }

    context 'with single granted privilege' do
      context 'as resource as symbols' do
        it { expect(list.authorized?('sing', :animal, :bird, :blackbird)).to be(true) }
      end

      context 'and resources as string' do
        it 'returns true' do
          expect(list.authorized?('fly', 'animal::bird::blackbird')).to be(true)
        end
      end
    end

    context 'with list of any granted privilege' do
      it 'returns true' do
        expect(list.authorized?(%w(sing swim), :animal, :bird, :blackbird)).to be(true)
      end
    end

    context 'with privilege not granted' do
      it { expect(list.authorized?('sing', :animal, :cat)).to be(false) }
    end

    context "when any_matcher '*'" do
      context 'when at least one privilege is granted' do
        it 'returns true' do
          expect(list.authorized?('*', :animal, :bird, :blackbird)).to be(true)
        end
      end

      context 'when no privileges are granted' do
        it 'returns false' do
          expect(list.authorized?('*', :tree)).to be(false)
        end
      end
    end
  end

  describe '#subresource_authorized?' do
    let(:list) { Fixtures.permissions_list }

    context 'when privilege granted by rules for a subresource' do
      it 'returns true' do
        expect(list.subresource_authorized?('sing', :animal, :bird)).to be(true)
      end
    end

    context 'when privilege not granted by rules for a subresource' do
      it 'returns false' do
        expect(list.subresource_authorized?('foo', :animal)).to be false
      end
    end

    context "when using the any_matcher '*'" do
      context 'when at least one privilege is granted for a subresource' do
        it 'returns true' do
          expect(list.subresource_authorized?('*', :animal)).to be(true)
        end
      end

      context 'when no privileges are granted ' do
        it 'returns false' do
          expect(list.subresource_authorized?('*', :tree)).to be false
          expect(list.subresource_authorized?('*', :tree, :oak)).to be false
        end
      end
    end
  end

  describe '#compact' do
    let(:list) do
      Shark::Permissions::List.new({
        'empty' => {
          resource: 'empty',
          privileges: {}
        },
        'foo' => {
          resource: 'foo',
          privileges: { foo: true }
        },
        'foo::bar' => {
          resource: 'foo::bar',
          privileges: { foo: true }
        }
      })
    end

    subject { list.compact }

    context 'with empty rules that have no privileges' do
      it 'removes them' do
        expect(subject[:empty]).to be_nil
      end
    end

    it 'does not change the original' do
      subject
      expect(list.key?('empty')).to be(true)
      expect(list.key?('foo::bar')).to be(true)
    end
  end

  describe '#select' do
    let(:list) { Fixtures.permissions_list }

    context 'with "animal::bird"' do
      subject { list.select('animal::bird') }
      let(:expected_resources) { %w[animal::bird animal::bird::blackbird] }

      it 'returns only animal::bird rules' do
        expect(subject).to be_kind_of(described_class)
        expect(subject.rules.keys).to eq(expected_resources)
      end
    end

    context 'with "animal::bird::*"' do
      subject { list.select('animal::bird::*') }
      let(:expected_resources) { %w[animal::bird::blackbird] }

      it 'returns only animal::bird::* rules' do
        expect(subject).to be_kind_of(described_class)
        expect(subject.rules.keys).to eq(expected_resources)
      end
    end
  end

  describe '#reject' do
    let(:list) { Fixtures.permissions_list }

    context 'with "animal"' do
      subject { list.reject('animal') }
      let(:expected_resources) { %w[tree] }

      it 'returns only non "animal" rules' do
        expect(subject).to be_kind_of(described_class)
        expect(subject.rules.keys).to eq(expected_resources)
      end
    end

    context 'with "animal::*"' do
      subject { list.reject('animal::*') }
      let(:expected_resources) { %w[animal tree] }

      it 'returns only rules that are no subresource of "animal"' do
        expect(subject).to be_kind_of(described_class)
        expect(subject.rules.keys).to eq(expected_resources)
      end
    end
  end

  describe '#set_inherited_privileges!' do
    let(:list) do
      Shark::Permissions::List.new({
        'foo' => {
          resource: 'foo',
          privileges: { 'foo' => true }
        },
        'foo::bar' => {
          resource: 'foo::bar',
          privileges: { foo: false, bar: true }
        },
        'foo::bar::baz' => {
          resource: 'foo::bar::baz',
          privileges: { bar: false, baz: true }
        }
      })
    end

    subject { list.set_inherited_privileges! }

    it 'sets privileges from super resource also in subresources' do
      expect(subject['foo'].privileges).to eq ({ 'foo' => true })
      expect(subject['foo::bar'].privileges).to eq({ 'foo' => true, 'bar' => true })
    end

    it 'not sets privileges that are not in subresources' do
      expect(subject['foo::bar::baz'].privileges).to eq({ 'bar' => true, 'baz' => true })
    end
  end

  describe '#remove_inherited_rules' do
    let(:list) do
      Shark::Permissions::List.new({
        'foo' => {
          resource: 'foo',
          privileges: { 'foo' => true }
        },
        'foo::bar' => {
          resource: 'foo::bar',
          privileges: { foo: false, bar: true }
        },
        'foo::bar::baz' => {
          resource: 'foo::bar::baz',
          privileges: { bar: true }
        }
      })
    end

    subject { list.remove_inherited_rules }

    it 'removes inherited privileges' do
      expect(subject['foo'].privileges).to eq({ 'foo' => true })
      expect(subject['foo::bar'].privileges).to eq({ 'bar' => true })
    end

    it 'removes rules without privileges' do
      expect(subject.key?('foo::bar::baz')).to eq(false)
    end
  end

  describe '#==' do
    subject do
      list1 = Shark::Permissions::List.new(rules1)
      list2 = Shark::Permissions::List.new(rules2)
      list1 == list2
    end
    let(:rules1) do
      {
        'foo' => {
          resource: 'foo',
          privileges: { read: true }
        },
        'foo::bar' => {
          resource: 'foo::bar',
          privileges: { write: true }
        }
      }
    end

    context 'with different name comparing same values' do
      let(:rules2) do
        {
          'foo' => {
            resource: 'foo',
            privileges: { read: true }
          },
          'foo::baz' => {
            resource: 'foo::baz',
            privileges: { write: true }
          }
        }
      end

      it { is_expected.to be(false) }
    end

    context 'with different privilege' do
      let(:rules2) do
        {
          'foo' => {
            resource: 'foo',
            privileges: { read: false }
          },
          'foo::bar' => {
            resource: 'foo::bar',
            privileges: { write: true }
          }
        }
      end

      it { is_expected.to be(false) }
    end

    context 'when comparing same values' do
      let(:rules2) { rules1 }

      it { is_expected.to be(true) }
    end
  end
end
