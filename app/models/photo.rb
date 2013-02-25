class Photo < ActiveRecord::Base
  belongs_to :answer
  mount_uploader :image, ImageUploader

  def url(opts={})
    return  "/#{image.cache_dir}/#{image_tmp}" if image_tmp 
    return image.url(opts[:format]) if image.file
    return ""
  end

  def in_base64
    file = File.read("#{image.root}/#{image.cache_dir}/#{image_tmp}") if image_tmp
    file = image.thumb.file.read if image.thumb.file.try(:exists?)
    return Base64.encode64(file) if file
  end
end
