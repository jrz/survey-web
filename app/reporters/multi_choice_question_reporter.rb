class MultiChoiceQuestionReporter < QuestionReporter
  SELECTED_STRING     = "YES"
  NOT_SELECTED_STRING = "NO"
  BLANK_FIELD_FOR_QUESTION = ""

  def header
    [super] + question.options.map(&:content)
  end

  def formatted_answers_for(answers, options={})
    initial_array = [BLANK_FIELD_FOR_QUESTION]
    return initial_array + model.options.map { NOT_SELECTED_STRING } if answers.empty?
    model.options.inject(initial_array) do |memo, option|
      selection = answers.map do |answer|
        choice = Choice.where('answer_id = ? AND option_id = ?', answer.id, option.id)
        choice.present? ? SELECTED_STRING : NOT_SELECTED_STRING
      end.join(", ")
      memo << selection
    end
  end
end
