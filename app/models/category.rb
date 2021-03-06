class Category < ActiveRecord::Base
  belongs_to :parent, :class_name => Option
  belongs_to :category
  belongs_to :survey
  has_many :questions, :dependent => :destroy
  has_many :categories, :dependent => :destroy
  has_many :records, :dependent => :destroy
  validates_presence_of :content
  attr_accessible :content, :survey_id, :order_number, :category_id, :parent_id, :type, :mandatory

  delegate :question, :to => :parent, :prefix => true, :allow_nil => true

  before_destroy { |category| !category.finalized? }

  scope :finalized, where(:finalized => true)


  def elements
    (questions + categories.includes([:questions, :categories])).sort_by(&:order_number)
  end

  def create_blank_answers(params={})
    elements.each { |element| element.create_blank_answers(params) }
  end

  def self.new_category_by_type(type, params)
    klass = (type == 'MultiRecordCategory') ? MultiRecordCategory : Category
    klass.new(params)
  end

  def as_json_with_elements_in_order
    json = self.as_json
    json['elements'] = elements.map(&:as_json_with_elements_in_order).flatten
    json
  end

  def questions_in_order
    elements.map(&:questions_in_order).flatten
  end

  def as_json(opts={})
    super(opts.merge({ :methods => [:type, :has_multi_record_ancestor] }))
  end

  def nesting_level
    return parent_question.nesting_level + 1 if parent
    return category.nesting_level + 1 if category
    return 1
  end

  def sub_question?
    parent || category.try(:sub_question?)
  end

  def sorted_answers_for_response(response_id, record_id=nil)
    elements.map { |element| element.sorted_answers_for_response(response_id, record_id) }.flatten
  end

  def duplicate(survey_id)
    category = self.dup
    category.survey_id = survey_id
    category.questions << questions.map { |question| question.duplicate(survey_id) } if self.respond_to? :questions
    category.categories << categories.map { |category| category.duplicate(survey_id) } if self.respond_to? :categories
    category.save(:validate => false)
    category
  end

  def copy_with_order
    duplicated_category = duplicate(survey_id)
    duplicated_category.order_number += 1
    duplicated_category.save
  end

  def has_questions?
    questions.count > 0 || categories.any? { |x| x.has_questions? }
  end

  def categories_with_questions
    categories.select { |x| x.has_questions? }
  end

  def index_of_parent_option
    parent_options = parent_question.options
    parent_options.index(parent)
  end

  def has_multi_record_ancestor?
    category.try(:is_a?, MultiRecordCategory) || category.try(:has_multi_record_ancestor?) || parent.try(:has_multi_record_ancestor?)
  end

  def to_json_with_sub_elements
    to_json(:include => [{ :questions => { :methods => :type }}, { :categories => { :methods => :type }}])
  end

  def elements_with_questions
    (questions + categories_with_questions).sort_by(&:order_number)
  end

  protected

  def has_multi_record_ancestor
    has_multi_record_ancestor?
  end
end
