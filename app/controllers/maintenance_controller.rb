class MaintenanceController < ApplicationController
	def periodic_maintenance
		Channel.clean_expired_messages
	end
end