ActiveRecord::Schema.define(:version => 0) do
  create_table :products, :force => true do |t|
    t.string :name
    t.string :subtype
  end
  
  create_table :books, :primary_key => :product_id, :force => true do |t|
    t.string :isbn
  end
  
  create_table :mod_videos, :primary_key => :product_id, :force => true do |t|
    t.string :url
  end
  
  create_table :mod_users, :force => true do |t|
    t.string :name
    t.string :subtype
  end
  
  create_table :managers, :primary_key => :mod_user_id, :force => true do |t|
    # t.integer :mod_user_id
    t.string :salary
  end
  
  create_table :key_cards, :force => true do |t|
    t.string :name
    t.string :card_type
  end
  
  create_table :school_student, :force => true do |t|
    t.string :student_code
    t.integer :grade_level
    t.float :grade_overall
  end
  
  create_table :school_teacher, :force => true do |t|
    t.string :preferred_subjects
  end
end
