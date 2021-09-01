module Fixtures
  def self.permissions_list
    Shark::Permissions::List.new({
      'animal' => {
        resource: 'animal',
        privileges: { 'move' => true },
        title: 'Animal',
      },
      'animal::bird' => {
        resource: 'animal::bird',
        privileges:  { 'fly' => true },
        title: 'Bird',
      },
      'animal::bird::blackbird' => {
        resource: 'animal::bird::blackbird',
        privileges:  { 'sing' => true },
        title: 'Blackbird',
      },
      'animal::cat' => {
        resource: 'animal::cat',
        privileges:  { 'meow' => true },
        title: 'Cat',
      },
      'tree' => {
        resource: 'tree',
        privileges:  { 'move' => false },
        title: 'Tree',
      }
    })
  end
end
