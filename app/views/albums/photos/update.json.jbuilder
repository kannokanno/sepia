if !@photo
  response.status = 400
  json.result :failed
  json.message 'invalid photo id'
elsif @error
  response.status = 400
  json.result :failed
  json.message @error.to_s
else
  json.result :success
  json.id @photo.id
  json.thumbnail_url @photo.thumbnail_url
  json.fullsize_url @photo.fullsize_url
  json.message @photo.message
end
