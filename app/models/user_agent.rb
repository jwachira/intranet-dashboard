# -*- coding: utf-8 -*-
require "bcrypt"

# Autentication with a "remember me" token
# Each user has one or more user agents with an individual token, remember_me setting and modified date
class UserAgent < ActiveRecord::Base

  belongs_to :user
  attr_accessible :user_id, :remember_me, :remember_me_hash, :user_agent_tag

  def authenticate(token)
    remember_me? && !expired? && valid_token?(token)
  end

  def valid_token?(token)
    BCrypt::Password.new(remember_me_hash) == token
  end

  def expired?
    updated_at < Date.today - APP_CONFIG['remember_me_days'].days
  end

  # Save UA remember me token
  def self.track(user_id, tracker_id, remember_me, tag)
    user_agent = where(id: tracker_id).first_or_initialize

    # Create a new token every time it is set for the user agent
    token = Array.new(64).map { (65 + rand(58)).chr }.join
    user_agent.update_attributes({
      user_id: user_id,
      user_agent_tag: tag,
      remember_me: remember_me,
      remember_me_hash: BCrypt::Password.create(token)
    })
    { id: user_agent.id, token: token }
  end
end
