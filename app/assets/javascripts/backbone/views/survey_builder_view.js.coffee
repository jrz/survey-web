# Controls the survey building process
class SurveyBuilder.Views.SurveyBuilderView extends Backbone.View
  el: "#survey_builder"

  events:
    'new_question': 'new_question'
    'new_category': 'new_category'
    'dummy_click': 'handle_dummy_click'
    'click #save': 'save_all_questions'
    'click #finalize': 'finalize'
    'show_survey_details': 'show_survey_details'
    'save_all_questions': 'save_all_questions'

  initialize:(survey_id) =>
    this.picker_pane   = new SurveyBuilder.Views.PickerPaneView
    this.survey        = new SurveyBuilder.Models.SurveyModel(survey_id)
    this.settings_pane = new SurveyBuilder.Views.SettingsPaneView(this.survey)
    this.dummy_pane    = new SurveyBuilder.Views.DummyPaneView(this.survey)
    $(this.el).ajaxStart(window.notifications_view.show_spinner)
    $(this.el).ajaxStop(window.notifications_view.hide_spinner)

    # $( "#sidebar" ).tabs()

    $.getJSON("/api/surveys/#{survey_id}", this.preload_elements)


  new_question: (event, data) =>
    @loading_overlay()
    type = data.type
    parent = data.parent
    model = this.survey.add_new_question_model(type, parent)
    this.dummy_pane.add_question(type, model, parent)
    this.settings_pane.add_question(type, model)
    model.save_model()

  new_category: (event, type) =>
    @loading_overlay()
    model = this.survey.add_new_question_model()
    this.dummy_pane.add_category(type, model)
    this.settings_pane.add_category(type, model)
    model.save_model()

  preload_elements: (data) =>
    _(data.elements).each (element) =>
      model = this.survey.add_new_question_model(element)
      model.set('id', element.id)
      model.preload_elements()
      this.dummy_pane.add_question(element.type, model)
      this.settings_pane.add_question(element.type, model)
    window.loading_overlay.hide_overlay()
    this.dummy_pane.reorder_questions()

  loading_overlay: =>
    window.loading_overlay.show_overlay()
    $(this.el).bind('ajaxStop.new_question', =>
      window.loading_overlay.hide_overlay()
      $(this.el).unbind('ajaxStop.new_question')
      )

  handle_dummy_click: =>
    this.hide_all()
    # this.switch_tab()

  hide_all: (event) =>
    this.dummy_pane.unfocus_all()
    this.settings_pane.hide_all()

  show_survey_details: =>
    this.dummy_pane.show_survey_details()

  switch_tab: =>
    $("#sidebar").tabs('select', 1)

  finalize: =>
    if confirm(I18n.t('surveys.confirm_finalize'))
      $(this.el).bind "ajaxStop.finalize", =>
        $(this.el).unbind "ajaxStop.finalize"
        $("#finalize_hidden").click() unless this.survey.has_errors()
      @save_all_questions()

  save_all_questions: =>
    $(this.el).find("#save input").prop('disabled', true)
    window.loading_overlay.show_overlay()

    # Delay so that the UI doesn't hang.
    _.delay(=>
      $(this.el).bind('ajaxStop.save', this.handle_save_finished)
      this.survey.save()
      this.survey.save_all_questions()
    , 10)

  handle_save_finished: =>
    $(this.el).unbind('ajaxStart.save')
    $(this.el).unbind('ajaxStop.save')
    $(this.el).find("#save input").prop('disabled', false)
    $(this.el).trigger('save_finished')
    @display_save_status()
    window.loading_overlay.hide_overlay()

  display_save_status: =>
    if this.survey.has_errors()
      window.notifications_view.set_error(I18n.t('js.save_unsuccessful'),)
    else
      window.notifications_view.set_notice(I18n.t('js.save_successful'),)
