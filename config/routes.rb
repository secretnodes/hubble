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
      get :settings
    end
  end

  # HUBBLE
  root to: 'home#index'

  namespace :cosmos, path: '' do
    resources :chains, format: false, constraints: { id: /[^\/]+/ }, only: %i{ index show } do
      # Faucet is a WIP
      # resource :faucet, only: %i{ show } do
      #   resources :transactions, only: %i{ index create show }
      # end

      resources :validators, only: %i{ show } do
        resources :subscriptions, except: %i{ new },
                  controller: '/util/subscriptions', defaults: { network: 'Cosmos' }
      end

      resources :blocks, only: %i{ show }
      resources :logs, only: %i{ index },
                controller: '/util/logs', defaults: { network: 'Cosmos' }
    end
  end

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

    namespace :cosmos do
      resources :chains, format: false, constraints: { id: /[^\/]+/ }, only: %i{ new create show update destroy } do
        resource :faucet, only: %i{ show update destroy }
        resources :faucets, only: %i{ create } do
          collection do
            post :init
          end
        end
      end
    end
  end

  mount LetterOpenerWeb::Engine, at: "/_mail" if Rails.env.development?
  match "*path", to: "home#catch_404", via: :all
end
