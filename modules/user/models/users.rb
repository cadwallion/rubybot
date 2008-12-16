class User < ActiveRecord::Base
  has_many :hosts, :dependent => :destroy
  validates_uniqueness_of :nickname
  def before_save
    self.nickname = self.nickname.downcase
  end
end
