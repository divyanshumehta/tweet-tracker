class Tweet
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short

  field :ID,                        type: Integer
  field :category,                  type: String, default: ""
  field :text,                      type: String, default: ""
  field :media,                     type: String, default: ""
  field :url,                       type: String, default: ""
  field :tweeted_at

  belongs_to :user

end
