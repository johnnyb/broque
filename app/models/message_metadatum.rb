class MessageMetadatum < ApplicationRecord
	belongs_to :channel
	belongs_to :message
end