# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Colleagueships" do
  let(:user) { create(:user) }
  before(:each) do
    login(user.username, "") # Stubbed auth
  end

  it "should not be set" do
    page.should have_selector('.no-colleagues')
  end

  it "should be set" do
    followed = create(:user)
    Colleagueship.create(user_id: user.id, colleague_id: followed.id)
    visit root_path
    page.should_not have_selector('.no-colleagues')
    page.should have_xpath("//li[not(@id='my-status')][1]", text: followed.displayname)
  end
end
