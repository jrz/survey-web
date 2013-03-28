SurveyBuilder.Views.Questions ||= {}

#  The settings of a single option in the settings pane
class SurveyBuilder.Views.Questions.OptionView extends Backbone.View
  initialize: (@model, @template) =>
    this.sub_questions = []
    this.model.on('change:errors', this.render, this)
    this.model.on('change:id', this.render, this)
    this.model.on('add:sub_question', this.add_sub_question, this)
    this.model.on('change:preload_sub_questions', this.preload_sub_questions)
    this.model.on('destroy', this.remove, this)
    @preload_sub_questions()

  render: =>
    data = _.extend(this.model.toJSON(), {errors: this.model.errors})
    $(this.el).html(Mustache.render(@template, data))
    $(this.el).addClass('option')
    $(this.el).children('div').children('.add_sub_question').bind('click', this.add_sub_question_model)
    $(this.el).children('div').children('.add_sub_category').bind('click', this.add_sub_category_model)
    $(this.el).children('div').children('.add_sub_multi_record').bind('click', this.add_sub_category_model)
    $(this.el).children('div').children('.delete_option').bind('click', this.delete)
    $(this.el).children('input').bind('keyup', this.update_model)
    return this

  update_model: (event) =>
    input = $(event.target)
    this.model.set({content: input.val()})
    event.stopImmediatePropagation()

  delete: =>
    this.model.destroy()

  add_sub_question_model: (event) =>
    type = $(event.target).prev().val()
    this.model.add_sub_question(type)

  add_sub_category_model: (event) =>
    type = $(event.target).data('type')
    this.model.add_sub_question(type)

  add_sub_question: (sub_question_model) =>
    window.loading_overlay.show_overlay()
    $(this.el).bind('ajaxStop.new_question', =>
      window.loading_overlay.hide_overlay()
      $(this.el).unbind('ajaxStop.new_question')
      )
    sub_question_model.on('destroy', this.delete_sub_question, this)
    type = sub_question_model.get('type')
    question = SurveyBuilder.Views.QuestionFactory.settings_view_for(type, sub_question_model)
    this.sub_questions.push question
    $('#settings_pane').append($(question.render().el))
    $(question.render().el).hide()

  preload_sub_questions: () =>
    _.each(@model.sub_question_models, (sub_question_model) =>
      this.add_sub_question(sub_question_model)
    )

  delete_sub_question: (sub_question_model) =>
    view = sub_question_model.actual_view
    @sub_questions = _(@sub_questions).without(view)
    view.remove()
