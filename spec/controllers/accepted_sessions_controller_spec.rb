# encoding: UTF-8
require 'spec_helper'

describe AcceptedSessionsController, type: :controller do
  describe "#index" do
    context 'csv' do
      let(:conference) {FactoryGirl.create(:conference)}
      context 'unauthorized user' do
        before(:each) do
          @user = FactoryGirl.build(:user)
          @user.add_role('organizer')
          controller.stubs(:current_user).returns(@user)
        end

        it 'should return 403 status' do
          get :index, year: conference.year, format: :csv

          expect(response.status).to eq(403)
        end
        it 'should say unauthorized' do
          get :index, year: conference.year, format: :csv

          expect(response.body).to eq('Unauthorized')
        end
      end
      context 'authorized user' do
        before(:each) do
          controller.stubs(:current_ability).returns(stub(:can? => true))
        end
        it 'should generate CSV from accepted sessions' do
          session = FactoryGirl.create(:session, state: 'accepted', conference: conference)

          get :index, year: conference.year, format: :csv

          csv = <<-CSV
Session id,Session title,Session Type,Author,Email
#{session.id},#{session.title},#{I18n.t(session.session_type.title)},#{session.author.full_name},#{session.author.email}
          CSV
          expect(response.body).to eq(csv)
        end
      end
    end
  end
end
