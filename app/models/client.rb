class Client
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short

  field :token,                        type: String, default: ""
  has_and_belongs_to_many :users
end
