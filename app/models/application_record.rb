class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Fix PostgreSQL sequences after creation to prevent ID conflicts
  after_create :fix_sequence_if_needed

  private

  def fix_sequence_if_needed
    return unless self.class.connection.adapter_name.downcase.include?("postgresql")

    sequence_name = "#{self.class.table_name}_id_seq"

    # Find the next available ID (not just the max ID)
    existing_ids = self.class.pluck(:id).sort
    next_available_id = 1
    existing_ids.each { |id| break if id > next_available_id; next_available_id = id + 1 }

    # Only update if the current sequence is not already correct
    current_sequence = self.class.connection.execute("SELECT last_value FROM #{sequence_name}").first["last_value"].to_i
    if current_sequence != next_available_id
      # Use setval with false to set the exact value without advancing
      self.class.connection.execute("SELECT setval('#{sequence_name}', #{next_available_id}, false)")
      Rails.logger.info "Fixed sequence #{sequence_name} from #{current_sequence} to #{next_available_id} (next available ID)"
    else
      Rails.logger.info "Sequence #{sequence_name} already correct at #{next_available_id}"
    end
  rescue => e
    Rails.logger.warn "Failed to fix sequence: #{e.message}"
  end
end
