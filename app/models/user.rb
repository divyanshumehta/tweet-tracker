class User
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short

  field :handle,               type: String, default: ""
  field :last_tweet,           type: Integer
  has_and_belongs_to_many :clients
  has_many  :tweets
end
