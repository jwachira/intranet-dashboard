# -*- coding: utf-8 -*-

# News feeds administration
class FeedsController < ApplicationController
  before_filter { add_body_class('edit feeds') }
  before_filter { sub_layout("admin", except: "edit") }
  before_filter :require_admin

  def index
    @feeds = Feed.order("recent_failures desc, total_failures desc").includes(:users)
  end

  def new
    @feed = Feed.new
  end

  def edit
    @feed = Feed.where(id: params[:id]).includes(:roles).first
    not_found unless @feed.present?
  end

  def create
    @feed = Feed.new(params[:feed])

    if @feed.save
      redirect_to feeds_path, notice: "Nyhetsflödet skapades"
    else
      render action: "new"
    end
  end

  def update
    @feed = Feed.find(params[:id])

    if @feed.update_attributes(params[:feed])
      redirect_to feeds_path, notice: "Nyhetsflödet uppdaterades"
    else
      render action: "edit"
    end
  end

  def destroy
    @feed = Feed.find(params[:id])
    @feed.destroy
    redirect_to feeds_path, notice: "Nyhetsflödet raderades"
  end

  def refresh_entries
    @feed = Feed.find(params[:id])
    if @feed.refresh_entries
      redirect_to feeds_path, notice: "Nyhetsflödets samtliga nyheter raderades. De senaste nyheterna hämtades från källan. Notera att det kan ta en liten stund innan detta slår igenom hos användarna."
    else
      render action: "edit"
    end
  end
end
