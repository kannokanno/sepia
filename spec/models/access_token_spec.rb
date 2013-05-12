# -*- coding: utf-8 -*-
require 'spec_helper'

describe AccessToken do
  let(:user) { User.create(name: 'hoge') }
  let(:access_token) { AccessToken.create(user_id: user.id, token: 'aaa', secret: 'bbb', provider: :twitter, uid: "1234567890")}
  let(:access_token_fb) { AccessToken.create(user_id: user.id, token: 'aaa', secret: 'bbb', provider: :facebook, uid: "12345678901")}

  describe "relations" do
    describe "#user" do
      subject { access_token.user }
      it "should be belongs to user" do
        expect(subject).to eq(user)
      end
    end
  end

  describe "validations" do
    describe "user_id" do
      it "required" do
        access_token.user_id = nil
        expect(access_token).not_to be_valid
      end
    end
    describe "provider" do
      it "required" do
        access_token.provider = ""
        expect(access_token).not_to be_valid
      end
    end
    describe "uid" do
      it "required" do
        access_token.uid = ""
        expect(access_token).not_to be_valid
      end
      context "uniqueness" do
        before do
          access_token
          @invalid = AccessToken.new(user_id: user.id, token: 'aaa', secret: 'bbb', provider: :twitter, uid: "1234567890")
        end
        it "by provider and uid" do
          expect(@invalid).not_to be_valid
        end
      end
    end
  end

  describe "#provider?" do
    it "providerを判定できる" do
      expect(access_token).to be_twitter
      expect(access_token_fb).to be_facebook
    end
  end

end
