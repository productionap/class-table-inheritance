ActiveRecord::Schema.define(:version => 0) do
  create_table :products, :force => true do |t|
    t.string :name
    t.string :subtype
  end
  
  create_table :books, :force => true do |t|
    t.string :isbn
    t.integer :product_id
  end
  
  create_table :mod_videos, :force => true do |t|
    t.integer :product_id
    t.string :url
  end
  
  create_table :mod_users, :force => true do |t|
    t.string :name
    t.string :subtype
  end
  
  create_table :managers, :force => true do |t|
    t.integer :mod_user_id
    t.string :salary
  end
  
  create_table :key_cards, :force => true do |t|
    t.string :name
    t.string :card_type
  end
  
  create_table :school_student, :inherits => {
      :base => :key_card,
      :primary => :id,
  }, :force => true do |t|
    t.string :student_code
    t.integer :grade_level
    t.float :grade_overall
  end
  
  create_table :school_teacher, :inherits => {
    :base => :key_card,
    :primary => :id,
  }, :force => true do |t|
    t.string :preferred_subjects
  end
end
