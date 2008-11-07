class User < ActiveRecord::Base
  has_many :hosts
  validates_uniqueness_of :nickname

end
