class User < ApplicationRecord
  has_and_belongs_to_many :interests
  has_and_belongs_to_many :skills

  validates :name, :patronymic, :email, :age, :nationality, :country, :gender, presence: true
  validates :email, uniqueness: true
  validates :age, numericality: { greater_than: 0, less_than: 90 }
  validates :gender, inclusion: { in: ['male', 'female'] }

  before_save :update_fullname

  private

  def update_fullname
    self.fullname = "#{surname} #{name} #{patronymic}"
  end
end

class Interest < ApplicationRecord
  has_and_belongs_to_many :users
end

class Skill < ApplicationRecord
  has_and_belongs_to_many :users
end

module Users
  class Create < ActiveInteraction::Base
    hash :params do
      string :name
      string :surname
      string :patronymic
      string :email
      integer :age
      string :nationality
      string :country
      string :gender
      array :interests
      array :skills
    end

    def execute
      return unless required_params_present?

      user_params = params.except('interests', 'skills')
      user = User.create(user_params)
      return unless user.present?

      user.skills << Skill.includes(:name).where(name: params['skills'].uniq)
      user.interests << Interest.includes(:name).where(name: params['interests'].uniq)
      user.save
    end

    private

    def required_params_present?
      %w[name surname patronymic email age nationality country gender].all? { |param| params.key?(param) }
    end
  end
end
