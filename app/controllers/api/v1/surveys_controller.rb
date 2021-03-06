module Api
  module V1
    class SurveysController < APIApplicationController
      caches_action :show, :if => :survey_finalized?
      authorize_resource :except => [:identifier_questions, :questions_count]

      def index
        surveys = Survey.accessible_by(current_ability).active_plus(extra_survey_ids)
        render :json => surveys
      end

      def questions_count
        surveys = Survey.accessible_by(current_ability).active_plus(extra_survey_ids)
        render :json => { count: surveys.with_questions.count }
      end
      
      def identifier_questions
        survey = Survey.find_by_id(params[:id])
        authorize! :read, survey
        if survey
          render :json => survey.identifier_questions
        else
          render :nothing => true, :status => :bad_request
        end 
      end

      def show
        survey = Survey.find_by_id(params[:id])
        authorize! :read, survey
        if survey
          survey_json = survey.as_json
          survey_json['elements'] = survey.elements_in_order_as_json
          render :json => survey_json
        else
          render :nothing => true, :status => :bad_request
        end
      end

      def update
        survey = Survey.find_by_id(params[:id])
        if survey && survey.update_attributes(params[:survey])
          render :json => survey.to_json
        else
          render :json => survey.try(:errors).try(:full_messages), :status => :bad_request
        end
      end

      private

      def extra_survey_ids
        extra_survey_ids = params[:extra_surveys] || ""
        extra_survey_ids.split(',').map(&:to_i)
      end

      def survey_finalized?
        survey = Survey.find_by_id(params[:id])
        survey.finalized?
      end
    end
  end
end
