class Photo < ActiveRecord::Base
  belongs_to :answer
  mount_uploader :image, ImageUploader

  def url(opts={})
    return  "/#{image.cache_dir}/#{tmp}" if tmp 
    return image.url(opts[:format]) if image.file
    return ""
  end
end
