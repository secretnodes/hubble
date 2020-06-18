Rails.application.routes.draw do
  get '/login' => 'sessions#new', as: 'login'
  post '/login' => 'sessions#create', as: 'login_submit'
  get '/logout' => 'sessions#destroy', as: 'logout'
  get '/password/forgot' => 'sessions#forgot_password', as: 'forgot_password'
  post '/password/reset' => 'sessions#reset_password', as: 'reset_password'
  get '/password/recover' => 'sessions#recover_password', as: 'recover_password'

  resources :users, only: %i{ new create update } do
    collection do
      get :welcome
      get :confirm
      get :confirmed
      get :resend_confirmation
      get :settings
    end
  end

  # PUZZLE
  root to: 'home#index'
  get '/privacy_policy' => 'home#privacy_policy'

  concern :chainlike do
    resources :chains, format: false, constraints: { id: /[^\/]+/ }, only: %i{ show } do
      get '/dashboard' => 'dashboard#index', as: 'dashboard'

      resource :faucet, only: %i{ show } do
        resources :faucet_transactions, as: 'transactions', path: 'transactions', only: %i{ create }
      end

      member do
        get :search
        get :halted
        get :prestart
        post :broadcast
      end

      resources :events, only: %i{ index show }

      resources :validators, only: %i{ show } do
        resources :subscriptions, only: %i{ index create }, controller: '/util/subscriptions'
      end

      resources :accounts, only: %i{ show }

      resources :blocks, only: %i{ show } do
        resources :transactions, only: %i{ show }
      end
      resources :transactions, only: %i{ show }

      resources :logs, only: %i{ index }, controller: '/util/logs'

      namespace :governance do
        root to: 'main#index'
        resources :proposals, only: %i{ show }
      end

      resources :watches, as: 'watches', only: %i{ create }
    end
  end

  get '/chains/*path', to: redirect('/cosmos/chains/%{path}')
  namespace :enigma, network: 'enigma' do concerns :chainlike end
  namespace :cosmos, network: 'cosmos' do concerns :chainlike end
  namespace :terra, network: 'terra' do concerns :chainlike end
  namespace :iris, network: 'iris' do concerns :chainlike end
  namespace :kava, network: 'kava' do concerns :chainlike end

  # ADMIN
  namespace :admin do
    root to: 'main#index'

    resources :sessions, only: %i{ new create }
    get '/logout' => 'sessions#destroy', as: 'logout'

    resources :administrators do
      collection do
        get :setup
        post :setup
      end
    end

    resources :users do
      member do
        get :masq
      end
      resources :alert_subscriptions, only: %i{ destroy }
    end

    concern :chainlike do
      resources :chains, format: false, constraints: { id: /[^\/]+/ } do
        resource :faucet, only: %i{ show update destroy }
        resources :faucets, only: %i{ create }

        resources :validator_events, only: %i{ index }

        member do
          post :move_up
          post :move_down
        end
      end
    end

    namespace :enigma do concerns :chainlike end
    namespace :cosmos do concerns :chainlike end
    namespace :terra do concerns :chainlike end
    namespace :iris do concerns :chainlike end
    namespace :kava do concerns :chainlike end

    namespace :common do
      resources :validator_events, only: %i{ destroy }
    end
  end

  namespace :api do
    namespace :v1 do
      get '/account_balance' => 'accounts#balance', as: :account_balance
      get '/account_info' => 'accounts#info', as: :account_info
    end
  end

  mount LetterOpenerWeb::Engine, at: '/_mail' if Rails.env.development?
  match '*path', to: 'home#catch_404', via: :all
end
