# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :photo do
    answer_id 1
    image "MyString"
    factory :photo_with_image do
      image { fixture_file_upload(Rails.root.to_s + '/spec/fixtures/images/sample.jpg', 'image/jpeg') }
    end
  end
end
