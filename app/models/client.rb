class Client
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short

  field :token,                        type: String, default: ""
  field :text_notify,                  type: Boolean, default: false
  field :photo_notify,                 type: Boolean, default: false
  field :text_and_photo_notify,        type: Boolean, default: false
  field :track,                        type: Hash, default: {}
  has_and_belongs_to_many :users
end
