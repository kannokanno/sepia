# -*- coding: utf-8 -*-
require 'spec_helper'

describe Album do
  let(:user) { User.create!(name: "test-user", email: "hoge@gmail.com") }
  let(:user2) { User.create!(name: "test-user", email: "hoge@gmail.com") }
  let(:album){ Album.create!(user_id: user.id, name: 'hoge-album') }
  let(:photo){ Photo::Google.create!(user_id: user.id, provider: :hoge, platform_id: "100", format: "jpg", posted_at: Time.now, fullsize_url: "hoge", thumbnail_url: "foo") }
  let(:other_photo){ Photo::Google.create!(user_id: user2.id, provider: :hoge, platform_id: "100", format: "jpg", posted_at: Time.now, fullsize_url: "hoge", thumbnail_url: "foo") }

  describe 'relation' do
    describe 'user' do
      subject{ album.user }
      it { should eq(user) }
    end

    describe 'photos' do
      subject{ album.photos }
      before do
        AlbumsPhotos.create(album_id: album.id, photo_id: photo.id, position: 1)
      end
      it "紐づくPhotoが取得できる" do
        expect(subject.first).to eq(photo)
      end
    end
  end

  describe :scope do
    describe :public do
      let(:public_album) { Album.new(name: 'hoge-album', public: true) }

      before do
        user.albums << public_album
        album
      end

      it "publicなアルバムのみ取得できる" do
        expect(user.albums.public).to match_array [public_album]
      end
    end
  end

  describe "validation" do
    describe "add photos" do
      context "AlbumのユーザーとPhotoのユーザーが同じ場合" do
        before do
          AlbumsPhotos.create(album_id: album.id, photo_id: photo.id, position: 1)
        end
        it "Albumに紐づくPhotoとして登録される" do
          expect(Album.find(album.id).photos.first).to eq(photo)
        end
      end
      context "AlbumのユーザーとPhotoのユーザーが別の場合" do
        it "Albumに紐づくPhotoとして登録されない" do
          expect{ AlbumsPhotos.create!(album_id: album.id, photo_id: other_photo.id, position: 1) }.to raise_error{|error|
            expect(error.record.errors[:user]).to have(1).item
          }
          expect(Album.find(album.id).photos.first).to be_nil
        end
      end
      context "登録済みの写真の場合" do
        before do
          AlbumsPhotos.create(album_id: album.id, photo_id: photo.id, position: 1)
        end
        it "Albumに紐づくPhotoとして登録されない" do
          expect{ AlbumsPhotos.create!(album_id: album.id, photo_id: photo.id, position: 2) }.to raise_error{|error|
            expect(error.record.errors[:photo_id]).to match_array ['unique']
          }
          expect(Album.find(album.id).photos.size).to eq(1)
        end
      end
    end
  end

  describe '#public?' do
    subject { Album.find(@id).public? }
    context "public is true" do
      before do
        @id = Album.create!(user_id: user.id, name: 'hoge-album', public: true).id
      end
      it { should be_true }
    end
    context "public is false" do
      before do
        @id = Album.create!(user_id: user.id, name: 'hoge-album', public: false).id
      end
      it { should be_false }
    end
  end

  describe "#owner?" do
    subject{ album.owner?(@user) }
    context "受け取ったUserのIDがアルバムのUserIDと一致する場合" do
      before { @user = user }
      it { should be_true }
    end
    context "受け取ったUserのIDがアルバムのUserIDと一致しない場合" do 
      before { @user = user2 }
      it { should be_false }
    end
  end

  describe "#find_by_position" do
    subject{ album.find_by_position(@position) }
    before do
      AlbumsPhotos.create(album_id: album.id, photo_id: photo.id, position: 1)
    end
    context "指定した位置に画像がある場合" do
      before { @position = 1 }
      it { should eq(photo) }
    end
    context "指定した位置に画像がない場合" do
      before { @position = 2 }
      it { should be_nil }
    end
  end

  describe "#position" do
    subject{ album.position(@photo) }
    before do
      AlbumsPhotos.create(album_id: album.id, photo_id: photo.id, position: 2)
    end
    context "指定した画像が登録されている場合" do
      before { @photo = photo }
      it { should eq(2) }
    end
    context "指定した画像が登録されていない場合" do
      before { @photo = other_photo }
      it { should be_nil }
    end
  end
end
