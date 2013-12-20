json.array!(@people) do |person|
  json.extract! person, :id, :email, :name_first, :name_last, :birth_year, :height, :degree_p
  json.url person_url(person, format: :json)
end
