# -*- coding: utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :init_body_class, :mailer_set_url_options

  # Set a permanent cookie w/data from the user profile. Used by the masthead in other webapps
  def set_profile_cookie
    departments = current_user.roles.map { |d| { name: d.name, homepage_url: d.homepage_url } if d.category == 'department' }.compact
    workingfields = current_user.roles.map { |w| { name: w.name, homepage_url: w.homepage_url } if w.category == 'working_field' }.compact

    if Rails.env.development?
      myprofile = "myprofile-development"
    elsif Rails.env.test?
      myprofile = "myprofile-test"
    else
      myprofile = "myprofile"
    end

    cookies.permanent[myprofile] = {
      value: {
        # Singular is for old style masthead
        department:   departments.present? ? departments.first[:homepage_url].gsub('http://komin.malmo.se/', '') : '',
        workingfield: workingfields.present? ? workingfields.first[:homepage_url].gsub('http://komin.malmo.se/', '') : '',
        # Plural for masthead w/dropdowns
        departments:   departments,
        workingfields: workingfields
      }.to_json,
      expires: 365*10,
      path: '/',
      domain: 'malmo.se'
    }
  end

  # Save user agent and set permanent cookie for "remember me"
  def track_user_agent
    # Existing tracker from the browser
    tracker_id = cookies.signed[:user_agent].present? ? cookies.signed[:user_agent][:id] : nil

    # Get or create tracker from the UserAgent model
    tracker = UserAgent.track(current_user.id, tracker_id, params[:remember_me], request.env['HTTP_USER_AGENT'] )

    # Set tracker in browser
    cookies.permanent.signed[:user_agent] = {
      value:  { id: tracker[:id], token: tracker[:token] },
      secure: !Rails.env.development?,
      httponly: true,
      path: root_path
    }
  end

  # Catch errors and record not founds
  unless Rails.env.development?
    rescue_from ActionController::RoutingError, with: :not_found
    rescue_from AbstractController::ActionNotFound, with: :not_found
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from Exception, with: :error_page
  end
  def action_missing(method, *args)
    not_found
  end

  def not_found(exception = "404")
    logger.warn "Exception: #{exception}"
    logger.warn "  Full path: #{request.fullpath}"
    logger.warn "  Referer: #{request.referer}"
    reset_body_classes
    render template: "404", status: 404
  end

  def error_page(exception = "500", msg = "Prova att navigera med menyn ovan.")
    logger.error "Exception: #{exception}"
    logger.error "  User id: #{session[:user_id] ? session[:user_id] : 'not logged in'}"
    logger.error "  User Agent: #{request.user_agent}"
    logger.error "  Referer: #{request.referer}"
    logger.error "  Params: #{params}"
    reset_body_classes
    @msg = msg
    render template: "500", status: 500
  end

  protected

  def current_user
    begin
      @current_user ||= User.find(session[:user_id])
    rescue
      false
    end
  end

  def admin?
    current_user && current_user.admin?
  end
  helper_method :admin?, :current_user

  def require_user
    redirect_to login_path unless current_user
  end

  def require_admin
    not_authorized unless admin?
  end

  def require_early_adopter
    not_authorized unless current_user && current_user.early_adopter?
  end

  # Use only when params[:id] is users id
  def editing_myself?
    current_user.id.to_i === params[:id].to_i
  end

  def require_admin_or_myself
    not_authorized unless admin? || editing_myself?
  end

  def not_authorized(msg = "Du saknar behörighet för detta" )
    flash[:error] = msg
    redirect_to root_path
  end

  def init_body_class
    add_body_class(Rails.env)
    add_body_class('malmo-masthead-dashboard')
    add_body_class("user") if current_user
  end

  # Adds classnames to the body tag
  def add_body_class(name)
    @body_classes ||= ""
    @body_classes << "#{name} "
  end

  def reset_body_classes
    @body_classes = nil
    init_body_class
  end

  def sub_layout(name = "")
    @sub_layout = name
  end

  # It is not possible to set a /path mounted app url in the
  # action mailer config so we need to do it here
  def mailer_set_url_options
    ActionMailer::Base.default_url_options[:host] = request.env["HTTP_HOST"] + root_path.slice(0..-2)
  end
end
