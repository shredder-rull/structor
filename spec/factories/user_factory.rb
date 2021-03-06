FactoryGirl.define do
  factory :user do
    email { FFaker::Internet.email }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    trait :address do
      address{ FactoryGirl.build(:address) }
    end
  end
end