class CreateGameEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :game_events do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :game_name, null: false
      t.string :type, null: false
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :game_events, [ :user_id, :occurred_at ], name: "index_game_events_on_user_and_occurred_at"
    add_index :game_events, [ :game_name, :type ], name: "index_game_events_on_game_and_type"
  end
end
