galleryId = '#gallery'
formId = '#new_album'
submitButtonId = '#create-submit'
modalId = '#create-form'
messageTemplateId = "#error-msg-template"
errorAreaId = "#errors"

$(galleryId).booklet(
  width: 1100,
  height: 460,
  speed: 800,
  autoCenter: true,
  manual: false,
  overlays: false,
  hovers: false,
)

$(submitButtonId).bind 'click', (event) ->
  event.preventDefault()
  $(formId).submit()

$(formId).submit (event) ->
  event.preventDefault()

  $form = $(this)
  $submitButton = $(submitButtonId)
  $submitButton.attr 'disabled', true
  $errors = $(errorAreaId)
  $errors.children().remove()

  promise = $.ajax
    url: "#{ $form.attr('action') }.json",
    type: $form.attr('method'),
    data: $form.serialize(),
    timeout: 10000,
    dataType: 'json'

  promise.done (data) ->
    $submitButton.attr 'disabled', false
    $(modalId).modal 'hide'
    setTimeout ->
      window.location.href = new Album(data.id).show_url()
    , 500

  promise.fail (res) ->
    _.each res.responseJSON.errors, (error, i) ->
      template = _.template($(messageTemplateId).html())
      _.each error, (messages, key) ->
        _.each messages, (message) ->
          $(template(key: key, message: message)).hide().appendTo($errors).fadeIn()

  undefined

do ->
  $(galleryId).on 'click', '.photo-trash', ->
    if confirm('Is this photo deleted from an album?')
      $link = $(this)
      # TODO 複数削除を考慮して名前を`ids`にしてあるけど、今の持ち方だと自身のidしか持てないんじゃね。HTML側修正
      new Album($link.data('album-id')).delete_photos($link.data('photo-ids'))
      .done (data) ->
        $link.parent('.pocket').animate(opacity: 0, 'slow', ->
          $(this).removeClass('pocket').addClass('add-pocket empty-pocket').html('<span>Add Photo</span>').css('opacity', '1.0'))
      .fail (res) ->
        # TODO エラー時の見せ方
        console.log(res.responseJSON)

do ->
  $('#albums').on 'click', '.album-trash', ->
    if confirm('Is this album deleted?')
      $link = $(this)
      $link.css('display', 'none')
      new Album($link.data('album-id')).delete()
      .done (data) ->
        $link.closest('li').animate width: 'hide', height: 'hide', opacity: 'hide', 'slow', -> $(this).remove()
      .fail (res) ->
        # TODO エラー時の見せ方
        console.log(res.responseJSON)
        $link.css('display', '')

apply_unveil = (page) -> $(".img-block img[data-page='#{page}']").unveil(0)
apply_unveil(1)

$('#load-link').bind 'click', ->
  $link = $(this)
  currentPage = $link.attr('data-current-page') - 0
  $.get($link.data('url'), page: currentPage+1)
  .done (data) ->
    parent = $('#albums')
    template = _.template($('#album-template').html())
    append_albums = ''
    _.each data.albums, (album, i) ->
      stack_class = if album.size < 1 then 'simple' else 'stack'
      append_albums += template(id: album.id, page: data.page, url: album.url, image_url: album.image_url, name: album.name, size: album.size, updated_at: album.updated_at, stack_class: stack_class)
    $(parent).append(append_albums)

    apply_unveil(data.page)
    $link.attr 'data-current-page', data.page
    $link.hide() if data.page * 25 >= data.all_count

$('#albums').on 'click', '.title-edit', ->
  album_id = $(this).data('album-id')
  title =  $("#title-#{album_id}")
  header = $("#title-header-#{album_id}")
  header.hide()

  $("#title-edit-#{album_id}")
  .val(title.html())
  .fadeIn()
  .on 'keypress.title-edit', (event) ->
    if event.which == 13 # enter key
      text = $(this)
      new Album(album_id)
      .update(name: text.val())
      .done (data) ->
        title.html _.escape(text.val())
      .always ->
        text.off('keypress.title-edit').hide()
        header.fadeIn()

$('#load-candidate-link').on 'click', ->
  $link = $(this)
  $parent = $link.parent()
  $.get($('#add-candidate').data('url'), page: ($link.attr('data-current-page') - 0) + 1)
  .done (data) ->
    parent = $('#candidate-photos')
    template = _.template($('#candidate-template').html())
    candidate_photos = ''
    _.each data.photos, (photo, i) ->
      candidate_photos += template(id: photo.id, page: data.page, thumbnail_url: photo.thumbnail_url)
    parent.append(candidate_photos)

    $("#add-candidate img[data-candidate-page='#{data.page}']").unveil(0)
    $link.attr 'data-current-page', data.page
    $parent.appendTo($('#candidate-photos'))
    # TODO '50'のベタ書き。photos.coffeeにもあるが、Settingsを参照したい
    $link.hide() if data.page * 50 >= data.all_count

SepiaUtil.apply_fancybox($('.fullsize-link'))

do ->
  init = true
  $('.gallery-page').on 'click', '.add-pocket', ->
    $candidate = $('#add-candidate')
    isClosed = $candidate.css('display') == 'none'
    iconBottomPos = if isClosed then '110px' else '5px'

    $candidate.animate(height: 'toggle', 500, 'swing', ->
      $icon = $('#toggle-candidate-icon')
      if !isClosed # TODO わかりにくい
        $icon.removeClass('icon-double-angle-down')
        $icon.addClass('icon-double-angle-up')
      else
        $icon.removeClass('icon-double-angle-up')
        $icon.addClass('icon-double-angle-down')
    )
    if init
      $('#more-candidate').show()
      $('#load-candidate-link').click()
    init = false

do ->
  $icon = $('#toggle-candidate-icon')
  hoverClass = 'toggle-candidate-hover'
  $('#toggle-candidate').hover ->
    $icon.addClass(hoverClass)
  , ->
    $icon.removeClass(hoverClass)

toast_success = (msg) ->
  $.toast(msg, duration: 3000, type: 'success')

toast_fail = (msg) ->
  $.toast(msg, duration: 5000, type: 'danger')

do ->
  mimeType = 'text/plain'
  dragImgCssClass = 'drag-img-active'
  dropCssClass = 'drop-area-notice'

  $dragArea = $('#add-candidate')
  $dragArea.on 'dragstart', 'img', (event) ->
    $(this).addClass(dragImgCssClass)
    event.originalEvent.dataTransfer.effectAllowed = 'copy'
    event.originalEvent.dataTransfer.setData(mimeType, $(this).data('photo-id'))
  $dragArea.on 'dragend', 'img', -> $(this).removeClass(dragImgCssClass)

  $dropArea = $("#{galleryId} .drop-area")
  $dropArea.on 'dragenter', -> $(this).addClass(dropCssClass)
  $dropArea.on 'dragleave', -> $(this).removeClass(dropCssClass)
  $dropArea.on 'dragover', (event) -> event.preventDefault()
  $dropArea.on 'drop', (event) ->
    $photo = $(this)
    album = new Album($(galleryId).data('album-id'))

    apply_drop = ($promise, success_msg, fail_msg) ->
      $promise
      .done (data) ->
        toast_success(success_msg)
        $photo.removeClass('add-pocket empty-pocket').addClass('pocket')
        template = _.template($('#pocket-template').html())
        $photo.html(template(album_id: album.id, thumbnail_url: data.thumbnail_url, fullsize_url: data.fullsize_url, message: data.message, photo_id: [data.id]))
        $($photo).find('img').unveil()
        SepiaUtil.apply_fancybox($photo.find('.fullsize-link'))
      .fail (res) ->
        toast_fail(fail_msg)
      .always ->
        $($dragArea, 'img').removeClass(dragImgCssClass)
        $photo.removeClass(dropCssClass)

    photo_id = event.originalEvent.dataTransfer.getData(mimeType)
    position = $photo.data('position')
    if $photo.find('img').length == 0
      apply_drop(album.add_photo(photo_id, position),
        'Photo was added.', 'Photo was not able to add.')
    else if confirm('Update this photo?')
      apply_drop(album.update_photo(photo_id, position),
        'Photo was updated.', 'Photo was not able to update.')
    event.preventDefault()

$('#album-visibility').on 'switch-change', (e, data) ->
  $switch = $(this)
  new Album($switch.data('album-id'))
  .update(public: data.value)
  .fail (res) ->
    alert('failed to update visibility')

$('#load-photo-link').bind 'click', ->
  $link = $(this)
  currentPage = $link.attr('data-current-page') - 0
  $.get($link.data('url'), page: currentPage+1)
  .done (data) ->
    parent = $('#polaroids')
    album_id = $('#photos').data('album-id')
    template = _.template($('#photo-template').html())
    polaroids = ""
    _.each data.photos, (photo, i) ->
      polaroids += template(album_id: album_id, thumbnail_url: photo.thumbnail_url, fullsize_url: photo.fullsize_url, message: photo.message, page: data.page,\
                            posted_at: photo.posted_at, provider: photo.provider, icon_class: photo.icon_class, photo_ids: [photo.id])

    polaroidsObj = $(polaroids)
    $(parent).append(polaroidsObj)
    polaroidsObj.each -> SepiaUtil.truncate_message($('.polaroid .message', this))

    $("img.img-photo[data-page='#{data.page}']").unveil(0)
    $link.attr 'data-current-page', data.page
    $link.hide() if data.page * 50 >= data.all_count
    SepiaUtil.apply_fancybox($('.display-link'))

$("#album-visibility").bootstrapSwitch()
