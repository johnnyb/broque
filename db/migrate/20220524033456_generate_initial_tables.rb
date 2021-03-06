class GenerateInitialTables < ActiveRecord::Migration[7.0]
	def change
		create_table :channels do |t|
			t.string :name
			t.string :owner_uid

			#### Configuration ####
			# Should I expire messages when they are all-the-way read?
			t.boolean :expire_messages, :default => false
			# Should I force a message to expire after a certain time even if unread?
			t.integer :force_message_expiration_time
			# How many readys before it is DLQd? (copied to cursor)
			t.integer :default_max_reads
			# On a message poll, ignore all messages that are more than this old (copied to cursor)
			t.integer :default_read_timeout

			t.timestamps
		end
		add_index :channels, :name, :unique => true
		add_index :channels, :owner_uid

		create_table :messages do |t|
			t.references :channel
			t.string :message_origination_reference
			t.string :message_reference
			t.string :publisher_uid
			t.text :message

			t.timestamps
		end
		add_index :messages, [:channel_id, :id]
		add_index :messages, :message_reference, :unique => true
		add_index :messages, [:channel_id, :message_origination_reference], :unique => true

		create_table :message_metadata do |t|
			t.references :message
			t.string :key
			t.string :value
		end

		create_table :subscriptions do |t|
			t.references :channel
			t.references :default_message_cursor
			t.string :name
			t.string :subscriber_uid

			t.timestamps
		end
		add_index :subscriptions, [:channel_id, :name], :unique => true

		create_table :message_cursors do |t|
			t.string :originator_uid
			t.references :channel
			t.references :last_message

			t.integer :default_max_reads
			t.integer :default_read_timeout

			t.timestamps
		end

		create_table :active_readings do |t|
			t.references :message_cursor
			t.references :message 
			t.timestamp :expires_at
			t.boolean :died, :default => false
			t.integer :read_count, :default => 0
			t.integer :max_reads		

			t.timestamps
		end
		add_index :active_readings, [:message_cursor_id, :message_id], :unique => true
		add_index :active_readings, [:message_cursor_id, :expires_at]
	end
end
