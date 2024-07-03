class User < ApplicationRecord
    validates :name, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    # validates :campaigns_list, presence: true, format: { with: /\A\[(\{"campaign_name": "[^"]+", "campaign_id": "[^"]+"\},?\s*)+\]\z/, message: "should be an array of JSONs" }

    # serialize :campaigns_list, default: [], coder: Array
end
