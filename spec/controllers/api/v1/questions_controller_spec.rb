require 'spec_helper'

module Api
  module V1
    describe QuestionsController do
      let(:organization_id) { 12 }
      let(:survey) { FactoryGirl.create(:survey, :organization_id => organization_id) }

      before(:each) do
        sign_in_as('super_admin')
        session[:user_info][:org_id] = organization_id
        response = double('response')
        parsed_response = { "email" => "admin@admin.com",
                            "id" => 1,
                            "name" => "cso_admin",
                            "organization_id" => 12,
                            "role" => "cso_admin"
                            }

        access_token = double('access_token')
        OAuth2::AccessToken.stub(:new).and_return(access_token)
        access_token.stub(:get).and_return(response)
        response.stub(:parsed).and_return(parsed_response)
      end
      context "POST 'create'" do
        it "creates a new question" do
          question = FactoryGirl.attributes_for(:question, :type => 'RadioQuestion', :survey_id => survey.id)

          expect do
            post :create, :survey_id => survey.id, :question => question
          end.to change { Question.count }.by(1)
        end

        it "creates a new question based on the type" do
          question = FactoryGirl.attributes_for(:question, :survey_id => survey.id)
          question['type'] = 'RadioQuestion'
          expect do
            post :create, :survey_id => survey.id, :question => question
          end.to change { RadioQuestion.count }.by(1)
        end

        it "doesn't create the question if the current user doesn't have permission to do so" do
          sign_in_as('viewer')
          survey = FactoryGirl.create(:survey, :organization_id => 500)
          question = FactoryGirl.attributes_for(:question, :survey_id => survey.id, :type => 'SingleLineQuestion')
          expect {
            post :create, :survey_id => survey.id, :question => question
          }.not_to change { Question.count }
        end

        it "returns the created question as JSON" do
          expected_keys = Question.attribute_names
          question = FactoryGirl.attributes_for(:question, :type => 'RadioQuestion', :survey_id => survey.id)
          post :create, :survey_id => survey.id, :question => question

          response.should be_ok
          returned_json = JSON.parse(response.body)
          expected_keys.each { |key| returned_json.keys.should include key }
          returned_json['content'].should == question[:content]
        end

        it "returns the `has_multi_record_ancestor` method in the JSON output" do
          expected_keys = Question.attribute_names
          question = FactoryGirl.attributes_for(:question, :type => 'RadioQuestion', :survey_id => survey.id)
          post :create, :survey_id => survey.id, :question => question

          response.should be_ok
          returned_json = JSON.parse(response.body)
          returned_json.keys.should include 'has_multi_record_ancestor'
        end

        context "when save is unsuccessful" do
          it "returns the errors with a bad_request status" do
            question = FactoryGirl.attributes_for(:question, :type => 'RadioQuestion', :survey_id => survey.id)
            question[:content] = ''
            post :create, :survey_id => survey.id, :question => question

            response.status.should == 400
            JSON.parse(response.body).should be_any {|m| m =~ /can\'t be blank/ }
          end
        end
      end

      context "PUT 'update'" do
        it "updates the question" do
          question = FactoryGirl.create(:question, :survey => survey)
          put :update, :id => question.id, :question => {:content => "hello"}
          Question.find(question.id).content.should == "hello"
        end

        it "returns the updated question as JSON, including it's type" do
          expected_keys = Question.attribute_names
          question = FactoryGirl.create(:question, :type => 'RadioQuestion', :survey => survey)
          put :update, :id => question.id, :question => {:content => "someuniquestring"}

          response.should be_ok
          returned_json = JSON.parse(response.body)
          returned_json.keys.should =~ expected_keys
          returned_json['content'].should == 'someuniquestring'
        end

        context "when update is unsuccessful" do
          it "returns the errors with a bad request status" do
            question = FactoryGirl.create(:question, :survey => survey)
            put :update, :id => question.id, :question => {:content => ""}
            response.status.should == 400
            JSON.parse(response.body).should be_any {|m| m =~ /can\'t be blank/ }
          end
        end

        it "doesn't update the question if the current user doesn't have permission to do so" do
          sign_in_as('viewer')
          survey = FactoryGirl.create(:survey, :organization_id => 500)
          question = FactoryGirl.create(:question, :survey => survey)
          put :update, :id => question.id, :question => {:content => "someuniquestring"}
          question.reload.content.should_not == 'someuniquestring'
        end
      end

      context "DELETE 'destroy'" do
        it "deletes the question" do
          question = FactoryGirl.create(:question, :survey => survey)
          delete :destroy, :id => question.id
          Question.find_by_id(question.id).should be_nil
        end

        it "handles an invalid ID passed in" do
          delete :destroy, :id => '1234567'
          response.should_not be_ok
        end

        it "doesn't destroy the question if the current user doesn't have permission to do so" do
          sign_in_as('viewer')
          survey = FactoryGirl.create(:survey, :organization_id => 500)
          question = FactoryGirl.create(:question, :survey => survey)
          delete :destroy, :id => question.id
          question.reload.should be_present
        end
      end

      context "POST image_upload" do
        it "uploads the image for given question" do
          question = FactoryGirl.create(:question, :survey => survey)
          @file = fixture_file_upload('/images/sample.jpg', 'text/xml')
          post :image_upload, :id => question.id, :image => @file
          response.should be_ok
          question.reload.image.should be
          question.reload.image.should_not eq '/images/original/missing.png'
        end

        it "returns the url for the image thumb as JSON" do
          question = FactoryGirl.create(:question, :survey => survey)
          @file = fixture_file_upload('/images/sample.jpg', 'text/xml')
          post :image_upload, :id => question.id, :image => @file
          response.should be_ok
          JSON.parse(response.body).should == { 'image_url' => question.reload.image_url(:thumb) }
        end

        it "returns the errors if the image upload was unsuccessful" do
          question = FactoryGirl.create(:question, :survey => survey)
          @file = fixture_file_upload('/images/sample.jpg', 'text/xml')
          Question.stub(:find).and_return(question)
          question.stub(:save).and_return(false)
          question.stub(:errors).and_return("error message")
          post :image_upload, :id => question.id, :image => nil
          JSON.parse(response.body)['errors'].should =~ /error/
        end

        it "doesn't perform the upload if the current user doesn't have permission to do so" do
          sign_in_as('viewer')
          survey = FactoryGirl.create(:survey, :organization_id => 500)
          question = FactoryGirl.create(:question, :survey => survey)
          @file = fixture_file_upload('/images/sample.jpg', 'text/xml')
          post :image_upload, :id => question.id, :image => @file
          response.should_not be_ok
          question.reload.image.should be_blank
        end
      end

      context "GET 'index'" do
        it "returns question IDs" do
          question = FactoryGirl.create(:question, :survey_id => survey.id)
          get :index, :survey_id => survey.id
          response.should be_ok
          JSON.parse(response.body).map { |hash| hash['id'] }.should include question.id
        end

        it "returns question types" do
          question = FactoryGirl.create(:question, :survey_id => survey.id, :type => "RadioQuestion")
          get :index, :survey_id => survey.id
          response.should be_ok
          JSON.parse(response.body).map { |hash| hash['type'] }.should include 'RadioQuestion'
        end

        it "returns all attributes of the question as well as the image_url" do
          question = RadioQuestion.create(FactoryGirl.attributes_for(:question, :survey_id => survey.id))
          get :index, :survey_id => survey.id
          response.should be_ok
          response.body.should include question.to_json(:methods => [:type, :image_url, :image_in_base64])
        end

        it "returns the image in base64 if the referrer is nil or mobile" do
          question = RadioQuestion.create(FactoryGirl.attributes_for(:question, :survey_id => survey.id))
          request.env["HTTP_REFERER"] = nil
          get :index, :survey_id => survey.id
          response.body.should include question.to_json(:methods => [:type, :image_url, :image_in_base64])
        end

        it "does not return the image in base64 if the referrer is a url" do
          question = RadioQuestion.create(FactoryGirl.attributes_for(:question, :survey_id => survey.id))
          request.env["HTTP_REFERER"] = 'http://google.com'
          get :index, :survey_id => survey.id
          response.body.should include question.to_json(:methods => [:type, :image_url])
          response.body.should_not include question.to_json(:methods => [:image_in_base64])
        end

        it "returns a :bad_request if no survey_id is passed" do
          get :index
          response.should_not be_ok
        end

        it "authorizes the current user's access to the given survey" do
          sign_in_as('viewer')
          survey = FactoryGirl.create(:survey, :organization_id => 500)
          question = RadioQuestion.create(FactoryGirl.attributes_for(:question, :survey_id => survey.id))
          get :index, :survey_id => survey.id
          response.should_not be_ok
        end
      end

      context "GET 'show'" do
        it "returns the question as JSON" do
          question = FactoryGirl.create(:question, :survey => survey)
          get :show, :id => question.id
          response.should be_ok
          response.body.should == question.to_json(:methods => [:type, :image_url, :has_multi_record_ancestor, :image_in_base64])
        end

        it "returns a :bad_request for an invalid question_id" do
          get :show, :id => 456787
          response.should_not be_ok
        end

        it "authorizes the current user's access to the given question's survey" do
          sign_in_as('viewer')
          survey = FactoryGirl.create(:survey, :organization_id => 500)
          question = FactoryGirl.create(:question, :survey => survey)
          get :show, :id => question.id
          response.should_not be_ok
        end

      end

      context "POST 'duplicate'" do
        before(:each) do
          request.env["HTTP_REFERER"] = 'http://google.com'
        end

        context "when succesful" do
          it "creates new question" do
            question = FactoryGirl.create(:question, :survey => survey)
            expect {
              post :duplicate, :id => question.id
            }.to change { Question.count }.by 1
          end

          it "redirects back with a success message" do
            question = FactoryGirl.create(:question, :survey => survey)
            post :duplicate, :id => question.id
            response.should redirect_to(:back)
            flash[:notice].should_not be_nil
          end
        end

        context "when unsuccessful" do
          it "redirects back with a error message" do
            post :duplicate, :id => 456787
            response.should redirect_to(:back)
            flash[:error].should_not be_nil
          end
        end

        it "doesn't duplicate the question if the current user doesn't have access to the survey" do
          sign_in_as('viewer')
          survey = FactoryGirl.create(:survey, :organization_id => 500)
          question = FactoryGirl.create(:question, :survey => survey)
          expect { post :duplicate, :id => question.id }.not_to change { Question.count }
          response.should_not be_ok
        end
      end
    end
  end
end
