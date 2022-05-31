class V1::PermissionsController < ApplicationController
	before_action :setup_permission_object
	before_action :check_read_permission
	before_action :check_write_permission, :except => [:index]

	def index 
		Permission.where(:permission_on => @permission_on)
	end 

	def create 
		Permission.find_or_create_by(:permission_on => @permission_on, :uid => @designated_uid, :permission => @permission)
		index
	end 

	def delete
		Permission.where(:permission_on => @permission_on, :uid => @designated_uid, :permission => @permission).delete_all
		render :nothing => true
	end

	protected

	def setup_permission_object

	end

	def check_read_permission 
	end

	def check_write_permission
	end
end