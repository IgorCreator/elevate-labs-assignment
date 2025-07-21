require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    context 'email' do
      it 'requires an email' do
        user = build(:user, email: nil)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it 'validates email format' do
        invalid_emails = [ 'invalid', 'invalid@', '@invalid.com', 'invalid@.com' ]
        invalid_emails.each do |email|
          user = build(:user, email: email)
          expect(user).not_to be_valid
          expect(user.errors[:email]).to include("is invalid")
        end
      end

      it 'accepts valid email formats' do
        valid_emails = [ 'test@example.com', 'user+tag@domain.co.uk', 'valid.email@test.org' ]
        valid_emails.each do |email|
          user = build(:user, email: email)
          expect(user).to be_valid
        end
      end

      it 'enforces email uniqueness (case insensitive)' do
        create(:user, email: 'test@example.com')

        duplicate_user = build(:user, email: 'TEST@EXAMPLE.COM')
        expect(duplicate_user).not_to be_valid
        expect(duplicate_user.errors[:email]).to include("has already been taken")
      end

      it 'normalizes email to lowercase' do
        user = create(:user, email: 'TEST@EXAMPLE.COM')
        expect(user.email).to eq('test@example.com')
      end

      it 'strips whitespace from email' do
        user = create(:user, email: '  test@example.com  ')
        expect(user.email).to eq('test@example.com')
      end
    end

    context 'password' do
      it 'requires a password' do
        user = build(:user, password: nil)
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("can't be blank")
      end

      it 'requires minimum 8 characters' do
        user = build(:user, password: 'Short1!')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("is too short (minimum is 8 characters)")
      end

      it 'requires at least one symbol' do
        user = build(:user, password: 'NoSymbol123')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("must contain at least one symbol")
      end

      it 'accepts valid passwords with symbols' do
        valid_passwords = [ 'Password123!', 'MySecure@Pass', 'Complex#2024$' ]
        valid_passwords.each do |password|
          user = build(:user, password: password, password_confirmation: password)
          expect(user).to be_valid
        end
      end

      it 'requires password confirmation to match' do
        user = build(:user, password: 'ValidPass1!', password_confirmation: 'Different!')
        expect(user).not_to be_valid
        expect(user.errors[:password_confirmation]).to include("doesn't match Password")
      end
    end
  end

  describe 'authentication' do
    let(:user) { create(:user, password: 'SecurePass123!') }

    it 'authenticates with correct password' do
      expect(user.authenticate('SecurePass123!')).to eq(user)
    end

    it 'fails authentication with incorrect password' do
      expect(user.authenticate('WrongPassword')).to be_falsey
    end

    it 'has secure password digest' do
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq('SecurePass123!')
    end
  end

  describe 'factory' do
    it 'creates valid user from factory' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'creates unique emails for multiple users' do
      user1 = create(:user)
      user2 = create(:user)
      expect(user1.email).not_to eq(user2.email)
    end
  end
end
