require 'spec_helper'
require 'ostruct'


RSpec.describe RomFactory::Builder do
  before(:all) do
    container = ROM.container(:sql, 'sqlite::memory') do |conf|
      conf.default.create_table(:users) do
        primary_key :id
        column :last_name, String, null: false
        column :first_name, String, null: false
        column :email, String, null: false
        column :created_at, Time, null: false
        column :updated_at, Time, null: false
      end
    end

    RomFactory::Config.configure do |config|
      config.container = container
    end
  end

  let(:repo_class) {
    Class.new(ROM::Repository[:users]) do
      commands :create
    end
  }

  let(:mapped_user_class) {
    Class.new do
      def self.call(attrs)
        OpenStruct.new(attrs)
      end
    end
  }

  describe "factory builder DSL" do
    it "does not error when trying using proper DSL" do
      RomFactory::Builder.define do |b|
        b.factory(repo: repo_class, name: :user_1) do |f|
          f.first_name "Janis"
          f.last_name "Miezitis"
          f.email "janjiss@gmail.com"
        end
      end
    end

    it "Raises an error if arguments are not part of schema" do
      expect {
        RomFactory::Builder.define do |b|
          b.factory(repo: repo_class, name: :user_2) do |f|
            f.boobly "Janis"
          end
        end
      }.to raise_error(NoMethodError)
    end
  end

  context "creation of records" do
    it "creates a record based on defined factory" do
      RomFactory::Builder.define do |b|
        b.factory(repo: repo_class, name: :user_3) do |f|
          f.first_name "Janis"
          f.last_name "Miezitis"
          f.email "janjiss@gmail.com"
          f.created_at Time.now
          f.updated_at Time.now
        end
      end

      user = RomFactory::Builder.create(:user_3)
      expect(user.email).not_to be_empty
      expect(user.first_name).not_to be_empty
      expect(user.last_name).not_to be_empty
    end

    it "supports callable values" do
      RomFactory::Builder.define do |b|
        b.factory(repo: repo_class, name: :user_4) do |f|
          f.first_name "Janis"
          f.last_name "Miezitis"
          f.email "janjiss@gmail.com"
          f.created_at {Time.now}
          f.updated_at {Time.now}
        end
      end

      user = RomFactory::Builder.create(:user_4)
      expect(user.email).not_to be_empty
      expect(user.first_name).not_to be_empty
      expect(user.last_name).not_to be_empty
      expect(user.created_at).not_to be_nil
      expect(user.updated_at).not_to be_nil
    end
  end

  context "mapping of the records" do
    it "creates a record based on defined factory" do
      RomFactory::Builder.define do |b|
        b.factory(repo: repo_class, name: :user_6, as: mapped_user_class) do |f|
          f.first_name "Janis"
          f.last_name "Miezitis"
          f.email "janjiss@gmail.com"
          f.created_at Time.now
          f.updated_at Time.now
        end
      end

      user = RomFactory::Builder.create(:user_6)
      expect(user).to be_kind_of(OpenStruct)
      expect(user.email).not_to be_empty
      expect(user.first_name).not_to be_empty
      expect(user.last_name).not_to be_empty
    end
  end

  context "changing values" do
    it "supports overwriting of values" do
      RomFactory::Builder.define do |b|
        b.factory(repo: repo_class, name: :user_7, as: mapped_user_class) do |f|
          f.first_name "Janis"
          f.last_name "Miezitis"
          f.email "janjiss@gmail.com"
          f.created_at Time.now
          f.updated_at Time.now
        end
      end

      user = RomFactory::Builder.create(:user_7, email: "holla@gmail.com")
      expect(user.email).to eq("holla@gmail.com")
    end
  end

  context "errors" do
    it "raises error if factory with the same name is registered" do
      RomFactory::Builder.define do |b|
        b.factory(repo: repo_class, name: :user_8) do
        end
      end

      expect {
        RomFactory::Builder.define do |b|
          b.factory(repo: repo_class, name: :user_8) do
          end
        end
      }.to raise_error(ArgumentError)
    end
  end
end
