class Album
  constructor: (id) ->
    @id = id

  show_url: =>
    "/albums/#{@id}"

  update: (data) =>
    $.ajax(type: 'PUT', url: "/albums/#{@id}.json", data: { album: data }, dataType: 'json')

  delete: =>
    $.ajax(type: 'DELETE', url: "/albums/#{@id}.json", dataType: 'json')

  add_photo: (photoId, position) =>
    $.ajax
      type: 'POST',
      url: "/albums/#{@id}/photos.json",
      data: {photo_id: photoId, position: position}
      dataType: 'json'
      timeout: 10000,

  update_photo: (photoId, position) =>
    $.ajax
      type: 'PUT',
      url: "/albums/#{@id}/photos.json",
      data: {photo_id: photoId, position: position}
      dataType: 'json'
      timeout: 10000,

  delete_photos: (photoIds) =>
    $.ajax
      type: 'DELETE',
      url: "/albums/#{@id}/photos.json",
      data: {photo_ids: photoIds}
      dataType: 'json'
      timeout: 10000,

this.Album = Album
