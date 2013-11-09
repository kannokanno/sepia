class Albums::PhotosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_album

  def create
    @photo = current_user.photos.find(params[:photo_id]) if params[:photo_id]
    if @album && @photo
      begin 
        ActiveRecord::Base.transaction do
          AlbumsPhotos.create!(album_id: @album.id, photo_id: @photo.id, position: params[:position])
        end
      rescue => e
        logger.warn e
        @error = e
      end
    end
  end

  def update
    albums_photos = AlbumsPhotos.find_by(album_id: @album.id, position: params[:position])
    @photo = current_user.photos.find(params[:photo_id]) if params[:photo_id]
    if albums_photos && @photo
      begin
        ActiveRecord::Base.transaction do
          albums_photos.photo_id = @photo.id
          albums_photos.save!
        end
      rescue => e
        logger.warn e
        @error = e
      end
    end
  end

  def destroy
    @photos = current_user.photos.where(id: params[:photo_ids]) if params[:photo_ids]
    if @album && @photos && !@photos.empty?
      begin
        ActiveRecord::Base.transaction do 
          @album.photos.destroy(@photos)
        end
      rescue => e
        logger.warn e
        @error = e
      end
    end
  end

  private
  def set_album
    @album = current_user.albums.where(id: params[:album_id]).first
    head :not_found unless @album
  end
end
