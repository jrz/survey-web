require 'spec_helper'

describe Photo do
  it { should belong_to(:answer) }

  before do
    ImageUploader.enable_processing = true
    ImageUploader.storage = :file
  end

  after do
    ImageUploader.enable_processing = false
  end

  context "when getting the URL" do
    it "returns the relative URL to the cached (local) image if the S3 version hasn't uploaded" do
      photo = FactoryGirl.create :photo
      photo.image.stub(:root).and_return(Rails.root)
      photo.image.stub(:cache_dir).and_return("spec/fixtures/images")
      photo.image_tmp = 'sample.jpg'
      photo.url.should == '/spec/fixtures/images/sample.jpg'
    end

    it "returns the URL to the S3 version if it's uploaded" do
      photo = FactoryGirl.create :photo_with_image
      photo.image_tmp = nil
      photo.url.should == photo.image.url
    end

    it "takes a format (medium or thumb) which it returns only for the S3 version" do
      photo = FactoryGirl.create :photo_with_image
      photo.image_tmp = nil
      photo.url(:format => :thumb).should == photo.image.thumb.url
    end

    it "returns empty if the question doesn't have an image" do
      photo = FactoryGirl.create :photo
      photo.url.should be_empty
    end
  end

  pending "when encoding in base64" do
    it "returns the cached image if the remote image is still uploading" do
      photo = FactoryGirl.create :photo
      photo.image.stub(:root).and_return(Rails.root)
      photo.image.stub(:cache_dir).and_return("spec/fixtures/images")
      photo.image_tmp = 'sample.jpg'
      photo.url.should == '/spec/fixtures/images/sample.jpg'
      photo.in_base64.should == Base64.encode64(File.read('spec/fixtures/images/sample.jpg'))
    end

    it "returns the remote image if it's done uploading" do
      photo = FactoryGirl.create :photo
      photo.in_base64.should == Base64.encode64(File.read(photo.image.thumb.path))
    end
  end

end
