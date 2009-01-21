class Channel < Sequel::Model
  validates_uniqueness_of :name
end
