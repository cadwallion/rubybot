class User < ActiveRecord::Base
  has_many :hosts
  validates_uniqueness_of :nickname
  def before_save
    nickname = nickname.downcase
  end
end
