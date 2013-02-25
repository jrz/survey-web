require 'spec_helper'

describe Photo do
  it { should belong_to(:answer) }

  context "when getting the URL" do
    it "returns the relative URL to the cached (local) image if the S3 version hasn't uploaded" do
      photo = FactoryGirl.create :photo
      photo.image.stub(:root).and_return(Rails.root)
      photo.image.stub(:cache_dir).and_return("spec/fixtures/images")
      photo.tmp = 'sample.jpg'
      photo.url.should == '/spec/fixtures/images/sample.jpg'
    end

    it "returns the URL to the S3 version if it's uploaded" do
      photo = FactoryGirl.create :photo
      photo.tmp = nil
      photo.url.should == photo.image.url.to_s
    end

    it "takes a format (medium or thumb) which it returns only for the S3 version" do
      photo = FactoryGirl.create :photo
      photo.tmp = nil
      photo.url(:format => :thumb).should == photo.image.thumb.url.to_s
    end

    it "returns empty if the question doesn't have an image" do
      photo = FactoryGirl.create :photo
      photo.url.should be_empty
    end
  end
end
