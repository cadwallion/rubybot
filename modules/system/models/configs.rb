class Conf < Sequel::Model
  validates_uniqueness_of :config_name
end
