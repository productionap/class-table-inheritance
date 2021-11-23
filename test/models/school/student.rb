module School
  class Student < KeyCard
    inherits_from :card, class_name: 'KeyCard', primary_key: :id, foreign_key: :id
  end
end
