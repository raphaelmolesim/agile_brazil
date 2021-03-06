# encoding: UTF-8
class Page < ActiveRecord::Base
  belongs_to :conference

  scope :with_path, lambda { |p| where(path: p) }
end
