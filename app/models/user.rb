class User < ApplicationRecord
  # Enable bcrypt password authentication
  has_secure_password

  # Email validations
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  # Password validations (handled automatically by has_secure_password for presence)
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :password, format: {
    with: /\A(?=.*[!@#$%^&*(),.?":{}|<>])/,
    message: "must contain at least one symbol"
  }, allow_nil: true

  # Normalize email to lowercase before saving
  before_validation :normalize_email

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
