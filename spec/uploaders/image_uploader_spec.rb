require 'carrierwave/test/matchers'

describe ImageUploader do
  include CarrierWave::Test::Matchers

  before do
    ImageUploader.enable_processing = true
    ImageUploader.storage = :file
    @question = FactoryGirl.create :question
    @uploader = ImageUploader.new(@question, :image)
    file =  File.open "#{Rails.root}/spec/fixtures/images/sample.jpg"
    @uploader.store!(file)
  end

  after do
    ImageUploader.enable_processing = false
    @uploader.remove!
  end

  context 'the thumb version' do
    it "should scale down a image to fit within 100 by 100 pixels" do
      @uploader.thumb.should be_no_larger_than(100, 100)
    end
  end

  context 'the medium version' do
    it "should scale down a image to fit within 300 by 300 pixels" do
      @uploader.medium.should be_no_larger_than(300, 300)
    end
  end

  it "knows the filename of the image" do
    @uploader.filename.should == File.basename(@uploader.path)
  end
end
