class StaticPagesController < ApplicationController
  def home
    if current_user
      redirect_to dashboard_path
    end
  	@title = "Home"
  end

  def dashboard
    @title = "Dashboard"
  end
  
  def learn
    @title = "Learn"
  end

  def about
    @title = "About"
  end

  def help
    @title = "Help and FAQ"
  end

  def contact
    @title = "Contact Us"
  end
end
