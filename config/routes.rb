Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords',
    confirmations: 'users/confirmations'
  }
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  resources :users, only: %i{ update } do
    collection do
      get :welcome
      get :confirm
      get :confirmed
      get :resend_confirmation
      get :settings
    end
  end

  resource :two_factor_settings, except: [:index, :show]

  resources :wallets, only: %i{ index }

  put '/default_wallet' => 'wallets#update', as: :default_wallet
  
  # PUZZLE
  root to: 'secret/chains#show', id: 'secret-2'
  get '/privacy_policy' => 'home#privacy_policy'
  get '/chains' => 'home#index'

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
        get :info_cards
      end

      get '/events_table' => 'events#events_table', as: :events_table

      resources :events, only: %i{ index show }

      resources :validators, only: %i{ show } do
        resources :subscriptions, only: %i{ index create }, controller: '/util/subscriptions'
      end

      resources :accounts, only: %i{ show index }

      resources :blocks, only: %i{ show } do
        resources :transactions, only: %i{ show }
      end
      resources :transactions, only: %i{ show index }
      get 'swaps' => 'transactions#swaps', as: :swaps
      get 'contracts' => 'transactions#contracts', as: :contracts

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
  namespace :secret, network: 'secret' do concerns :chainlike end
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
    namespace :secret do concerns :chainlike end
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
      get '/swap_total' => 'swaps#tokens_burned', as: :burned
      resources :wallets, only: [:create]
    end
  end

  mount LetterOpenerWeb::Engine, at: '/_mail' if Rails.env.development?
  match '*path', to: 'home#catch_404', via: :all
end
