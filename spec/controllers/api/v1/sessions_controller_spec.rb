# encoding: UTF-8
require 'spec_helper'

describe Api::V1::SessionsController, type: :controller do
  let(:conference) { FactoryGirl.create(:conference) }
  let(:session)  { FactoryGirl.create(:session, keyword_list: %w(fake tags tags.success), conference: conference) }

  describe 'show' do
    context 'with pt locale' do
      before do
        get :show, id: session.id.to_s, format: :json, locale: 'pt'
      end

      it { should respond_with(:success) }

      it 'should return session JSON parseable representation' do
        gravatar_id = Digest::MD5::hexdigest(session.author.email).downcase
        expect(JSON.parse(response.body)).to eq({
          'id' => session.id,
          'session_uri' => "http://test.host/#{session.conference.year}/sessions/#{session.to_param}?locale=pt",
          'title' => session.title,
          'authors' => [{ 'user_id' => session.author.id,
            'user_uri' => "http://test.host/users/#{session.author.to_param}?locale=pt",
            'username' => session.author.username,
            'name' => session.author.full_name,
            'gravatar_url' => gravatar_url(gravatar_id)}],
          'prerequisites' => session.prerequisites,
          'duration_mins' => 50,
          'tags' => ['fake', 'tags', 'Casos de Sucesso'],
          'session_type' => 'Palestra',
          'audience_level' => 'Iniciante',
          'track' => 'Engenharia',
          'audience_limit' => nil,
          'summary' => session.summary,
          'mechanics' => session.mechanics,
          'status' => 'Criada',
          'author_agreement' => nil,
          'image_agreement' => nil
        })
      end

      it 'should return session raw JSON with 2 authors' do
        session.second_author = FactoryGirl.create(:author, email: 'dtsato@dtsato.com')
        session.save

        get :show, id: session.id.to_s, format: :json, locale: 'pt'

        expect(unescape_utf8_chars(response.body)).to eq(%Q{
          {
            "id":#{session.id},
            "session_uri":"http://test.host/#{session.conference.year}/sessions/#{session.to_param}?locale=pt",
            "title":"#{session.title}",
            "authors":[
              {
                "user_id":#{session.author.id},
                "user_uri":"http://test.host/users/#{session.author.to_param}?locale=pt",
                "username":"#{session.author.username}",
                "name":"#{session.author.full_name}",
                "gravatar_url":"#{gravatar_url(Digest::MD5::hexdigest(session.author.email).downcase)}"
              },
              {
                "user_id":#{session.second_author.id},
                "user_uri":"http://test.host/users/#{session.second_author.to_param}?locale=pt",
                "username":"#{session.second_author.username}",
                "name":"#{session.second_author.full_name}",
                "gravatar_url":"#{gravatar_url(Digest::MD5::hexdigest(session.second_author.email).downcase)}"
              }
            ],
            "prerequisites":"#{session.prerequisites}",
            "tags":["fake","tags","Casos de Sucesso"],
            "duration_mins":50,
            "session_type":"Palestra",
            "audience_level":"Iniciante",
            "track":"Engenharia",
            "audience_limit":null,
            "summary":"#{session.summary}",
            "mechanics":"#{session.mechanics}",
            "status":"Criada",
            "author_agreement":null,
            "image_agreement":null}
        }.gsub(/\s*\n\s*/,''))
      end
    end

    context 'using en locale' do
      before do
        get :show, id: session.id.to_s, format: :json, locale: 'en'
      end
      it 'should respect locale on session type, audience level, track and tags if possible' do
        gravatar_id = Digest::MD5::hexdigest(session.author.email).downcase
        expect(JSON.parse(response.body)).to eq({
          'id' => session.id,
          'session_uri' => "http://test.host/#{session.conference.year}/sessions/#{session.to_param}?locale=en",
          'title' => session.title,
          'authors' => [{ 'user_id' => session.author.id,
            'user_uri' => "http://test.host/users/#{session.author.to_param}?locale=en",
            'username' => session.author.username,
            'name' => session.author.full_name,
            'gravatar_url' => gravatar_url(gravatar_id)}],
          'prerequisites' => session.prerequisites,
          'tags' => ['fake', 'tags', 'Success Cases'],
          'duration_mins' => 50,
          'session_type' => 'Lecture',
          'audience_level' => 'Beginner',
          'track' => 'Engineering',
          'audience_limit' => nil,
          'summary' => session.summary,
          'mechanics' => session.mechanics,
          'status' => 'Created',
          'author_agreement' => nil,
          'image_agreement' => nil
        })
      end
    end

    it 'should respond with 404 for unexisting session' do
      get :show, id: ((Session.last.try(:id) || 0) + 1), format: :json

      expect(response.code).to eq('404')
      expect(response.body).to eq('{"error":"not-found"}')
    end

    it 'should respond to js as JS object as well' do
      xhr :get, :show, format: :js, id: session.id.to_s,
        locale: 'pt'

      gravatar_id = Digest::MD5::hexdigest(session.author.email).downcase
      expect(JSON.parse(response.body)).to eq({
        'id' => session.id,
        'session_uri' => "http://test.host/#{session.conference.year}/sessions/#{session.to_param}?locale=pt",
        'title' => session.title,
        'authors' => [{ 'user_id' => session.author.id,
          'user_uri' => "http://test.host/users/#{session.author.to_param}?locale=pt",
          'username' => session.author.username,
          'name' => session.author.full_name,
          'gravatar_url' => gravatar_url(gravatar_id)}],
        'prerequisites' => session.prerequisites,
        'tags' => ['fake', 'tags', 'Casos de Sucesso'],
        'duration_mins' => 50,
        'session_type' => 'Palestra',
        'audience_level' => 'Iniciante',
        'track' => 'Engenharia',
        'audience_limit' => nil,
        'summary' => session.summary,
        'mechanics' => session.mechanics,
        'status' => 'Criada',
        'author_agreement' => nil,
        'image_agreement' => nil
      })
    end

    it 'should respond to js with callback as JSONP if callback is provided' do
      xhr :get, :show, format: :js, id: session.id.to_s,
        locale: 'pt', callback: 'test'

      gravatar_id = Digest::MD5::hexdigest(session.author.email).downcase
      expect(response.body).to match(/test\((.*)\)$/)
      expect(JSON.parse(response.body.match(/test\((.*)\)$/)[1])).to eq({
        'id' => session.id,
        'session_uri' => "http://test.host/#{session.conference.year}/sessions/#{session.to_param}?locale=pt",
        'title' => session.title,
        'authors' => [{ 'user_id' => session.author.id,
          'user_uri' => "http://test.host/users/#{session.author.to_param}?locale=pt",
          'username' => session.author.username,
          'name' => session.author.full_name,
          'gravatar_url' => gravatar_url(gravatar_id)}],
        'prerequisites' => session.prerequisites,
        'tags' => ['fake', 'tags', 'Casos de Sucesso'],
        'duration_mins' => 50,
        'session_type' => 'Palestra',
        'audience_level' => 'Iniciante',
        'track' => 'Engenharia',
        'audience_limit' => nil,
        'summary' => session.summary,
        'mechanics' => session.mechanics,
        'status' => 'Criada',
        'author_agreement' => nil,
        'image_agreement' => nil
      })
    end

    it 'should respond to js with audience limit' do
      session.audience_limit = 100
      session.save

      xhr :get, :show, format: :js, id: session.id.to_s,
        locale: 'pt', callback: 'test'

      gravatar_id = Digest::MD5::hexdigest(session.author.email).downcase
      expect(response.body).to match(/test\((.*)\)$/)
      expect(JSON.parse(response.body.match(/test\((.*)\)$/)[1])).to eq({
        'id' => session.id,
        'session_uri' => "http://test.host/#{session.conference.year}/sessions/#{session.to_param}?locale=pt",
        'title' => session.title,
        'authors' => [{ 'user_id' => session.author.id,
          'user_uri' => "http://test.host/users/#{session.author.to_param}?locale=pt",
          'username' => session.author.username,
          'name' => session.author.full_name,
          'gravatar_url' => gravatar_url(gravatar_id)}],
        'prerequisites' => session.prerequisites,
        'tags' => ['fake', 'tags', 'Casos de Sucesso'],
        'duration_mins' => 50,
        'session_type' => 'Palestra',
        'audience_level' => 'Iniciante',
        'track' => 'Engenharia',
        'audience_limit' => 100,
        'summary' => session.summary,
        'mechanics' => session.mechanics,
        'status' => 'Criada',
        'author_agreement' => nil,
        'image_agreement' => nil
      })
    end

    context 'before author confirmation date for a rejected session' do
      before do
        session.reviewing
        session.reject
        session.save!
        get :show, id: session.id.to_s, format: :json, locale: 'en'
      end

      it 'should respect locale on session type, audience level, track and tags if possible' do
        gravatar_id = Digest::MD5::hexdigest(session.author.email).downcase
        expect(JSON.parse(response.body)).to eq({
          'id' => session.id,
          'session_uri' => "http://test.host/#{session.conference.year}/sessions/#{session.to_param}?locale=en",
          'title' => session.title,
          'authors' => [{ 'user_id' => session.author.id,
            'user_uri' => "http://test.host/users/#{session.author.to_param}?locale=en",
            'username' => session.author.username,
            'name' => session.author.full_name,
            'gravatar_url' => gravatar_url(gravatar_id)}],
          'prerequisites' => session.prerequisites,
          'tags' => ['fake', 'tags', 'Success Cases'],
          'duration_mins' => 50,
          'session_type' => 'Lecture',
          'audience_level' => 'Beginner',
          'track' => 'Engineering',
          'audience_limit' => nil,
          'summary' => session.summary,
          'mechanics' => session.mechanics,
          'status' => 'Created',
          'author_agreement' => nil,
          'image_agreement' => nil
        })
      end
    end
  end

  describe 'accepted' do
    before do
      @accepted_sessions = [
        create_accepted_session_for(conference),
        create_accepted_session_for(conference)
      ]
    end
    context 'with pt locale' do
      before do
        Timecop.freeze((conference.author_confirmation + 1.day).to_datetime) do
          get :accepted, format: :json, locale: 'pt', year: conference.year
        end
      end

      it { should respond_with(:success) }

      it 'should return accepted_sessions in a parseable JSON representation' do
        sessions = @accepted_sessions.map { |s| pt_hash_for(s) }
        
        expect(JSON.parse(response.body)).to eq(sessions)
      end
    end

    context 'with en locale' do
      before do
        Timecop.freeze((conference.author_confirmation + 1.day).to_datetime) do
          get :accepted, format: :json, locale: 'en', year: conference.year
        end
      end

      it { should respond_with(:success) }

      it 'should return accepted_sessions in a parseable JSON representation' do
        sessions = @accepted_sessions.map { |s| en_hash_for(s) }
        
        expect(JSON.parse(response.body)).to eq(sessions)
      end
    end

    context 'before author confirmation date' do
      before do
        Timecop.freeze((conference.author_confirmation - 1.hour).to_datetime) do
          get :accepted, format: :json, locale: 'en', year: conference.year
        end
      end

      it { should respond_with(:success) }

      it 'should return an empty array' do
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end

  def pt_hash_for(session)
    gravatar_id = Digest::MD5::hexdigest(session.author.email).downcase
    {
      'id' => session.id,
      'session_uri' => "http://test.host/#{session.conference.year}/sessions/#{session.to_param}?locale=pt",
      'title' => session.title,
      'authors' => [{ 'user_id' => session.author.id,
        'user_uri' => "http://test.host/users/#{session.author.to_param}?locale=pt",
        'username' => session.author.username,
        'name' => session.author.full_name,
        'gravatar_url' => gravatar_url(gravatar_id)}],
      'prerequisites' => session.prerequisites,
      'tags' => ['Aprendizagem', 'Testes'],
      'duration_mins' => 50,
      'session_type' => 'Palestra',
      'audience_level' => 'Iniciante',
      'track' => 'Engenharia',
      'audience_limit' => nil,
      'summary' => session.summary,
      'mechanics' => session.mechanics,
      'status' => 'Aceita',
      'author_agreement' => true,
      'image_agreement' => false
    }
  end

  def en_hash_for(session)
    gravatar_id = Digest::MD5::hexdigest(session.author.email).downcase
    {
      'id' => session.id,
      'session_uri' => "http://test.host/#{session.conference.year}/sessions/#{session.to_param}?locale=en",
      'title' => session.title,
      'authors' => [{ 'user_id' => session.author.id,
        'user_uri' => "http://test.host/users/#{session.author.to_param}?locale=en",
        'username' => session.author.username,
        'name' => session.author.full_name,
        'gravatar_url' => gravatar_url(gravatar_id)}],
      'prerequisites' => session.prerequisites,
      'tags' => ['Learning', 'Tests'],
      'duration_mins' => 50,
      'session_type' => 'Lecture',
      'audience_level' => 'Beginner',
      'track' => 'Engineering',
      'audience_limit' => nil,
      'summary' => session.summary,
      'mechanics' => session.mechanics,
      'status' => 'Accepted',
      'author_agreement' => true,
      'image_agreement' => false
    }
  end

  def create_accepted_session_for(conference)
    FactoryGirl.create(:session, state: :accepted, author_agreement: true, image_agreement: false, conference: conference)
  end

  def gravatar_url(gravatar_id)
    "https://gravatar.com/avatar/#{gravatar_id}.png?s=48&d=mm"
  end

  def unescape_utf8_chars(text)
    text.gsub(/\\u([0-9a-z]{4})/) {|s| [$1.to_i(16)].pack("U")}
  end
end
