class MoreMetadataIndices < ActiveRecord::Migration[7.0]
  def change
    add_reference :message_metadata, :channel
    add_index :message_metadata, [:channel_id, :key, :value]
    execute("UPDATE message_metadata SET channel_id = (SELECT channel_id FROM messages WHERE messages.id = message_metadata.message_id)")
  end
end
