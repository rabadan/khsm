require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  context 'Anon' do
    it 'kick from #show' do
      get :show, id: game_w_questions.id
      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kick from #create' do
      generate_questions(15)

      # пытаемся создать игру
      post :create
      game = assigns(:game)

      # проверяем создалась ли игра
      expect(game).to be_nil

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kick from #answer' do
      # пытаемся ответить на вопрос
      put :show, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key

      # убеждаемся, что ответ не засчитался
      game_w_questions.reload
      expect(game_w_questions.current_level).to eq(0)

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kick from #take_money' do
      # переходим на произвольный уровень
      game_w_questions.update_attribute(:current_level, 4)
      # пытаемся забрать деньги
      put :take_money, id: game_w_questions.id

      # проверяем, что игра не закончилась, деньги нам не отдали
      game_w_questions.reload
      expect(game_w_questions).not_to be_finished

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end
  end

  context 'Usual user' do
    before(:each) { sign_in user }

    it 'creates game' do

      generate_questions(15)

      post :create
      game = assigns(:game)

      expect(game).not_to be_finished
      expect(game.user).to eq(user)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to be
    end

    it '#show game' do
      get :show, id: game_w_questions.id
      game = assigns(:game)
      expect(game).not_to be_finished
      expect(game.user).to eq(user)

      expect(response.status).to eq(200)
      expect(response).to render_template('show')
    end

    it 'answers correct' do
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
      game = assigns(:game)

      expect(game).not_to be_finished
      expect(game.current_level).to be > 0
      expect(response).to redirect_to(game_path(game))
      expect(flash).to be_empty
    end

    it 'show alien game' do
      alien_game = FactoryGirl.create(:game_with_questions)

      get :show, id: alien_game.id

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be
    end

    it 'takes money' do
      game_w_questions.update_attribute(:current_level, 4)

      put :take_money, id: game_w_questions.id
      game = assigns(:game)
      user.reload

      expect(game).to be_finished
      expect(game.prize).to eq(500)
      expect(user.balance).to eq(500)
      expect(response).to redirect_to(user_path(user))
    end

    it 'try to create others game' do
      expect(game_w_questions).not_to be_finished
      expect { post :create }.to change(Game, :count).by(0)

      game = assigns(:game)
      expect(game).to be_nil
      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end
  end
end
