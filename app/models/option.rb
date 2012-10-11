class Option < ActiveRecord::Base
  belongs_to :question
  has_many :questions, :foreign_key => :parent_id
  attr_accessible :content, :question_id, :order_number
  validates_uniqueness_of :order_number, :scope => :question_id
  validates_presence_of :content, :question_id
  default_scope :order => 'order_number'

  def as_json(opts={})
    super(opts).merge({:questions => questions.map(&:as_json)})
  end
end