class User < ApplicationRecord
  has_secure_password
  has_many :game_events, dependent: :destroy

  attribute :admin, :boolean, default: false

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :password, format: {
    with: /\A(?=.*[!@#$%^&*(),.?":{}|<>]).*\z/,
    message: "must contain at least one symbol"
  }, allow_nil: true

  before_validation :normalize_email

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
