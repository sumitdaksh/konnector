class UsersController < ApplicationController
    def index
        users = User.all
        render json: users
    end

    def show
        user = User.find(params[:id])
        render json: user
    rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :not_found
    end

    def create
        user = User.new(user_params)

        if user.save
            render json: user, status: :created
        else
            render json: user.errors, status: :unprocessable_entity
        end
    end

    def filter
        campaign_name = params[:campaign_names]&.split(',')
        if campaign_name.nil?
          users = []
        else
          condition = campaign_name.map { |name| "JSON_SEARCH(JSON_EXTRACT(campaigns_list, '$[*].campaign_name'), 'one', '#{name}')" }.join(' OR ')
          # users = User.where("JSON_SEARCH(JSON_EXTRACT(campaigns_list, '$[*].campaign_name'), 'all', ?)", params[:campaign_name])
          users = User.where(ActiveRecord::Base.sanitize_sql(condition))
        end 
        render json: users
    end

    private

    def user_params
        params.require(:user).permit(:name, :email, campaigns_list: [:campaign_name, :campaign_id])
    end
end
