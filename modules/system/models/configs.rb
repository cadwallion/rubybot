class Conf < ActiveRecord::Base
  validates_uniqueness_of :config_name
end
