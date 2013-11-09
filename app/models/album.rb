class Album < ActiveRecord::Base
  belongs_to  :user
  has_many :albums_photos, class_name: 'AlbumsPhotos', inverse_of: :album, dependent: :destroy
  has_many :photos, through: :albums_photos

  scope :public, -> { where(public: true) }

  validates :name, presence: true

  def owner? user
    user.id == self.user_id
  end

  def find_by_position position
    photos.find_by(:'albums_photos.position' => position)
  end

  def position photo
    found = albums_photos.find { |p| p.photo_id == photo.id }
    found.nil? ? nil : found.position
  end
end
